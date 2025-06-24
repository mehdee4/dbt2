-- macros/create_snowflake_schemas.sql
{% macro create_snowflake_schemas() %}
  {#
    This macro is responsible for creating or ensuring the existence of Snowflake schemas.
    It reads the schema definitions from the 'snowflake_schemas' variable in dbt_project.yml.
    It calls the 'create_schema_if_not_exists' helper macro for each schema.
  #}

  {# Load the schema definitions from the 'snowflake_schemas' variable in dbt_project.yml #}
  {% set schemas_to_create = var('snowflake_schemas', []) %} {# Use var() to get the list #}

  {# Check if the 'schemas_to_create' list is not empty #}
  {% if schemas_to_create %}
    {{ log("--- Starting to create/ensure Snowflake Schemas ---", info=true) }}
    {# Loop through each schema definition provided in the variable #}
    {% for schema_def in schemas_to_create %}
      {% set schema_name_to_create = schema_def.name %}

      {#
        Call the 'create_schema_if_not_exists' macro (from its own file)
        to handle the actual creation logic for each schema.
        It will create the schema in the current target.database (e.g., DBT_DEV).
      #}
      {% do create_schema_if_not_exists(target.database, schema_name_to_create) %}
    {% endfor %}
    {{ log("--- Finished creating/ensuring Snowflake Schemas ---", info=true) }}
  {% else %}
    {# Log a warning if no schemas are defined in the variable #}
    {{ log("No 'snowflake_schemas' list defined in dbt_project.yml. No schemas created.", info=true) }}
  {% endif %}

{% endmacro %}