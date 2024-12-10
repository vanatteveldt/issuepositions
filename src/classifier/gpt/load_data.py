import pandas as pd
from pathlib import Path


def load_data(data_file:Path, topic:str=None):
    "Loads data and filters for specific topic and agreement"

    df = pd.read_csv(data_file)
    df = df[df["text"].notna()]
    df = df.loc[df['topic'] == topic]

    return df


def get_text(df: pd.DataFrame, unit_id: str):
    "Filters the dataframe for the given unit_id and return text corresponding to that id"
    filtered_df = df.loc[df['unit_id'] == unit_id]

    # Check if a matching row exists
    if filtered_df.empty:
        return None
    
    return filtered_df['text'].iloc[0]


def generate_answers(data_file:Path, topic, range=None):

    df = load_data(data_file, topic)
    
    unit_ids = list(df['unit_id'])
    
    predictions_dict = {}

    for unit_id in unit_ids[:range]: #adjust for more predictions
        text = get_text(df, unit_id)
        answer = 'blabla' #tofix
        predictions_dict[unit_id] = answer

    df['GPT'] = df['unit_id'].map(predictions_dict)

    return df


data_path = Path("data//intermediate//coded_units.csv")

topic = "Environment"

