# %%
# Setup and data prep
import pandas as pd
import numpy as np
from pathlib import Path
from transformers import (AutoModelForSequenceClassification, TrainingArguments, DataCollatorWithPadding,
                          AutoTokenizer, AutoModel, TrainingArguments, Trainer)

from sklearn.model_selection import StratifiedKFold
import torch, gc
import datasets
from pyhere import here

MODEL = "MoritzLaurer/mDeBERTa-v3-base-xnli-multilingual-nli-2mil7"
DEVICE = "cuda:0"

label2id  = {"Ja": 1, "Nee": 0}

annotations = pd.read_csv(here() / "data" / "intermediate" / "annoations_01_dutch_types.csv")
annotations = annotations.rename(columns={"issue position": "label_text"})[["unit_id", "label_text"]]
annotations['label'] = annotations.label_text.map(label2id)

units = pd.read_csv(here() / "data" / "intermediate" / "units_tk2023.csv")
units = units.fillna("")
units.text = units.before + '\nDeze zin: "' + units.text + '"\n' + units.after
units = units[["unit_id", "actor", "text"]]

df = annotations.merge(units, on="unit_id")
df.head()

# %%
# Utility functions

def format_nli_trainset(data=None, hypo_label_dic=None, random_seed=42, party_column=None):
    "Create hypotheses pairs and set entailment label"
    data = data.copy(deep=True)
    dfs = []
    for label_text, hypothesis in hypo_label_dic.items():
        ## entailment
        d_entail = data[data.label_text == label_text].copy(deep=True)
        if party_column:
            d_entail["hypothesis"] = [hypothesis.format(party=p) for p in d_entail[party_column]]
        else:
            d_entail["hypothesis"] = [hypothesis] * len(d_entail)
        d_entail["label"] = [0] * len(d_entail)

        ## not_entailment
        d_notentail = data[data.label_text != label_text].copy(deep=True)
        d_notentail = d_notentail.sample(n=min(len(d_entail), len(d_notentail)), random_state=random_seed)
        if party_column:
            d_notentail["hypothesis"] = [hypothesis.format(party=p) for p in d_notentail[party_column]]
        else:
            d_notentail["hypothesis"] = [hypothesis] * len(d_notentail)
        d_notentail["label"] = [2] * len(d_notentail)
        dfs += [d_entail, d_notentail]

    return pd.concat(dfs).sample(frac=1, random_state=random_seed)

def get_nli_tokenizer(tokenizer):
    def tokenize_nli_format(examples):
        return tokenizer(examples["text"], examples["hypothesis"], truncation=True, max_length=512)  # max_length can be reduced to e.g. 256 to increase speed, but long texts will be cut off
    return tokenize_nli_format

def get_train_args(training_directory=here("data") / "tmp" / "nli_model", epochs=5, evaluation_strategy="no", seed=42):
    """Get sensible default train args"""
    return TrainingArguments(
        output_dir=f'./results/{training_directory}',
        logging_dir=f'./logs/{training_directory}',
        learning_rate=2e-5,
        per_device_train_batch_size=16,  # if you get an out-of-memory error, reduce this value to 8 or 4 and restart the runtime. Higher values increase training speed, but also increase memory requirements. Ideal values here are always a multiple of 8.
        per_device_eval_batch_size=80,  # if you get an out-of-memory error, reduce this value, e.g. to 40 and restart the runtime
        #gradient_accumulation_steps=4, # Can be used in case of memory problems to reduce effective batch size. accumulates gradients over X steps, only then backward/update. decreases memory usage, but also slightly speed. (!adapt/halve batch size accordingly)
        num_train_epochs=epochs,  # this can be increased, but higher values increase training time. Good values for NLI are between 3 and 20.
        warmup_ratio=0.25,  # a good normal default value is 0.06 for normal BERT-base models, but since we want to reuse prior NLI knowledge and avoid catastrophic forgetting, we set the value higher
        weight_decay=0.1,
        seed=seed,
        load_best_model_at_end=True,
        metric_for_best_model="f1_macro",
        #fp16=fp16_bool,  # Can speed up training and reduce memory consumption, but only makes sense at batch-size > 8. loads two copies of model weights, which creates overhead. https://huggingface.co/transformers/performance.html?#fp16
        #fp16_full_eval=fp16_bool,
        evaluation_strategy=evaluation_strategy, # options: "no"/"steps"/"epoch"
        #eval_steps=10_000,  # evaluate after n steps if evaluation_strategy!='steps'. defaults to logging_steps
        save_strategy = evaluation_strategy,  # options: "no"/"steps"/"epoch"
        #save_steps=10_000,              # Number of updates steps before two checkpoint saves.
        #save_total_limit=10,             # If a value is passed, will limit the total amount of checkpoints. Deletes the older checkpoints in output_dir
        #logging_strategy="steps",
        report_to="all",  # "all"  # logging
        #push_to_hub=False,
        #push_to_hub_model_id=f"{model_name}-finetuned-{task}",
    )

