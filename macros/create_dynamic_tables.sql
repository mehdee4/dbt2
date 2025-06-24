    -- macros/create_dynamic_tables.sql
    {% macro create_dynamic_tables() %}

      {# Define the path to your external YAML configuration file #}
      {% set config_file_path = 'macros/config/tables.yml' %}

      {# Load the configuration from the external YAML file using our custom loader #}
      {% set loaded_config = load_yaml_config(config_file_path) %}

      {% set table_definitions = loaded_config.get('tables', []) %}

      {% if table_definitions is not none and table_definitions | length > 0 %}
        {{ log("--- Starting to create/ensure Snowflake Tables from YAML ---", info=true) }}

        {% for table_def in table_definitions %}
          {% set full_table_name = table_def.table_name %}
          {% set columns = table_def.columns %}

          {% if columns is none or columns | length == 0 %}
            {{ log("Warning: No columns defined for table '" ~ full_table_name ~ "'. Skipping table creation.", info=true) }}
            {% continue %}
          {% endif %}

          {% set column_definitions = [] %}
          {% for col in columns %}
            {% do column_definitions.append(col.name ~ ' ' ~ col.type) %}
          {% endfor %}

          {% set create_table_sql %}
            CREATE OR REPLACE TABLE {{ full_table_name }} (
              {{ column_definitions | join(',\n  ') }}
            );
          {% endset %}

          {{ log("Creating/Replacing Table: " ~ full_table_name, info=true) }}
          {% do run_query(create_table_sql) %}
          {{ log("Table " ~ full_table_name ~ " created/updated successfully.", info=true) }}
        {% endfor %}

        {{ log("--- Finished creating/ensuring Snowflake Tables from YAML ---", info=true) }}
      {% else %}
        {{ log("No table definitions found in " ~ config_file_path ~ ". No tables created.", info=true) }}
      {% endif %}

    {% endmacro %}
    