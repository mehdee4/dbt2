-- macros/custom_schema_override.sql (UPDATED for casing)

{% macro generate_schema_name(custom_schema_name, node) -%}
    {#-
        This macro ensures the final schema name is consistently uppercase
        for Snowflake to avoid case sensitivity issues.
    -#}

    {%- set default_schema = target.schema -%}

    {%- if custom_schema_name is none -%}
        {{ default_schema | upper | trim }} {# <-- Add | upper here #}
    {%- else -%}
        {{ custom_schema_name | upper | trim }} {# <-- Add | upper here #}
    {%- endif -%}

{%- endmacro %}