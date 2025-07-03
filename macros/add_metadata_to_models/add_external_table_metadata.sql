-- macros/add_external_table_metadata.sql

{% macro add_external_table_metadata() -%}
    {# This macro adds common external table metadata columns. #}
    {# It outputs columns separated by commas. #}
    {# IMPORTANT: No line starts with a comma. Only internal lines end with a comma. #}
    {# The overall macro output has NO leading or trailing commas. #}

    '{{ invocation_id }}'::VARCHAR(36) AS STG_DBT_RUN_ID,
    '{{ run_started_at }}'::TIMESTAMP_TZ(9) AS STG_CREATED_AT,

    METADATA$FILENAME::VARCHAR AS SRC_SOURCE_FILE_NAME,
    METADATA$FILE_ROW_NUMBER::BIGINT AS SRC_FILE_ROW_NUMBER,
    METADATA$FILE_LAST_MODIFIED::TIMESTAMP_NTZ(9) AS SRC_FILE_LAST_MODIFIED_TS,
    METADATA$FILE_CONTENT_KEY::VARCHAR AS SRC_FILE_CONTENT_KEY {# <--- NO COMMA AT THE END OF THIS LINE #}
{%- endmacro %}