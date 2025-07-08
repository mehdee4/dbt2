-- models/stg_dynamics365_customers.sql (assuming this is your staging model file)

{{
    config(
        materialized='incremental',
        unique_key='customer_id',
        incremental_strategy='merge',
        cluster_by='file_last_modified_at'
    )
}}

WITH
    source_casted AS (
        SELECT
            VALUE:c1::VARCHAR AS customer_id,
            VALUE:c2::VARCHAR AS customer_name,
            VALUE:c3::VARCHAR AS customer_address,
            VALUE:c4::VARCHAR AS customer_email,
            VALUE:c5::DATE AS last_updated_date,
            VALUE AS row_content,
            {{ add_external_table_metadata() }}
        FROM
            {{ source('src_ext_dynamic365', 'src_ext_dynamic365_customers') }}
    ),

    final_data AS (
        SELECT
             {{ generate_table_sk_key(['customer_id', 'customer_name', 'customer_address', 'customer_email', 'last_updated_date']) }} AS customer_surrogate_key,
             source_casted.*,
             METADATA$FILE_LAST_MODIFIED AS file_last_modified_at
        FROM
            source_casted
    )

SELECT
    *
FROM
    final_data

{% if is_incremental() %}
    -- On incremental runs, filter to process only records from files
    -- that have been modified *after* the latest file modification
    -- timestamp already present in the target table.
    WHERE file_last_modified_at > (SELECT MAX(file_last_modified_at) FROM {{ this }})
{% endif %}