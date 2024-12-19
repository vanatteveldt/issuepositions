import pandas as pd
from dotenv import load_dotenv
from pathlib import Path
from langchain.globals import set_llm_cache
from langchain_community.cache import SQLiteCache
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI
from pydantic import BaseModel, Field
from typing import TypedDict
from sklearn.metrics import precision_score, recall_score, f1_score, classification_report

from classification_prompts import coding_prompt_nshot, coding_prompt_0shot, coding_prompt_6shot_extended
from load_data import load_data, get_text, load_topic_data, load_examples

load_dotenv()

# set a cache in case api connection fails, to remove cache: !rm .langchain.db
set_llm_cache(SQLiteCache(database_path=".langchain.db"))


class Classification(BaseModel):
    # topic: str = Field(description="The most important topic in the text")
    label: str = Field(
        description="The stance taken by the highlighted actor on the described topic",
        enum=['L', 'N', 'R']
    )


class TopicData(TypedDict):
    topic_name: str
    topic: str
    descriptions: dict
    labels: dict


def create_input(prompt:ChatPromptTemplate, data:dict, issue, examples=None):
    """Formats a prompt with data related to the topic and the issue to code"""
    input = prompt.format_messages(topic=data['topic'],
                               L_description=data['descriptions']['L'],
                               L_label=data['labels']['L'],
                               R_description=data['descriptions']['R'],
                               R_label=data['labels']['R'],
                               issue=issue,
                               examples=examples)
    
    return input


def create_llm(temperature, model_name, logprobs=False):
    """Initialize an OpenAI llm, turn logprobs to TRUE to get probabilities"""
    if logprobs:
        llm = ChatOpenAI(temperature=temperature, model=model_name).bind(logprobs=True)

    else: 
        llm = ChatOpenAI(temperature=temperature, model=model_name).with_structured_output(
            Classification,
            include_raw=False
            )
    return llm
        

def generate_label(llm:ChatOpenAI, input, logprobs=False):
    """Generate a single label for an issue, input is a formatted prompt"""
    output = llm.invoke(input)

    if logprobs:
        return output.response_metadata["logprobs"]["content"][:5], output.content

    else:
        return output.label


def generate_labels_topic(prompt, df:pd.DataFrame, topic_data:TopicData, n_shot:int, limit=5):
    """
    Generate labels for a specified topic in a dataset
    Set limit to None to generate a label for every issue
    """
    llm = create_llm(0, "gpt-4-turbo", False)

    # Filter rows for the given topic
    topic_name = topic_data.get('topic_name')
    if not topic_name:
        raise ValueError("topic_data must include a 'topic_name' key.")

    df_filtered = df.loc[df['topic'] == topic_name]

    examples, example_ids = load_examples(df_filtered, n_shot)

    # Exctract unit_ids and remove example ids
    unit_ids = list(df_filtered['unit_id'])
    unit_ids = [unit_id for unit_id in unit_ids if unit_id not in example_ids]

    if limit:
        unit_ids = unit_ids[:limit]    
    
    predictions_dict = {}

    for unit_id in unit_ids:
        text = get_text(df_filtered, unit_id)
        input = create_input(prompt, topic_data, text, examples)
        label = generate_label(llm, input, False)
        predictions_dict[(unit_id, topic_name)] = label

    # Update the DataFrame with predictions (keeping track of both unit_id and topic_name)
    for (unit_id, topic_name), label in predictions_dict.items():
        df.loc[(df['unit_id'] == unit_id) & (df['topic'] == topic_name), f'GPT-{n_shot}shot'] = label

    return df


def generate_labels(prompt, dataframe:pd.DataFrame, topics_to_code:list, n_shot:int, limit:int):
    """Combined function to generate labels for issues in a list of topics"""
    topic_data = load_topic_data()

    for dict in topic_data:
        if dict['topic_name'] in topics_to_code:
            df = generate_labels_topic(prompt, dataframe, dict, n_shot, limit)

    return df


def evaluate_labels(df:pd.DataFrame, n_shot):
    """Evaluate the generated labels based on precision, recall and f1 scores"""
    df = df[df[f"GPT-{n_shot}shot"].notna()]
    y_true = df['majority'].astype(str)
    y_pred = df[f"GPT-{n_shot}shot"].astype(str)

    precision = precision_score(y_true, y_pred, average='macro')  # Macro-average for multi-class
    recall = recall_score(y_true, y_pred, average='macro')
    f1 = f1_score(y_true, y_pred, average='macro')

    print(f"Evaluation for GPT-{n_shot}shot classfier\n")
    print(f"Precision: {precision:.2f}")
    print(f"Recall: {recall:.2f}")
    print(f"F1 Score: {f1:.2f}")

    print("\nClassification Report:")
    print(classification_report(y_true, y_pred))


if __name__ == "__main__":
        
    data_path = Path("data//intermediate//coded_units.csv")
    save_path = Path("data//intermediate//coded_units_gpt_nshot.csv")
    topics_to_code = ["Environment", "CivilRights", "Immigration"]
    n_shots = [1, 5, 16, 35]
    df = load_data(data_path)

    for n_shot in n_shots:
        print(f"Generating labels using {n_shot}-shot prompt...")
        df = generate_labels(coding_prompt_nshot, df, topics_to_code, n_shot, limit=60)
        evaluate_labels(df, n_shot)

    df.to_csv(save_path)
    print(f"GPT labeled data saved to {save_path}")

    #error handeling
    saved_df = pd.read_csv(save_path)
    print(saved_df.info())
    print(saved_df.head())
