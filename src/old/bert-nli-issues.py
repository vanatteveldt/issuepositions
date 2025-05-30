# %%
# Check remote connection
import socket

print(socket.gethostname())

# %%
# Load data
import csv
from lib import topics

topic_dicts = topics.get_topics_internationalized("nl")
tdict = {
    row["nl"]: row["en"] for row in csv.DictReader(open("data/raw/topics_dict.csv"))
}

gold = list(csv.DictReader(open("data/raw/annotations_stances_1_gold.csv")))
for g in gold:
    g["topic"] = tdict[g["gold_topic"].split(" : ")[0]]


# %%
# Load topics

# %%
for g in gold:
    topic = g["gold_topic"].split(" : ")[0]
    print(topic, topic in topic_dicts)


# %%
# Load model and pipeline
from transformers import pipeline

model_name = "MoritzLaurer/mDeBERTa-v3-base-xnli-multilingual-nli-2mil7"
classifier = pipeline("zero-shot-classification", model=model_name, device="cuda:0")


# %%
# Prepare hypotheses
hypothesis_template = "Deze tekst gaat over {}"


def describe_topic(t):
    descriptions = [t.get("description"), t.get("positive"), t.get("negative")]
    descriptions = [t.get("description")]
    return ". ".join(d for d in descriptions if d)


# classes = [f"{t['label']} (such as {describe_topic(t)})" for t in topic_dicts.values()]
classes = {label: t["description"] for (label, t) in topic_dicts.items()}
classes["None"] = "Geen onderwerp"
print(classes)


# %%
# run classifier
ncor = 0
for s in gold:
    text = ". ".join([s["before"], s["text"], s["after"]])
    result = classifier(
        text,
        list(classes.values()),
        hypothesis_template=hypothesis_template,
    )
    pred = result["labels"][0]
    actual = classes[s["topic"]]
    correct = pred == actual
    if correct:
        ncor += 1
    print(f"{correct} gold: {actual}, pred: {pred}, text: {text}")
print(ncor / len(gold))
