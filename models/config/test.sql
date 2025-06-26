SELECT
*
FROM
    {{ source('pos_raw_data', 'raw_menu_data') }}    