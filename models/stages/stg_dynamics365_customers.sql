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
    )
SELECT 
     {{ generate_hash_key(['customer_id', 'customer_name', 'customer_address', 'customer_email', 'last_updated_date']) }},
     source_casted.*
     
FROM
    source_casted
