{% for name, topic in topics.items() %}

# {{ name }}{% if 'description' in topic %}: {{ x(topic['description']) }} {% endif %}

{% if 'positive' in topic -%}
{{ phrases.positive}}: {{ x(topic['positive'])}}

{% endif -%}

{% if 'examples' in topic -%}
#### {{ phrases.examples -}}:
{% for ex in topic.examples -%}
- {{ x(ex) }}
{% endfor %}
{% endif -%}

{% if 'negative' in topic -%}
{{ phrases.negative}}: {{ x(topic['negative'])}}

{% endif -%}

{% if 'negative_examples' in topic -%}
#### {{ phrases.negative_examples -}}:
{% for ex in topic.negative_examples -%}
- {{ x(ex) }}
{% endfor -%}
{% endif -%}
{% endfor -%}
