-- macros/create_snowflake_file_formats.sql

{#
  This macro is responsible for creating or replacing Snowflake FILE FORMAT objects.
  It reads the definitions from the 'snowflake_file_formats' variable in dbt_project.yml.
#}
{% macro create_snowflake_file_formats() %}

  {#
    First, ensure the dedicated 'CONFIGS' schema exists in the target database.
    This macro calls 'create_schema_if_not_exists' (defined in its own .sql file)
    and passes the current target database and "CONFIGS" as the schema name.
  #}
  {% do create_schema_if_not_exists(target.database, "CONFIGS") %}

  {# Load the file formats definitions from the 'snowflake_file_formats' variable in dbt_project.yml #}
  {% set file_formats_to_create = var('snowflake_file_formats', []) %} {# Use var() to get the list #}

  {# Check if the 'file_formats_to_create' list is not empty #}
  {% if file_formats_to_create %}
    {{ log("--- Starting to create/replace Snowflake File Formats ---", info=true) }}
    {# Loop through each file format definition provided in the variable #}
    {% for format_def in file_formats_to_create %}
      {% set format_name = format_def.name %}
      {% set format_options = format_def.options %}
      {% set schema_name = "CONFIGS" %} {# Hardcoding the schema name as per your design #}

      {# Construct the fully qualified name for the FILE FORMAT object in Snowflake #}
      {% set full_format_name = '"' ~ target.database ~ '"."' ~ schema_name ~ '"."' ~ format_name ~ '"' %}

      {{ log("Creating/Replacing Snowflake File Format: " ~ full_format_name, info=true) }}

      {#
        Construct the CREATE OR REPLACE FILE FORMAT SQL statement.
        'CREATE OR REPLACE' ensures idempotency:
        - If the format doesn't exist, it's created.
        - If the format exists, it's replaced with the new definition (if changed).
      #}
      {% set create_format_sql %}
        CREATE OR REPLACE FILE FORMAT {{ full_format_name }}
        {{ format_options }};
      {% endset %}

      {# Execute the SQL query to create/replace the file format #}
      {% do run_query(create_format_sql) %}
      {{ log("File Format " ~ full_format_name ~ " created/updated successfully.", info=true) }}
    {% endfor %}
    {{ log("--- Finished creating/replacing Snowflake File Formats ---", info=true) }}
  {% else %}
    {# Log a warning if no file formats are defined in the variable #}
    {{ log("No 'snowflake_file_formats' list defined in dbt_project.yml. No file formats created.", info=true) }}
  {% endif %}

{% endmacro %}