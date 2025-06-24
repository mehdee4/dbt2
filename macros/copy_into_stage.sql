{% macro copy_from_stage(model_name) %}
  {{ log("DEBUG: model_name passed to macro: " ~ model_name, info=True) }}
  {{ log("DEBUG: Graph keys: " ~ graph['nodes'].keys() | string, info=True) }}

  {%- set model = none -%}
  {%- for key, node in graph['nodes'].items() %}
    {%- if key | lower | slice(-model_name | length) == model_name | lower %}
      {%- set model = node -%}
      {%- break -%}
    {%- endif %}
  {%- endfor %}

  {%- if not model %}
    {% do exceptions.raise_compiler_error("Model '" ~ model_name ~ "' not found in graph.") %}
  {%- endif %}

  {%- set copy_cfg = model.config.get('copy_options') %}
  {%- if copy_cfg is none or copy_cfg.stage_path is none -%}
    {% do exceptions.raise_compiler_error("Missing 'copy_options.stage_path' in model " ~ model_name) %}
  {%- endif %}

  COPY INTO {{ model_name }}
  FROM {{ copy_cfg.stage_path }}
  FILE_FORMAT = {{ copy_cfg.file_format | default('(type = csv)') }}
  ON_ERROR = '{{ copy_cfg.on_error | default("CONTINUE") }}'
{% endmacro %}