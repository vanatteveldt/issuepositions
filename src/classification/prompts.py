import json
import logging
from ast import Tuple
from enum import Enum
from textwrap import dedent, indent
from typing import Iterable, Literal, Protocol

import dotenv
import pandas as pd
from openai import OpenAI
from pydantic import BaseModel, ValidationError

from classification.data import StancesRow, get_stances, get_topics


class Prompts:

    extra_explanation = open("codebook/codebook-nl.md").read()

    INSTRUCTION = dedent(
        """
        ## Uitleg: standpunt coderen over {topic.label}

        Hier volgt telkens een drietal zinnen met een gemarkeerde actor. De centrale vraag is wat het standpunt is van de actor over {topic.label}.
        De drie zinnen zijn aangegeven met triple back ticks (```)

        Je kiest hiervoor tussen de twee dimensies die hieronder uitgelegd worden.

        Is {actor} voor meer {topic.position_labels.L}, of juist voor meer {topic.position_labels.R}?
        Als {actor} juist tegen {topic.position_labels.L} is, kies dan {topic.position_labels.R} en andersom.

        Je mag deze ruim interpreteren, het gaat om de algemene politieke richting, niet om de exacte bewoording van de dimensie.
        Als het standpunt echt niet bij de dimensies past, of niet duidelijk is, of over een ander ondewerp gaat, kies dan 'Geen/Ander/Neutraal'.

        ## Taak: Wat is het standpunt van {actor} over {topic.label}?

        * L: {topic.position_labels.L}: {topic.position_descriptions.L}
        * R: {topic.position_labels.R}: {topic.position_descriptions.R}
        * N: Geen/Ander/Neutraal: {actor} heeft geen standpunt heeft over {topic.label}, of het standpunt is niet duidelijk of past niet in de dimensies hierboven.

        ## Opdracht:
        {task}
        """
    )

    TASK = "Codeer de volgende tekst als L, N, of R. Geef je respons als json {{{{'standpunt': 'ANTWOORD'}}}}"

    TASK_REASONING = dedent(
        f"""
        Leg uit hoe je het standpunt van {{actor}} in de volgende zin zou coderen, en codeer het vervolgens al L, N, of R.
        Geef je respons als json {{{{'uitleg': 'UITLEG', 'standpunt': 'ANTWOORD'}}}}
        """
    )


class PositionEnum(str, Enum):
    L = "L"
    N = "N"
    R = "R"


class Standpunt(BaseModel):
    standpunt: PositionEnum

    def model_dump_json(self):
        return json.dumps(dict(standpunt=self.standpunt.value))


class BeredeneerdStandpunt(BaseModel):
    uitleg: str
    standpunt: PositionEnum

    def model_dump_json(self):
        return json.dumps(dict(standpunt=self.standpunt.value, uitleg=self.uitleg))


class Model(Protocol):
    def classify(self, text: str, actor: str, topic_name: str, method: Literal["0shot-reasoning"]): ...


class GPT(Model):
    def __init__(self, model="gpt-4.1", examples_df=None):
        # Load OPENAI_API_KEY from .env
        dotenv.load_dotenv()
        self.client = OpenAI()
        self.topics = get_topics()
        self.model = model
        self.examples_df = examples_df

    def prompt(self, prompts, output=Standpunt):
        try:
            result = self.client.responses.parse(model=self.model, text_format=output, input=prompts)
            return result.output_parsed
        except ValidationError:
            logging.exception("Error on parsing GPT result")
            return None

    def classify(self, text: str, actor: str, topic_name: str, nshot=0, reasoning=False):
        topic = self.topics[topic_name]
        task = (Prompts.TASK_REASONING if reasoning else Prompts.TASK).format(**locals())
        instruction = Prompts.INSTRUCTION.format(topic=topic, text=text, actor=actor, task=task)
        prompts = [{"role": "system", "content": instruction}]
        if nshot:
            for example_text, response in create_examples(self.examples_df, actor, topic_name, n=nshot):
                prompts += [
                    {"role": "user", "content": example_text},
                    {"role": "assistant", "content": response.model_dump_json()},
                ]
            prompts += [{"role": "user", "content": task}]

        prompts += [{"role": "user", "content": text}]
        output = BeredeneerdStandpunt if reasoning else Standpunt
        return self.prompt(prompts, output=output)


def create_example(row: StancesRow) -> BeredeneerdStandpunt:
    text = " ".join([row.before, row.text, row.after])
    topics = get_topics()
    uitleg = (
        "Er is geen standpunt, of het standpunt is niet helder"
        if row.stance == "N"
        else getattr(topics[row.topic].position_descriptions, row.stance)
    )
    return text, BeredeneerdStandpunt(standpunt=row.stance, uitleg=uitleg)


def create_examples(df, actor, topic, n=1, seed=1) -> Iterable[tuple[str, Standpunt]]:
    for stance in ["L", "R", "N"]:
        options = df[(df["topic"] == topic) & (df["actor"] == actor) & (df["stance"] == stance)]
        if len(options) < n:
            logging.warning(f"Could only generate {len(options)} examples for {actor}:{topic}:{stance}")
            continue
        for row in options.sample(n=min(n, len(options)), random_state=seed).itertuples():
            yield create_example(row)


if __name__ == "__main__":
    d = get_stances()
    m = GPT(examples_df=d)
    actor = "de VVD"
    text = "De VVD wil het leger geheel afschaffen"

    examples = create_examples(d, "VVD", "Defense")

    print(m.classify(text, actor, "Defense", nshot=1, reasoning=True))
