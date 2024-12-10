import pandas as pd
from dotenv import load_dotenv
from pathlib import Path
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.messages import AIMessage
from langchain_openai import ChatOpenAI
from pydantic import BaseModel, Field
from typing import TypedDict
from sklearn.metrics import precision_score, recall_score, f1_score, classification_report

from classification_prompts import coding_prompt_6shot, coding_prompt_0shot, civil_rights_examples, coding_prompt_6shot_extended
from load_data import load_data, get_text

load_dotenv()


class Classification(BaseModel):
    topic: str = Field(description="The most important topic in the text")
    label: str = Field(
        description="The stance taken by the highlighted actor on the described topic",
        enum=['L', 'N', 'R']
    )


class TopicData(TypedDict):
    topic_name: str
    topic: str
    description: dict
    labels: dict


def create_input(prompt:ChatPromptTemplate, data:dict, issue, examples=civil_rights_examples):

    input = prompt.format_messages(topic=data['topic'],
                               L_description=data['descriptions']['L'],
                               L_label=data['labels']['L'],
                               R_description=data['descriptions']['R'],
                               R_label=data['labels']['R'],
                               issue=issue,
                               examples=civil_rights_examples)
    
    return input


def create_llm(temperature, model_name, logprobs=False):

    if logprobs:
        llm = ChatOpenAI(temperature=temperature, model=model_name).bind(logprobs=True)

    else: 
        llm = ChatOpenAI(temperature=temperature, model=model_name).with_structured_output(
            Classification,
            include_raw=False
            )
    return llm
        

def generate_label(llm:ChatOpenAI, input, logprobs=False):
    output = llm.invoke(input)

    if logprobs:
        return output.response_metadata["logprobs"]["content"][:5], output.content

    else:
        return output.label


def generate_labels(prompt, data_file:Path, topic_data:TopicData, range=10):

    df = load_data(data_file, topic_data['topic_name'])

    llm = create_llm(0, "gpt-4-turbo", False)

    unit_ids = list(df['unit_id'])
    
    predictions_dict = {}

    for unit_id in unit_ids[:range]: #adjust for more predictions
        text = get_text(df, unit_id)
        input = create_input(prompt, topic_data, text)
        label = generate_label(llm, input, False)
        predictions_dict[unit_id] = label

    df['GPT'] = df['unit_id'].map(predictions_dict)

    return df


data_path = Path("data//intermediate//coded_units.csv")


topic_data:TopicData = {
    "topic_name": "CivilRights",
    "topic": "Burgerrechten",
    "descriptions": {
        "L": (
            "Vrijheid van meningsuiting, individuele rechten en vrijheden; "
            "privacy; gelijke rechten voor alle mensen, ethnische minderheden, "
            "seksualiteit inc homorechten, transgender, LHBTQI+ rechten; "
            "weerstand tegen discriminatie of anti-semitisme; zelfbeschikking in "
            "gezondheidszorg, waaronder abortus en euthanasie"
        ),
        "R": (
            "Traditionele / Christelijke / conservatieve normen en waarden; "
            "belang van gezin en gemeenschap; bescherming van het (ongeboren) "
            "leven en het gezin, weerstand tegen abortus / euthanasie, anti-woke"
        )
    },
    "labels": {
        "L": "Burgerrechten, vrijheid en minderheidsrechten",
        "R": "Traditionele waarden"
    },
}


df = generate_labels(coding_prompt_6shot_extended, data_path, topic_data, range=100)

print(df)

y_true = df['majority'][:100].astype(str)
y_pred = df['GPT'][:100].astype(str)

precision = precision_score(y_true, y_pred, average='macro')  # Macro-average for multi-class
recall = recall_score(y_true, y_pred, average='macro')
f1 = f1_score(y_true, y_pred, average='macro')

print(f"Precision: {precision:.2f}")
print(f"Recall: {recall:.2f}")
print(f"F1 Score: {f1:.2f}")

print("\nClassification Report:")
print(classification_report(y_true, y_pred))