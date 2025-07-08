-- snapshots/history_dynamics365_customers.sql

{% snapshot history_dynamics365_customers %}

{{
    config(
        target_schema='history',
        unique_key='stg_dynamics365_customers_KEY', 
        strategy='timestamp',
        updated_at='last_updated_date',
        invalidate_hard_deletes=True
    )
}}

SELECT
    *
FROM
    {{ ref('stg_dynamics365_customers') }}

{% endsnapshot %}