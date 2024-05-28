# %%
# inlezen stuff
from pyhere import here
import pandas as pd
import numpy as np
from datasets import Dataset
from transformers import (AutoModelForSequenceClassification, AutoTokenizer, 
                          Trainer, TrainingArguments)

tokenizer = AutoTokenizer.from_pretrained('xlm-roberta-large')


# %%
# inlezen data
data = pd.read_csv(here() / "data" / "intermediate" / "sents_npo.csv")
data = data.fillna("")

data.text = data.before + "\n" + data.text + "\n" + data.after
data = data[["sent_id", "text"]]
data.head()

#%%
label2cap  = {"Macroeconomics": 1, "Civil Rights": 2,"Health":3,"Argiculture":4,"Labor":5,"Education":6,"Environment":7, "Energy":8,"Immigration":9, "Transportation":10,
             "Law and Crime":12,"Social Welfare":13,"Housing":14,"Domestic commerce":15,"Defense":16,"Technology":17,"Foreign Trade":18, "International Affairs":19,
             "Governmental Operations":20, "Public Lands":21, "Culture":23, "Other": 999}
id2cap = {0: '1', 1: '2', 2: '3', 3: '4', 4: '5', 5: '6',  6: '7', 7: '8', 8: '9', 9: '10', 10: '12', 11: '13', 12: '14', 13: '15', 14: '16', 15: '17', 16: '18', 17: '19', 18: '20', 19:  '21', 20: '23', 21: '999'}

cap2id = {int(cap): id for (id, cap) in id2cap.items()}
label2id = {label: cap2id[cap] for (label, cap) in label2cap.items()}

id2label = {str(v): k for (k,v) in label2id.items()}
num_labels = len(id2cap)
label2id

# %%
# tokenize text

def tokenize_dataset(data : pd.DataFrame):
    tokenized = tokenizer(data["text"],
                          max_length=512,
                          truncation=True,
                          padding="max_length")
    return tokenized


hg_data = Dataset.from_pandas(data)
print(hg_data)
dataset = hg_data.map(tokenize_dataset, batched=True, remove_columns=hg_data.column_names)


# %%
model = AutoModelForSequenceClassification.from_pretrained('poltextlab/xlm-roberta-large-dutch-social-cap-v3',
                                                           num_labels=num_labels,
                                                           problem_type="multi_label_classification",
                                                           ignore_mismatched_sizes=True
                                                           )

training_args = TrainingArguments(
    output_dir='.',
    per_device_train_batch_size=8,
    per_device_eval_batch_size=8
)

trainer = Trainer(
    model=model,
    args=training_args
)

probs = trainer.predict(test_dataset=dataset).predictions
predicted = pd.DataFrame(np.argmax(probs, axis=1)).replace({0: id2cap}).rename(
    columns={0: 'predicted'}).reset_index(drop=True)
predicted.head()

# %%
predicted.head()
data.head()
data['id'] = np.arange(len(data))
predicted['id'] = np.arange(len(predicted))
df = data.merge(predicted, on="id")
df['predicted_lbl'] = df.predicted.map(id2label)
df.to_csv('data/cap_test.csv')
df.head()


# %%
d = pd.DataFrame(dict(x=[1,2,3]))
d['y'] = d.x.map(id2label)
list(df.predicted)