def predict(model, tokenizer, premise, hypotheses, entail_index=0, device="cuda:0", labels=None):
    if labels is None:
        labels = hypotheses
    entail_logits = []
    for hypo in hypotheses:
        input = tokenizer.encode(premise, hypo, return_tensors='pt', truncation=True, max_length=512)
        logits = model(input.to(device))[0]
        entail_logits.append(float(logits[:, entail_index]))
    scores = np.exp(entail_logits) / np.exp(entail_logits).sum(-1, keepdims=True)
    order = sorted(range(len(hypotheses)), key=lambda i: scores[i], reverse=True)
    return {'sequence': premise, 'scores': [scores[i] for i in order], 'labels': [labels[i] for i in order]}

def predict_data(model, tokenizer, data, hypothesis_label_dic, text_col="text", party_col=None):
    result = data.copy()
    results = []
    scores = []
    labels = list(hypothesis_label_dic.keys())
    for _index, row in data.iterrows():
        hypotheses = [hypothesis_label_dic[label] for label in labels]
        if party_col:
            hypotheses = [hypo.format(party=row[party_col]) for hypo in hypotheses]
        pred = predict(model, tokenizer, row[text_col], hypotheses, labels=labels)
        results.append(pred['labels'][0])
        scores.append(pred['scores'][0])
    result['prediction'] = results
    result['score'] = scores
    return result

# %%
# Run NLI model

folds = StratifiedKFold(n_splits=5)
splits = list(folds.split(np.zeros(df.shape[0]), df["label"]))

hypothesis_label_dic = {
   "Ja": "Deze zin laat een issuepositie zien van {party}, bijvoorbeeld dat zij voor of tegen immigratie, zorg, bestaanszekerheid zijn",
   "Nee": "Deze zin laat geen issuepositie zien van {party}, maar gaat bijvoorbeeld over succes in peilingen of over conflict"
}

# %%
predictions = list()
for i, (train_ics, test_ics) in enumerate(splits):
    print("**************** FOLD", i+1)

    data_formatted = format_nli_trainset(df.iloc[train_ics], hypo_label_dic=hypothesis_label_dic, party_column='actor')
    model = AutoModelForSequenceClassification.from_pretrained(MODEL).to(DEVICE)
    tokenizer = AutoTokenizer.from_pretrained(MODEL, use_fast=True, model_max_length=512)

    nli_tokenizer = get_nli_tokenizer(tokenizer)
    data_train = datasets.DatasetDict({
        "train": datasets.Dataset.from_pandas(data_formatted),
    }).map(nli_tokenizer)
    df_test = df.iloc[test_ics]
    trainer = Trainer(
            model=model,
            tokenizer=tokenizer,
            args=get_train_args(epochs=5),
            train_dataset=data_train["train"],
        )
    _output = trainer.train()
    model = model.eval()
    pred = predict_data(model, tokenizer, df_test, hypothesis_label_dic, party_col='actor')
    predictions.append(pred)
    # Memory management
    del model
    gc.collect()
    torch.cuda.empty_cache()


# %%
from sklearn.metrics import classification_report
#
preds = pd.concat(predictions)
preds.head()
print(classification_report(preds["label_text"], preds["prediction"]))
#print(classification_report(preds.label, preds.prediction))
