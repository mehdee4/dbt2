-- macros/create_snowflake_stages.sql

{#
This macro is responsible for creating or replacing Snowflake EXTERNAL or INTERNAL STAGE objects.
It now accepts the target database and schema as arguments, allowing
it to be called from a post-hook using 'this.database' and 'this.schema'.
It will consistently use CREATE OR REPLACE STAGE for idempotency.
#}
{% macro create_snowflake_stages(target_database_name, target_schema_name) %}

{% set stages_to_create = var('snowflake_stages', []) %}
{% set file_formats_available = var('snowflake_file_formats', []) %}

{% set file_formats_map = {} %}
{% if file_formats_available %}
{% for format in file_formats_available %}
{#
Update: Use the passed target_database_name and target_schema_name
to construct the full object name for file formats. This ensures
the map contains fully qualified names relevant to the current deployment context.
#}
{% set full_format_object_name = '"' ~ target_database_name ~ '"."' ~ target_schema_name ~ '"."' ~ format.name ~ '"' %}
{% do file_formats_map.update({format.name: full_format_object_name}) %}
{% endfor %}
{% endif %}

{% if stages_to_create %}
{{ log("--- Starting to create/replace Snowflake Stages in " ~ target_database_name ~ "." ~ target_schema_name ~ " ---", info=true) }}
{% for stage_def in stages_to_create %}
{% set stage_name = stage_def.name %}
{% set stage_url = stage_def.get('url') %} {# Use .get() to return None if not present #}
{% set file_format_ref = stage_def.get('file_format_ref') %}
{% set credentials = stage_def.get('credentials') %}
{% set storage_integration = stage_def.get('storage_integration') %}
{% set is_internal_stage = stage_def.get('is_internal', false) %}
{% set directory_table = stage_def.get('directory', false) %} {# This is the variable from your dbt_project.yml #}


{% set full_stage_name = '"' ~ target_database_name ~ '"."' ~ target_schema_name ~ '"."' ~ stage_name ~ '"' %}

{% set resolved_file_format = "" %}
{% if file_format_ref and file_formats_map[file_format_ref] is defined %}
{% set resolved_file_format = file_formats_map[file_format_ref] %}
{% else %}
{{ log("Warning: No valid file_format_ref '" ~ file_format_ref ~ "' found in file_formats_map for stage '" ~ stage_name ~ "'. Stage may fail to create or require manual correction.", info=true) }}
{% endif %}

{{ log("Creating/Replacing Snowflake Stage: " ~ full_stage_name ~ (" (Internal)" if is_internal_stage else " (External)"), info=true) }}

{% set create_stage_sql %}
CREATE OR REPLACE STAGE {{ full_stage_name }}
{% if not is_internal_stage %} {# Only include URL for external stages #}
URL = '{{ stage_url }}'
{% endif %}
{% if resolved_file_format %}
FILE_FORMAT = {{ resolved_file_format }}
{% endif %}
{% if not is_internal_stage %} {# Only include credentials/storage_integration for external stages #}
{% if credentials %}
CREDENTIALS = ({{ credentials }})
{% endif %}
{% if storage_integration %}
STORAGE_INTEGRATION = "{{ storage_integration }}"
{% endif %}
{% endif %}
{# *** FIX IS HERE *** #}
{% if is_internal_stage and directory_table %}
DIRECTORY = (ENABLE = TRUE AUTO_REFRESH = FALSE) {# <--- CORRECT SYNTAX FOR DIRECTORY #}
{% endif %};
{% endset %}

{% do run_query(create_stage_sql) %}
{{ log("Stage " ~ full_stage_name ~ " created/updated successfully.", info=true) }}
{% endfor %}
{{ log("--- Finished creating/replace Snowflake Stages ---", info=true) }}
{% else %}
{{ log("No 'snowflake_stages' list defined in dbt_project.yml. No stages created.", info=true) }}
{% endif %}

{% endmacro %}