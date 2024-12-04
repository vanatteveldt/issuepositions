from dotenv import load_dotenv
from pathlib import Path

from langchain_core.prompts import ChatPromptTemplate
from langchain_core.messages import AIMessage
from langchain_openai import ChatOpenAI
from pydantic import BaseModel, Field

load_dotenv()

coding_prompt = ChatPromptTemplate.from_template(
    """
## Uitleg: standpunt coderen over {topic}

Hier volgt telkens een drietal zinnen met een gemarkeerde actor. De centrale vraag is wat het standpunt is van de actor over {topic}. De drie zinnen zijn aangegeven met triple back ticks (```)
Je kiest hiervoor uit de twee dimensies die hieronder uitgelegd worden.

Is de actor voor meer {positive_description}, of juist voor meer {negative_description}? Als de actor juist tegen {positive_description} is, kies dan {negative_description} en andersom.

Je mag deze ruim interpreteren, het gaat om de algemene politieke richting, niet om de exacte bewoording van de dimensie. Als het standpunt echt niet bij de dimensies past, of niet duidelijk is, of over een ander ondewerp gaat, kies dan 'Geen/Ander/Neutraal'.

## Uitleg: Wat is het standpunt over {topic}?

Positive Label: {positive_label}
Bescrhijving: {positive_description}


Negative Label: {negative_label}
Beschrijving: {negative_description}

Neutral Label: Geen/Ander/Neutraal
Beschrijving: Als de actor geen standpunt heeft over {topic}, of als het standpunt niet duidelijk is of niet in deze dimensies past, kies dan Geen

## Opdracht: Standpunt om te coderen
```{issue}```

Label:"""
)


class Classification(BaseModel):
    topic: str = Field(description="The most important topic in the text")
    label: str = Field(
        description="The stance taken by the highlighted actor on the described topic",
        enum=['Positive', 'Neutral', 'Negative']
    )


def create_input(prompt:ChatPromptTemplate, data:dict):

    input = prompt.format_messages(topic=data['topic'],
                               positive_description=data['descriptions']['positive'],
                               positive_label=data['labels']['positive'],
                               negative_description=data['descriptions']['negative'],
                               negative_label=data['labels']['negative'],
                               issue=data['issue'])
    
    return input


def create_llm(temperature, model_name, logprobs=False):

    if logprobs:
        llm = ChatOpenAI(temperature=temperature, model=model_name).bind(logprobs=True)
        return llm
    else: 
        llm = ChatOpenAI(temperature=temperature, model=model_name, logprobs=True).with_structured_output(
            Classification,
            include_raw=True
            )
        return llm
        

def generate_label(llm:ChatOpenAI, input, logprobs=False):
    output = llm.invoke(input)

    if logprobs:
        return output.response_metadata["logprobs"]["content"][:5], output.content

    else:
        return output['parsed']


def generate_labels(prompt, data:dict, logprobs:bool):

    llm = create_llm(0, "gpt-4o-2024-08-06", logprobs)
    input = create_input(prompt, data)
    label = generate_label(llm, input, logprobs)

    return label


data = {
    "topic": "Burgerrechten",
    "descriptions": {
        "positive": (
            "Vrijheid van meningsuiting, individuele rechten en vrijheden; "
            "privacy; gelijke rechten voor alle mensen, ethnische minderheden, "
            "seksualiteit inc homorechten, transgender, LHBTQI+ rechten; "
            "weerstand tegen discriminatie of anti-semitisme; zelfbeschikking in "
            "gezondheidszorg, waaronder abortus en euthanasie"
        ),
        "negative": (
            "Traditionele / Christelijke / conservatieve normen en waarden; "
            "belang van gezin en gemeenschap; bescherming van het (ongeboren) "
            "leven en het gezin, weerstand tegen abortus / euthanasie, anti-woke"
        )
    },
    "labels": {
        "positive": "Burgerrechten, vrijheid en minderheidsrechten",
        "negative": "Traditionele waarden"
    },
    "issue": (
        "Opmerkelijk is dat hun achterban daar vaak heel anders over denkt, zoals blijkt uit de "
        "resultaten van Kieskompas. Zo wil bijna 80 procent van de kiezers die bij de komende "
        "verkiezingen overwegen **NSC**, SP of Ja21 te stemmen dat mensen die hun leven 'voltooid' "
        "achten hulp kunnen krijgen om te sterven. Datzelfde geldt voor een ruime meerderheid van "
        "de PVV- en BBB-stemmers."
    )
}

label = generate_labels(coding_prompt, data, False)

print(label)

logprobs = generate_labels(coding_prompt, data, True)

print(logprobs)