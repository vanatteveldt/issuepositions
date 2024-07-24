from pyhere import here
import yaml
from functools import lru_cache


def extract_internationalized(item, lang, default_lang="en"):
    if item is None:
        return None
    if isinstance(item, str):
        return item
    if isinstance(item, list):
        return [extract_internationalized(x, lang, default_lang) for x in item]
    if isinstance(item, dict):
        # Is it an internationalized item?
        if lang in item:
            return item[lang]
        if default_lang in item:
            return f"[{default_lang}] {item[default_lang]}"
        # No --> it's probably a regular dict with items
        return {k: extract_internationalized(x, lang, default_lang) for (k, x) in item.items()}
    return None


@lru_cache()
def get_topics_internationalized(language="en") -> dict[str, dict]:
    """"""
    topics = yaml.safe_load(open(here("annotations", "topics.yml")))
    return extract_internationalized(topics, language)  # type: ignore


def describe_topic(key, lang):
    key = t = get_topics_internationalized(lang)[key]
    if lang != "en":
        key = t.get("label").split()[0]
        key = {"O.wijs,": "Onderwijs", "Beter": "Bestuur"}.get(key, key)

    pos = t.get("positive", {})
    neg = t.get("negative", {})
    descriptions = [
        t.get("label"),
        pos.get("label"),
        pos.get("description"),
        neg.get("label"),
        neg.get("description"),
    ]
    description = ". ".join(d for d in descriptions if d)
    if lang == "nl":
        return f"Onderwerp: {key}. Beschrijving: {description}"
    else:
        return f"Issue: {key}. Description: {description}"
