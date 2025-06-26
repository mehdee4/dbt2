-- macros/create_snowflake_stages.sql

{#
  This macro is responsible for creating Snowflake EXTERNAL STAGE objects.
  It now explicitly checks for existence and provides precise logging.
  If a stage already exists, it will log that and skip creation.
  If it does not exist, it will create it.

  IMPORTANT: If a stage with the same name already exists, its definition
  WILL NOT BE UPDATED by this macro. To force an update, you would need to
  manually DROP the stage in Snowflake.
#}
{% macro create_snowflake_stages(target_database_name, target_schema_name) %}

  {% set stages_to_create = var('snowflake_stages', []) %}
  {% set file_formats_available = var('snowflake_file_formats', []) %}

  {% set file_formats_map = {} %}
  {% if file_formats_available %}
    {% for format in file_formats_available %}
      {% set full_format_object_name = '"' ~ target_database_name ~ '"."' ~ target_schema_name ~ '"."' ~ format.name ~ '"' %}
      {% do file_formats_map.update({format.name: full_format_object_name}) %}
    {% endfor %}
  {% endif %}

  {#
    CRITICAL FIX: Only execute SQL queries if dbt is in the 'execute' phase.
    This prevents compilation-time evaluation errors where 'this' (or other
    context variables) might be 'None'.
  #}
  {% if execute %}
    {% if stages_to_create %}
      {{ log("--- Starting to create Snowflake Stages (IF NOT EXISTS) in " ~ target_database_name ~ "." ~ target_schema_name ~ " ---", info=true) }}
      {% for stage_def in stages_to_create %}
        {% set stage_name = stage_def.name %}
        {% set stage_url = stage_def.url %}
        {% set file_format_ref = stage_def.get('file_format_ref') %}
        {% set credentials = stage_def.get('credentials') %}
        {% set storage_integration = stage_def.get('storage_integration') %}

        {% set full_stage_name = '"' ~ target_database_name ~ '"."' ~ target_schema_name ~ '"."' ~ stage_name ~ '"' %}

        {% set resolved_file_format = "" %}
        {% if file_format_ref and file_formats_map[file_format_ref] is defined %}
          {% set resolved_file_format = file_formats_map[file_format_ref] %}
        {% else %}
          {{ log("Warning: No valid file_format_ref '" ~ file_format_ref ~ "' found in file_formats_map for stage '" ~ stage_name ~ "'. Stage may fail to create or require manual correction.", info=true) }}
        {% endif %}

        {# Check if the stage already exists #}
        {% set check_stage_sql %}
          SHOW STAGES LIKE '{{ stage_name }}' IN SCHEMA {{ target_database_name }}."{{ target_schema_name }}";
        {% endset %}
        {% set existing_stage = run_query(check_stage_sql) %}

        {% if existing_stage.rows | length > 0 %}
          {# Stage exists, log and skip #}
          {{ log("Stage " ~ full_stage_name ~ " already exists. Skipping creation.", info=true) }}
        {% else %}
          {# Stage does not exist, create it #}
          {{ log("Creating Stage: " ~ full_stage_name, info=true) }}
          {% set create_stage_sql %}
            CREATE STAGE {{ full_stage_name }}
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
          {{ log("Stage " ~ full_stage_name ~ " created successfully.", info=true) }}
        {% endif %}
      {% endfor %}
      {{ log("--- Finished creating Snowflake Stages ---", info=true) }}
    {% else %}
      {{ log("No 'snowflake_stages' list defined in dbt_project.yml. No stages created.", info=true) }}
    {% endif %}
  {% endif %} {# End of if execute block #}

{% endmacro %}