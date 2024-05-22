import jinja2
import yaml
from pyhere import here
from functools import partial

jinja = jinja2.Environment(loader=jinja2.FileSystemLoader(searchpath=here("src", "actions")))
template = jinja.get_template('topics.md')

phrases_dict = dict(
    positive=dict(en="Positions in favour include",
                  nl="Positieve standpunten zijn bijvoorbeeld"),
    examples=dict(en="Examples",
                  nl="Voorbeelden"),
    negative=dict(en="Positions against this dimension include",
                  nl="Negatieve standpunten zijn bijvoorbeeld"),
    negative_examples=dict(en="Examples of negative positions",
                  nl="Voorbeelden van negatieve standpunten"),
)

def extract_internationalized(item, lang, default_lang='en'):
    if item is None:
        return "∅"
    if isinstance(item, str):
        return item
    if lang in item:
        return item[lang]
    if default_lang in item:
        return f"[{default_lang}] {item[default_lang]}"
    return "⁇"

topics = yaml.safe_load(open(here("annotations", "topics.yml")))
for lang in ['en', 'nl']:
    jinja.globals['x'] = partial(extract_internationalized, lang=lang)
    phrases = {k: extract_internationalized(v, lang=lang) for (k,v) in phrases_dict.items()}
    of = here("annotations", f"topics-{lang}.md")
    print(of)
    with of.open("w") as stream:
        md = template.render(**locals())
        stream.write(md)
