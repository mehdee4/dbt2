-- models/test_surrogate_key_simple.sql

SELECT
    {{ dbt_utils.generate_surrogate_key(['value1', 'value2', 'value3']) }} AS test_key_default_output

   