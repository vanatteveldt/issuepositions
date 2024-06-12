# Issue dimensions

**Note:** This document is genated automatically from the [topic list](topics.yml).
Please do not edit this document directly.

{% for name, topic in topics.items() %}

## [`{{ name }}`] {{ x(topic['label']) }}
{% for pole in ['positive', 'negative'] -%}
  {% set d = topic[pole] %}
### _{{ phrases[pole]}}_ **{{ x(d['label'])}}**
{{ x(d['description'])}}
{% if 'examples' in d -%}
{% for ex in d.examples -%}
#### {{ phrases.examples -}}:

- {{ x(ex) }}
  {% endfor %}
  {% endif -%}
{% endfor %}
{% endfor %}
