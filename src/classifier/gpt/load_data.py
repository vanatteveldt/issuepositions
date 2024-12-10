import pandas as pd
import yaml
from pathlib import Path
from typing import TypedDict
from pprint import pprint


def load_data(data_file:Path, topic:str=None):
    "Loads data and filters for specific topic and agreement"

    df = pd.read_csv(data_file)
    df = df[df["text"].notna()]

    if topic:
        df = df.loc[df['topic'] == topic]

    return df


def get_text(df: pd.DataFrame, unit_id: str):
    "Filters the dataframe for the given unit_id and return text corresponding to that id"
    filtered_df = df.loc[df['unit_id'] == unit_id]

    # Check if a matching row exists
    if filtered_df.empty:
        return None
    
    return filtered_df['text'].iloc[0]


class TopicData(TypedDict):
    topic_name: str
    topic: str
    description: dict
    labels: dict
    hints: str


def load_topic_data():
    topic_list = []

    # Load the YAML file
    with open(Path('annotations//topics.yml'), 'r', encoding='utf-8') as file:
        data = yaml.safe_load(file)

    topic_list = []

    for topic in data:
        topic_data:TopicData = {}
        topic_data['topic_name'] = topic
        topic_data['topic'] = data[topic]['label']['nl']
        topic_data['labels'] = {'L': data[topic]['positive']['label']['nl'], 'R' :data[topic]['negative']['label']['nl']}
        topic_data['descriptions'] = {'L': data[topic]['positive']['description']['nl'], 'R' :data[topic]['negative']['description']['nl']}
        if 'hints' in data[topic]:
            topic_data['hints'] = data[topic]['hints']
        topic_list.append(topic_data)

    return topic_list



# Example topic_data

# topic_data:TopicData = {
#     "topic_name": "CivilRights",
#     "topic": "Burgerrechten",
#     "descriptions": {
#         "L": (
#             "Vrijheid van meningsuiting, individuele rechten en vrijheden; "
#             "privacy; gelijke rechten voor alle mensen, ethnische minderheden, "
#             "seksualiteit inc homorechten, transgender, LHBTQI+ rechten; "
#             "weerstand tegen discriminatie of anti-semitisme; zelfbeschikking in "
#             "gezondheidszorg, waaronder abortus en euthanasie"
#         ),
#         "R": (
#             "Traditionele / Christelijke / conservatieve normen en waarden; "
#             "belang van gezin en gemeenschap; bescherming van het (ongeboren) "
#             "leven en het gezin, weerstand tegen abortus / euthanasie, anti-woke"
#         )
#     },
#     "labels": {
#         "L": "Burgerrechten, vrijheid en minderheidsrechten",
#         "R": "Traditionele waarden"
#     },
# }
