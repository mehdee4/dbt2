-- macros/create_snowflake_file_formats.sql

{#
This macro is responsible for creating or replacing Snowflake FILE FORMAT objects.
It now accepts the target database and schema as arguments.
The responsibility for ensuring the schema exists is now with the caller.
#}
{% macro create_snowflake_file_formats(target_database_name, target_schema_name) %}

{#
REMOVED: The call to create_schema_if_not_exists is no longer here.
It should now be called explicitly in the post-hook before this macro.
#}

{# Load the file formats definitions from the 'snowflake_file_formats' variable in dbt_project.yml #}
{% set file_formats_to_create = var('snowflake_file_formats', []) %}

{% if file_formats_to_create %}
{{ log("--- Starting to create/replace Snowflake File Formats in " ~ target_database_name ~ "." ~ target_schema_name ~ " ---", info=true) }}
{% for format_def in file_formats_to_create %}
{% set format_name = format_def.name %}
{% set format_options = format_def.options %}

{% set full_format_name = '"' ~ target_database_name ~ '"."' ~ target_schema_name ~ '"."' ~ format_name ~ '"' %}

{{ log("Creating/Replacing Snowflake File Format: " ~ full_format_name, info=true) }}

{% set create_format_sql %}
CREATE OR REPLACE FILE FORMAT {{ full_format_name }}
{{ format_options }};
{% endset %}

{% do run_query(create_format_sql) %}
{{ log("File Format " ~ full_format_name ~ " created/updated successfully.", info=true) }}
{% endfor %}
{{ log("--- Finished creating/replacing Snowflake File Formats ---", info=true) }}
{% else %}
{{ log("No 'snowflake_file_formats' list defined in dbt_project.yml. No file formats created.", info=true) }}
{% endif %}

{% endmacro %}