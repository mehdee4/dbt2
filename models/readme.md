## source
    Overview
        Place where you get your data loaded from the source (any source, for examle data lakes) to snowflake

    Naming convensions

        - Tables
            - src_<rest>. 
                - example: src_daily_sales
        - Columns

            - src_filename
            The row number within the file from which the record was loaded.

            - src_file_row_number
                The row number within the file from which the record was loaded.

            - src_FILE_CONTENT_KEY
                A unique identifier ( a hash) for the content of the file. 
                Use Case: Excellent for detecting if a source file's content has changed without needing to compare the entire file, which is useful for incremental processing or data validation.

            - src_file_last_modified
                The timestamp when the source file was last modified
                Use Case: Helps in understanding data freshness and can be used in incremental loading patterns or for identifying recently updated files

            - src_scan_time
                The timestamp when the external table refresh process
                Use Case: for knowing when Snowflake last processed a specific file.            

## Staging 
    Overview
        Place where :
            -  flatten data from the source
            -  define data types
            - You do NOT change source field names

    Naming convensions

        - Tables
            - stg_<prefix followed by source 'table' name without src>. 
                - example: stg_sap_sales
        - Columns
            - stg_primary key
                - <tableName>_ID 
                    - example : ord.order_id

            - stg_filename
              - to be copied from the source

            - stg_file_row_number
               - to be copied from the source

            - stg_FILE_CONTENT_KEY
                - to be copied from the source

            - stg_file_last_modified
                - to be copied from the source




## Intermediate 
    Overview
        where you encapsulate reusable, complex, or shared business logic that doesn't belong in the raw staging layer but isn't yet in its final, aggregated mart form.

    Naming convensions

        - Tables
            - int_<prefix followed by a descriptive name that reflects the data's content>. 
                - example: int_daily_sales_by_product
        - Columns
            - primary key
                - <tableName>_ID 
                    - example : ord.order_id
            - Foreign key
                - <dimensionName>_ID
                    - example customer_id
            - Booleans
                - Use -is as prefix 
                    - example : is_active_customer, is_multiproduct_order
            - Time
                - Use -time suffix
                    - example : delivering_time
            - Date
                - Use -date suffix
                    - example : customer_sign_up_date
            - Timestamp
                - use -at suffix
            
            - Aggregations
                - avoid abbreviations and add the name of the function (count, sum, etc.) as prefix

            - dimensions 
                - use  clear name for the dimensions, avoid abbreviation if possible. When applicable, 
                use a prefix that indicate the domain of the dimension (product, customer etc.)

            - table alilases
                - use meaningful aliases with AT LEAST 3 characters


            Example:
            SELECT 
                ord.order_id, -- primary key 
                ord.customer_id, -- forigen key
                ord.product_name, -- dimensions
                cus.is_active_customer, -- booleans
                cus.customer_sign_up_date, -- dates 
                ord.dispatched_at, -- timestamps 
                ord.delivering_time, -- time measures 
                ord.count_products, -- aggregated fields
            FROM {{ ref('stg_orders') }} ord -- table aliases 
            LEFT JOIN {{ ref('stg_customers') }} cus 
                ON ord.customer_id = cus.customer_id
