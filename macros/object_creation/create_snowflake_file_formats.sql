-- macros/create_snowflake_file_formats.sql

{#
  This macro is responsible for creating Snowflake FILE FORMAT objects.
  It now uses 'CREATE FILE FORMAT IF NOT EXISTS', meaning it will only create
  the format if it doesn't already exist.
  
  IMPORTANT: If a file format with the same name already exists in Snowflake,
  this macro WILL NOT UPDATE its definition even if the 'format_options'
  change in dbt_project.yml. To force an update, you would need to manually
  DROP the file format in Snowflake before running dbt, or switch back to
  'CREATE OR REPLACE FILE FORMAT'.
#}
{% macro create_snowflake_file_formats(target_database_name, target_schema_name) %}

  {# Load the file formats definitions from the 'snowflake_file_formats' variable in dbt_project.yml #}
  {% set file_formats_to_create = var('snowflake_file_formats', []) %}

  {% if file_formats_to_create %}
    {{ log("--- Starting to create Snowflake File Formats (IF NOT EXISTS) in " ~ target_database_name ~ "." ~ target_schema_name ~ " ---", info=true) }}
    {% for format_def in file_formats_to_create %}
      {% set format_name = format_def.name %}
      {% set format_options = format_def.options %}

      {% set full_format_name = '"' ~ target_database_name ~ '"."' ~ target_schema_name ~ '"."' ~ format_name ~ '"' %}

      {{ log("Creating Snowflake File Format (IF NOT EXISTS): " ~ full_format_name, info=true) }}

      {% set create_format_sql %}
        CREATE FILE FORMAT IF NOT EXISTS {{ full_format_name }} {# Changed from CREATE OR REPLACE #}
        {{ format_options }};
      {% endset %}

      {% do run_query(create_format_sql) %}
      {{ log("File Format " ~ full_format_name ~ " creation attempted successfully.", info=true) }}
    {% endfor %}
    {{ log("--- Finished creating Snowflake File Formats ---", info=true) }}
  {% else %}
    {{ log("No 'snowflake_file_formats' list defined in dbt_project.yml. No file formats created.", info=true) }}
  {% endif %}

{% endmacro %}