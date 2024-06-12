from pyhere import here
import yaml

topics = yaml.safe_load(open(here("annotations", "topics.yml")))


def p(d, indent, inlist=False):
    ll = "- " if inlist else ""
    if not isinstance(d, dict) or "en" not in d:
        if inlist or '"' in d:
            d = repr(d)
        print(f"{'  '*indent}{ll}en: {d}")
    else:
        for lang in ["en", "nl"]:
            if lang in d:
                val = repr(d[lang]) if inlist or '"' in d[lang] else d[lang]
                print(f"{'  '*indent}{ll}{lang}: {val}")
            if ll == "- ":
                ll = "  "


for label, topic in topics.items():
    print(f"{label}:")
    print(f"  label:")
    p(topic["label"], indent=2)
    print(f"  positive:")
    print(f"    label:")
    p(topic["description"], indent=3)
    print(f"    description:")
    p(topic["positive"], indent=3)
    if "examples" in topic:
        print(f"    examples:")
        for example in topic["examples"]:
            p(example, indent=3, inlist=True)
    print(f"  negative:")
    print(f"    label:")
    print(f"      en: {label}-negative")
    print(f"    description:")
    if "negative" in topic:
        p(topic["negative"], indent=3)
    else:
        print(f"      en: {label}-negative-description")
    print()
