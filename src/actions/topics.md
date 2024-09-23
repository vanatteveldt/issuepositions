# Issue dimensions

**Note:** This document is genated automatically from the [topic list](topics.yml).
Please do not edit this document directly.

<table>
{% for name, topic in topics.items() %}
  {% set p = topic['positive'] %}
  {% set n = topic['negative'] %}

<tr><td colspan="2"><h1>{{x(topic['label'])}}</h1></td></tr>
{% if topic['description'] %}
<tr><td colspan="2"><em>{{phrases.description}}:</em> {{x(topic['description'])}}</td></tr>
{% endif %}
<tr><td><b>{{x(p.label)}}</b></td><td><b>{{x(n.label)}}</b></td></tr>
<tr><td>{{x(p.description)}}</td><td>{{x(n.description)}}</td></tr>
<tr>
  <td>
  {% if p.examples %}
  <em>{{phrases.examples}}:</em>
  <ul>
   {% for ex in p.examples %}
   <li> {{x(ex)}}
   {% endfor %}
   </ul>
  {% endif %}
  </td>
    <td>
  {% if n.examples %}
  <em>{{phrases.examples}}:</em>
  <ul>
   {% for ex in n.examples %}
   <li> {{x(ex)}}
   {% endfor %}
   </ul>
  {% endif %}
  </td>
</tr>
{% if topic['hints'] %}
<tr><td colspan="2"><em>{{phrases.hints}}:</em> {{x(topic['hints'])}}</td></tr>
{% endif %}

{% endfor %}
</table>
