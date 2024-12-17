import pandas as pd
from pathlib import Path


def load_data(data_file:Path, topic:str=None):
    "Second argument is a topic to filter the dataset on, if none is given, all topics are used"
    df = pd.read_csv(data_file)
    df = df.reset_index()
    #df = pd.melt(df, id_vars=["jobid", "unit_id", "topic", "text"], value_vars=["NK", "NPR", "AM", "KN", "SH", "NR", "JE", "WA"], value_name="value")
    df = df.dropna()

    if topic:
         return df.loc[df['topic'] == topic]
    else:
         return df


def category_mapping(df:pd.DataFrame, colname:str="stance"):
    "Maps caterigal values (stances) to numerical values to use by the model"
    category_mapping = {'L': 0, 'N': 1, 'R': 2}
    df[colname] = df[colname].map(category_mapping).astype(int)

    return df


def get_text_data():
    "Retrieve dataframe with unit_ids and text data"
    units = pd.read_csv("data/intermediate/units_tk2023.csv", usecols=["unit_id", "before", "text_hl", "after"], dtype=str)
    units['text'] = units['before'].fillna('') + units['text_hl'] + units['after'].fillna('')

    return units[['unit_id', 'text']]


def list_data(data_file:Path, topic:str=None):
    "Takes path to a csv file and returns a list of lists containing texts and coded values (labels)"
    df = load_data(data_file, topic)
    num_df = category_mapping(df)
    text_df = get_text_data()
    
    num_df = num_df.merge(text_df, how='left', on='unit_id')    

    texts = num_df['text'].tolist()
    labels = num_df['value'].tolist()

    return [texts, labels]

