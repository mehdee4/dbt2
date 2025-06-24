-- macros/create_snowflake_stages.sql

{#
  This macro is responsible for creating or replacing Snowflake EXTERNAL STAGE objects.
  It reads the definitions from the 'snowflake_stages' and 'snowflake_file_formats'
  variables in dbt_project.yml.
#}
{% macro create_snowflake_stages() %}

  {#
    Ensure the dedicated 'CONFIGS' schema exists where stages will be stored.
    This call is for defensive programming, as 'create_snowflake_schemas' should
    have already ensured this when called by the orchestrator.
  #}
  {% do create_schema_if_not_exists(target.database, "CONFIGS") %}

  {# Load the stage definitions from the 'snowflake_stages' variable #}
  {% set stages_to_create = var('snowflake_stages', []) %}
  {# Load file formats definitions from the 'snowflake_file_formats' variable to resolve references #}
  {% set file_formats_available = var('snowflake_file_formats', []) %}

  {% set file_formats_map = {} %}
  {% if file_formats_available %}
    {% for format in file_formats_available %}
      {# Map format name to its fully qualified name for easy lookup #}
      {% set full_format_object_name = '"' ~ target.database ~ '"."' ~ "CONFIGS" ~ '"."' ~ format.name ~ '"' %}
      {% do file_formats_map.update({format.name: full_format_object_name}) %}
    {% endfor %}
  {% endif %}


  {% if stages_to_create %}
    {{ log("--- Starting to create/ensure Snowflake Stages ---", info=true) }}
    {# Loop through each stage definition provided in the variable #}
    {% for stage_def in stages_to_create %}
      {% set stage_name = stage_def.name %}
      {% set stage_url = stage_def.url %}
      {% set file_format_ref = stage_def.get('file_format_ref') %}
      {% set credentials = stage_def.get('credentials') %}
      {% set storage_integration = stage_def.get('storage_integration') %}
      {% set schema_name = "CONFIGS" %} {# Stages will be created in CONFIGS schema #}

      {# Construct the fully qualified stage name #}
      {% set full_stage_name = '"' ~ target.database ~ '"."' ~ schema_name ~ '"."' ~ stage_name ~ '"' %}

      {# Resolve the file format reference to its fully qualified Snowflake object name #}
      {% set resolved_file_format = "" %}
      {% if file_format_ref and file_formats_map[file_format_ref] is defined %}
        {% set resolved_file_format = file_formats_map[file_format_ref] %}
      {% else %}
        {{ log("Warning: No valid file_format_ref '" ~ file_format_ref ~ "' found in file_formats_map for stage '" ~ stage_name ~ "'. Stage may fail to create or require manual correction.", info=true) }}
      {% endif %}

      {{ log("Creating/Replacing Snowflake Stage: " ~ full_stage_name, info=true) }}

      {% set create_stage_sql %}
        CREATE OR REPLACE STAGE {{ full_stage_name }}
        URL = '{{ stage_url }}'
        {% if resolved_file_format %}
        FILE_FORMAT = {{ resolved_file_format }}
        {% endif %}
        {% if credentials %}
        CREDENTIALS = ({{ credentials }})
        {% endif %}
        {% if storage_integration %}
        STORAGE_INTEGRATION = "{{ storage_integration }}"
        {% endif %};
      {% endset %}

      {% do run_query(create_stage_sql) %}
      {{ log("Stage " ~ full_stage_name ~ " created/updated successfully.", info=true) }}
    {% endfor %}
    {{ log("--- Finished creating/ensuring Snowflake Stages ---", info=true) }}
  {% else %}
    {{ log("No 'snowflake_stages' list defined in dbt_project.yml. No stages created.", info=true) }}
  {% endif %}

{% endmacro %}