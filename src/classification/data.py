# %%
from functools import lru_cache
from typing import Literal, NamedTuple, Protocol

import numpy as np
import pandas as pd
import yaml
from anyio import Path


def get_stances() -> pd.DataFrame:
    stances = pd.read_csv("data/intermediate/stances.csv")
    units = pd.read_csv("data/intermediate/units_tk2023.csv")

    def randomized_mode(x):
        mode_values = x.mode()
        return np.nan if len(mode_values) == 0 else np.random.choice(mode_values)

    d = (
        stances.groupby(["unit_id", "topic"])["stance"]
        .agg(
            [
                ("n", "count"),
                ("stance", randomized_mode),
                ("agreement", lambda x: (x == x.mode().iloc[0]).mean()),
            ]
        )
        .reset_index()
    )

    d = d.merge(units, on="unit_id", how="inner")
    for col in ["before", "after"]:
        d[col] = d[col].fillna("")
    return d[["unit_id", "actor", "topic", "n", "stance", "agreement", "text", "before", "after"]]


class StancesRow(Protocol):
    unit_id: str
    actor: str
    topic: str
    n: int
    stance: Literal["L", "R", "N"]
    agreement: float
    text: str
    before: str
    after: str


class Position(NamedTuple):
    L: str
    R: str


class TopicData(NamedTuple):
    name: str
    label: str
    position_descriptions: Position
    position_labels: Position
    hints: str


@lru_cache()
def get_topics(lang="nl"):
    # Load the YAML file
    with open(Path("codebook//topics.yml"), "r", encoding="utf-8") as file:
        data = yaml.safe_load(file)

    return {
        topicname: TopicData(
            name=topicname,
            label=topic["label"][lang],
            position_labels=Position(L=topic["positive"]["label"][lang], R=topic["negative"]["label"][lang]),
            position_descriptions=Position(
                L=topic["positive"]["description"][lang], R=topic["negative"]["description"][lang]
            ),
            hints=topic.get("hints"),
        )
        for topicname, topic in data.items()
    }
