# Cross-validation to evaluate BERT model on yes/no statement is an issue position

# %%
# Setup and data prep
from pyhere import here
import pandas as pd
import numpy as np
from pathlib import Path
from transformers import (AutoModelForSequenceClassification, TrainingArguments, DataCollatorWithPadding,
                          AutoTokenizer, TrainingArguments, Trainer)

from sklearn.model_selection import StratifiedKFold
import torch, gc

import datasets

checkpoint = "FremyCompany/roberta-large-nl-oscar23"

label2id  = {"Ja": 1, "Nee": 0}

annotations = pd.read_csv(here() / "data" / "intermediate" / "annoations_01_dutch_types.csv")
annotations = annotations.rename(columns={"issue position": "label"})[["unit_id", "label"]]
annotations.label = annotations.label.map(label2id)

units = pd.read_csv(here() / "data" / "intermediate" / "units_tk2023.csv")
units = units.fillna("")
units.text = units.before + "\n" + units.text + "\n" + units.after
units = units[["unit_id", "text"]]

df = annotations.merge(units, on="unit_id")
df.head()

# %%
# Utility functions

def get_datasets(data, train_ics, test_ics, checkpoint):
    df_train = data.iloc[train_ics]
    df_test =  data.iloc[test_ics]

    dataset = datasets.DatasetDict({
        "train": datasets.Dataset.from_pandas(df_train),
        "test": datasets.Dataset.from_pandas(df_test)
    })

    tokenizer = AutoTokenizer.from_pretrained(checkpoint)
    def preprocess_function(examples):
        return tokenizer(examples["text"], truncation=True, padding=True)

    dataset = dataset.map(preprocess_function, batched=True)
    data_collator = DataCollatorWithPadding(tokenizer=tokenizer)
    return dataset, data_collator, tokenizer

def predict_test(trainer, data):
    predictions = trainer.predict(data)
    preds = np.argmax(predictions.predictions, axis=-1)
    return pd.DataFrame(dict(true=data['label'], pred=list(preds)))



def get_model(label2id, checkpoint):
    id2label = {v:k for (k,v) in label2id.items()}
    model = AutoModelForSequenceClassification.from_pretrained(
       checkpoint, num_labels=2, id2label=id2label, label2id=label2id
    )
    return model

def compute_metrics(eval_pred):
    metric = datasets.load_metric('f1')
    logits, labels = eval_pred
    predictions = np.argmax(logits, axis=-1)
    return metric.compute(predictions=predictions, references=labels, average="macro")

def get_training_args():
    return TrainingArguments(
        output_dir=str(data / "tmp/dutch_bert"),
        learning_rate=2e-5,
        per_device_train_batch_size=16,
        per_device_eval_batch_size=48,
        num_train_epochs=5,
        weight_decay=0.01,
        fp16=True,
        fp16_full_eval=True, Run k-fold crossvalidation, store predictions
        evaluation_strategy="epoch",
        save_strategy="epoch",
        load_best_model_at_end=True,
        push_to_hub=False,
    )

# %%
# Run k-fold crossvalidation, store predictions

splits = list(StratifiedKFold(n_splits=5).split(np.zeros(df.shape[0]), df.label))

predictions=[]
for i, (train_ics, test_ics) in enumerate(splits):
    print("**************** FOLD", i+1)
    model=get_model(label2id, checkpoint)
    dataset, collator, tokenizer = get_datasets(df, train_ics, test_ics, checkpoint)
    trainer = Trainer(
            model,
            get_training_args(),
            train_dataset=dataset["train"],
            eval_dataset=dataset["test"],
            data_collator=collator,
            tokenizer=tokenizer,
            compute_metrics=compute_metrics,
    )
    trainer.train()
    pred = predict_test(trainer, dataset['test'])
    predictions.append(pred)
    del model
    gc.collect()
    torch.cuda.empty_cache()

# %%
# Run classification report
from sklearn.metrics import classification_report
preds = pd.concat(predictions)
print(classification_report(preds.true, preds.pred))
