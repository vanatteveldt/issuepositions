import os
import torch
from torch import nn
from torch.utils.data import DataLoader, Dataset
from transformers import BertTokenizer, BertModel, AdamW, get_linear_schedule_with_warmup
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
import pandas as pd


def load_data(data_file:str):
    df = pd.read_csv(data_file)
    df = df.reset_index()
    df = pd.melt(df, id_vars=["jobid", "unit_id", "topic", "text"], value_vars=["NK", "NPR", "AM", "KN", "SH", "NR", "JE", "WA"], value_name="value")
    df = df.dropna()

    return df.loc[df['topic'] == "Environment"]


def category_mapping(df:pd.DataFrame, colname:str="value"):
    #  Define the mapping for categorical values
    category_mapping = {'L': 0, 'N': 1, 'R': 2}
    df[colname] = df[colname].map(category_mapping).astype(int)
    return df


def list_data(data_file:str):
    "Takes path to a csv file and returns a list of lists containing texts and coded values (labels)"
    df = load_data(data_file=data_file)
    num_df = category_mapping(df)
    
    texts = num_df['text'].tolist()
    labels = num_df['value'].tolist()

    return [texts, labels]


class TextClassificationDataset(Dataset):
    def __init__(self, texts, labels, tokenizer, max_length):
            self.texts = texts
            self.labels = labels
            self.tokenizer = tokenizer
            self.max_length = max_length

    def __len__(self):
        return len(self.texts)
    
    def __getitem__(self, idx):
        text = self.texts[idx]
        label = self.labels[idx]
        encoding = self.tokenizer(text, return_tensors='pt', max_length=self.max_length, padding='max_length', truncation=True)
        return {'input_ids': encoding['input_ids'].flatten(), 'attention_mask': encoding['attention_mask'].flatten(), 'label': torch.tensor(label)}
    


data_file = "data\intermediate\coded_units.csv"

texts, labels = list_data(data_file)

