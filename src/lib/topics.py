from pyhere import here
import yaml


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
        return {
            k: extract_internationalized(x, lang, default_lang)
            for (k, x) in item.items()
        }
    return None


def get_topics_internationalized(language="en") -> dict[str, dict]:
    """"""
    topics = yaml.safe_load(open(here("annotations", "topics.yml")))
    return extract_internationalized(topics, language)  # type: ignore
