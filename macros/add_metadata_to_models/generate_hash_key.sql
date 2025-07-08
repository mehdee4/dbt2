-- macros/generate_hash_key.sql

{% macro generate_hash_key(columns) -%}
    {#
        Generates a Snowflake MD5_BINARY hash key (Surrogate Key) from a list of columns.
        The key is cast to BINARY(16).
        Each column is transformed as: UPPER(NVL(NULLIF(TRIM(column),''), '-1'))
        The transformed parts are concatenated with '~'.

        Args:
            columns (list): A list of column names (strings) to include in the hash.
                            These typically represent the natural key components.
        Output:
            SQL column expression (e.g., MD5_BINARY(...) AS table_name_KEY), NO leading/trailing comma.
    #}

    {% if not columns or not columns is iterable or columns is string %}
        {{ exceptions.raise_compiler_error(
            "The 'generate_hash_key' macro requires a list of column names as input. " ~
            "Example: {{ generate_hash_key(['col1', 'col2']) }}"
        ) }}
    {% endif %}

    {% set transformed_parts = [] %}

    {% for col in columns -%}
        {%- do transformed_parts.append(
            "UPPER(NVL(NULLIF(TRIM(" ~ col ~ "::VARCHAR), ''), '-1'))"
        ) -%}
    {% endfor %}

    {% set hash_expression = "MD5_BINARY(" ~ transformed_parts | join(" || '~' || ") ~ ")" %}
    
    {# CHANGE: Alias suffix from _sk to _KEY #}
    {% set alias_name = model.name ~ '_KEY' %}

    {# CHANGE: Explicitly cast the MD5_BINARY output to BINARY(16) #}
    {{ hash_expression }}::BINARY(16) AS {{ alias_name }}
{%- endmacro %}