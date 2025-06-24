-- macros/create_schema_if_not_exists.sql

{#
  This is a generic helper macro.
  It checks if a schema exists within a given database and creates it if it does not.
  This macro does NOT hardcode the schema name.
#}
{% macro create_schema_if_not_exists(database_name, schema_name) %}

  {# Query INFORMATION_SCHEMA to check if the schema already exists in Snowflake #}
  {% set schema_exists_sql %}
    SELECT EXISTS (
      SELECT 1
      FROM "{{ database_name }}".INFORMATION_SCHEMA.SCHEMATA
      WHERE SCHEMA_NAME = '{{ schema_name | upper }}' {# Schema names are typically uppercase in Snowflake #}
    );
  {% endset %}

  {% set schema_exists_result = run_query(schema_exists_sql) %}
  {% set schema_exists = schema_exists_result.columns[0].values()[0] %}

  {% if not schema_exists %}
    {{ log("Schema " ~ database_name ~ "." ~ schema_name ~ " does not exist. Creating it...", info=true) }}
    {# Construct the SQL to create the schema, using IF NOT EXISTS for idempotency #}
    {% set create_schema_sql %}
      CREATE SCHEMA IF NOT EXISTS "{{ database_name }}"."{{ schema_name }}";
    {% endset %}
    {# Execute the SQL query #}
    {% do run_query(create_schema_sql) %}
    {{ log("Schema " ~ database_name ~ "." ~ schema_name ~ " created successfully.", info=true) }}
  {% else %}
    {# If the schema already exists, log a message and skip creation #}
    {{ log("Schema " ~ database_name ~ "." ~ schema_name ~ " already exists. Skipping creation.", info=true) }}
  {% endif %}

{% endmacro %}