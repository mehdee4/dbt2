-- macros/schema_access_grants.sql (UPDATED)

{% macro create_and_grant_schema_role(database_name, schema_name, target_env_name, consumer_role_suffix='_READER') %}
{#
    This macro creates a dedicated role for a given schema and grants
    read-only access to that schema (and its current/future tables/views)
    to the newly created role. The role name is environment-specific.

    Args:
        database_name (str): The name of the database where the schema resides.
        schema_name (str): The name of the schema for which to create the role.
        target_env_name (str): The name of the current dbt target (e.g., 'dev', 'test', 'prod').
        consumer_role_suffix (str): Suffix for the new role name (e.g., '_READER' -> MY_SCHEMA_READER_DEV).
#}

{%- set new_role_name = (schema_name ~ consumer_role_suffix ~ '_' ~ target_env_name) | upper -%}
{# Example: STG_SAP_READER_DEV #}

-- Start a transaction for these DDL operations
BEGIN;

-- 1. Create the new role if it doesn't already exist
CREATE ROLE IF NOT EXISTS "{{ new_role_name }}";

-- 2. Grant USAGE on the database to the new role
GRANT USAGE ON DATABASE "{{ database_name }}" TO ROLE "{{ new_role_name }}";

-- 3. Grant USAGE on the schema to the new role
--    This is crucial for the role to 'see' the schema
GRANT USAGE ON SCHEMA "{{ database_name }}"."{{ schema_name }}" TO ROLE "{{ new_role_name }}";

-- 4. Grant SELECT on ALL *EXISTING* tables in the schema to the new role
GRANT SELECT ON ALL TABLES IN SCHEMA "{{ database_name }}"."{{ schema_name }}" TO ROLE "{{ new_role_name }}";

-- 5. Grant SELECT on ALL *FUTURE* tables in the schema to the new role
--    This ensures that newly materialized models automatically get the grant
GRANT SELECT ON FUTURE TABLES IN SCHEMA "{{ database_name }}"."{{ schema_name }}" TO ROLE "{{ new_role_name }}";

-- 6. Grant SELECT on ALL *EXISTING* views in the schema to the new role
GRANT SELECT ON ALL VIEWS IN SCHEMA "{{ database_name }}"."{{ schema_name }}" TO ROLE "{{ new_role_name }}";

-- 7. Grant SELECT on ALL *FUTURE* views in the schema to the new role
--    This ensures that newly materialized views automatically get the grant
GRANT SELECT ON FUTURE VIEWS IN SCHEMA "{{ database_name }}"."{{ schema_name }}" TO ROLE "{{ new_role_name }}";

-- Commit the transaction
COMMIT;

-- Optional: Print a message to the dbt log
{% do log('Created and granted role ' ~ new_role_name ~ ' for schema ' ~ database_name ~ '.' ~ schema_name ~ ' in ' ~ target_env_name ~ ' environment', info=true) %}

{% endmacro %}