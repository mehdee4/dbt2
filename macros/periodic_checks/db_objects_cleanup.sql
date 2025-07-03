{% macro prune_outdated_objects(databases_to_check=None, schemas_to_check=None, dry_run=True) %}

{#This macro identifies database tables/views that were created by dbt but are no longer defined in your current dbt project. It then logs or optionally executes DROP statements to remove these "orphaned" objects, helping to keep your database clean and in sync with your code.#}
    
    {# --- Input Validation --- #}
    {% if not databases_to_check %}
        {# Default to current target database if not specified #}
        {% set databases_to_check = [target.database] %}
    {% endif %}

    {% if not schemas_to_check %}
        {# Default to current target schema if not specified #}
        {% set schemas_to_check = [target.schema] %}
    {% endif %}

    {% if not databases_to_check or not schemas_to_check %}
        {% do log("Error: databases_to_check and schemas_to_check cannot be empty after defaults. Please provide valid lists.", info=true) %}
        {{ return('') }}
    {% endif %}

    {% do log("Starting prune_outdated_objects macro...", info=true) %}
    {% do log("Checking databases: " ~ databases_to_check | join(', '), info=true) %}
    {% do log("Checking schemas: " ~ schemas_to_check | join(', '), info=true) %}
    {% do log("Dry run mode: " ~ dry_run, info=true) %}

    {# --- 1. Get all currently active dbt models/seeds/snapshots from the graph --- #}
    {% set current_dbt_objects = {} %}
    {% for node in graph.nodes.values() %}
        {# We only care about resources that materialize as tables or views in the database #}
        {% if node.resource_type in ['model', 'seed', 'snapshot'] %} 
            {% set full_name = node.database ~ '.' ~ node.schema ~ '.' ~ node.name %}
            {# Store in uppercase for robust case-insensitive comparison with INFORMATION_SCHEMA results #}
            {% do current_dbt_objects.update({full_name.upper(): node.resource_type}) %} 
        {% endif %}
    {% endfor %}

    {% do log("Found " ~ current_dbt_objects | length ~ " active dbt objects in the current project.", info=true) %}

    {% set objects_to_drop = [] %}
    {% set drop_statements = [] %}

    {# --- 2. Query Snowflake's INFORMATION_SCHEMA for existing objects in target schemas --- #}
    {% for db_name_check in databases_to_check %}
        {% for schema_name_check in schemas_to_check %}
            {% set info_schema_query %}
                SELECT
                    TABLE_CATALOG AS DATABASE_NAME,
                    TABLE_SCHEMA AS SCHEMA_NAME,
                    TABLE_NAME AS OBJECT_NAME,
                    'TABLE' AS OBJECT_TYPE -- Label as 'TABLE' for consistency with DROP command
                FROM {{ db_name_check | upper }}.INFORMATION_SCHEMA.TABLES
                WHERE TABLE_SCHEMA = '{{ schema_name_check | upper }}'
                AND TABLE_TYPE IN ('BASE TABLE', 'TEMPORARY', 'EXTERNAL TABLE') -- Filter for actual tables

                UNION ALL

                SELECT
                    TABLE_CATALOG AS DATABASE_NAME,
                    TABLE_SCHEMA AS SCHEMA_NAME,
                    TABLE_NAME AS OBJECT_NAME,
                    'VIEW' AS OBJECT_TYPE -- Label as 'VIEW'
                FROM {{ db_name_check | upper }}.INFORMATION_SCHEMA.VIEWS
                WHERE TABLE_SCHEMA = '{{ schema_name_check | upper }}'
            {% endset %}

            {% set results = run_query(info_schema_query) %}

            {% if execute %} {# Only run this block during actual execution, not during parsing #}
                {% for row in results.rows %}
                    {% set db_name = row['DATABASE_NAME'] %}
                    {% set sch_name = row['SCHEMA_NAME'] %}
                    {% set obj_name = row['OBJECT_NAME'] %}
                    {% set obj_type = row['OBJECT_TYPE'] %}
                    
                    {% set full_object_path = db_name ~ '.' ~ sch_name ~ '.' ~ obj_name %}

                    {# --- 3. Compare: If Snowflake object is NOT in current dbt graph --- #}
                    {% if full_object_path.upper() not in current_dbt_objects %}
                        {% set drop_sql = "DROP " ~ obj_type ~ " IF EXISTS " ~ full_object_path ~ ";" %}
                        {% do objects_to_drop.append(full_object_path ~ ' (' ~ obj_type ~ ')') %}
                        {% do drop_statements.append(drop_sql) %}
                    {% endif %}
                {% endfor %}
            {% endif %}
        {% endfor %}
    {% endfor %}

    {# --- 4. Log and Execute Drop Statements --- #}
    {% if objects_to_drop | length > 0 %}
        {% do log('Identified ' ~ objects_to_drop | length ~ ' objects for potential removal:', info=true) %}
        {% for obj_path in objects_to_drop %}
            {% do log('- ' ~ obj_path, info=true) %}
        {% endfor %}

        {% if dry_run %}
            {% do log('--- DRY RUN COMPLETE ---', info=true) %}
            {% do log('No objects were dropped. To execute, set dry_run=False.', info=true) %}
            {% do log('Generated DDL (Dry Run):', info=true) %}
            {% for sql in drop_statements %}
                {% do log('  ' ~ sql, info=true) %}
            {% endfor %}
        {% else %}
            {% do log('--- EXECUTING DROP STATEMENTS ---', info=true) %}
            {% for sql in drop_statements %}
                {% do log('Executing: ' ~ sql, info=true) %}
                {% do run_query(sql) %}
            {% endfor %}
            {% do log('Cleanup complete. Objects dropped.', info=true) %}
        {% endif %}
    {% else %}
        {% do log('No outdated objects found for cleanup.', info=true) %}
    {% endif %}

{% endmacro %}