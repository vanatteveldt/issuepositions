import pandas as pd
from pathlib import Path


def load_data(data_file:Path, topic:str=None):
    "Second argument is a topic to filter the dataset on, if none is given, all topics are used"
    df = pd.read_csv(data_file)
    df = df.reset_index()
    df = pd.melt(df, id_vars=["jobid", "unit_id", "topic", "text"], value_vars=["NK", "NPR", "AM", "KN", "SH", "NR", "JE", "WA"], value_name="value")
    df = df.dropna()

    if topic:
         return df.loc[df['topic'] == topic]
    else:
         return df


def category_mapping(df:pd.DataFrame, colname:str="value"):
    "Maps caterigal values (stances) to numerical values to use by the model"
    category_mapping = {'L': 0, 'N': 1, 'R': 2}
    df[colname] = df[colname].map(category_mapping).astype(int)

    return df


def list_data(data_file:Path, topic:str=None):
    "Takes path to a csv file and returns a list of lists containing texts and coded values (labels)"
    df = load_data(data_file, topic)
    num_df = category_mapping(df)
    
    texts = num_df['text'].tolist()
    labels = num_df['value'].tolist()

    return [texts, labels]



    


