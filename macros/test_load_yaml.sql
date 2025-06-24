-- macros/test_load_yaml.sql
{% macro test_load_yaml_availability() %}
  {# This macro checks if dbt has parsed models and sources,
     which are typically defined in schemas.yml files. #}

  {% set model_count = (graph.nodes | selectattr('resource_type', '==', 'model') | list | length) %}
  {% set source_count = (graph.sources | list | length) %}

  {{ log("--- Checking dbt project for YAML-defined resources ---", info=true) }}

  {% if model_count > 0 %}
    {{ log("SUCCESS: dbt has parsed " ~ model_count ~ " models from your project YAMLs.", info=true) }}
    {{ log("Example Model Names:", info=true) }}
    {% for node in graph.nodes | selectattr('resource_type', '==', 'model') %}
      {{ log("- " ~ node.name, info=true) }}
    {% endfor %}
  {% else %}
    {{ log("FAILURE: No models found parsed from project YAMLs. Check your model definitions.", info=true) }}
  {% endif %}

  {{ log(" ", info=true) }} {# Blank line for readability #}

  {% if source_count > 0 %}
    {{ log("SUCCESS: dbt has parsed " ~ source_count ~ " sources from your project YAMLs.", info=true) }}
    {{ log("Example Source Names (schema.table):", info=true) }}
    {% for source in graph.sources %}
      {{ log("- " ~ source.schema ~ "." ~ source.name, info=true) }}
    {% endfor %}
  {% else %}
    {{ log("FAILURE: No sources found parsed from project YAMLs. Check your source definitions.", info=true) }}
  {% endif %}

  {{ log("--------------------------------------------------", info=true) }}

{% endmacro %}