# %%

import logging

import pandas as pd
from sklearn.metrics import accuracy_score, precision_recall_fscore_support

from classification.data import StancesRow, get_stances
from classification.prompts import GPT, Model


def do_classification(model: Model, row: StancesRow, **kargs):
    text = " ".join([row.before, row.text, row.after])
    output = row._asdict()
    try:
        result = model.classify(text, row.actor, row.topic, **kargs)
        output["prediction"] = result.standpunt.value
        output["uitleg"] = getattr(result, "uitleg", None)
    except Exception as e:
        logging.exception(f"Exception classifying {row}")
        output["prediction"] = None
        output["uitleg"] = f"Exception {type(e)}: {e}"

    return output


def compute_metrics(group):
    gold = group["stance"]
    predicted = group["prediction"]
    precision, recall, f1, _ = precision_recall_fscore_support(gold, predicted, average="macro")
    accuracy = accuracy_score(gold, predicted)
    return pd.Series({"precision": precision, "recall": recall, "f1": f1, "accuracy": accuracy})


# %%
if __name__ == "__main__":

    SEED = 42
    N = 300
    NSHOT = 0
    REASON = True
    MODEL = "o3"
    logging.basicConfig(level=logging.INFO, format="[%(asctime)s %(levelname)s] %(message)s")
    logging.getLogger("openai").setLevel(logging.WARNING)
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.info(f"Loading data")
    d = get_stances()
    model = GPT(model=MODEL)
    result = []
    for topic in sorted(d["topic"].unique()):
        topic_rows = d[d["topic"] == topic]
        n = min(N, len(topic_rows))
        logging.info(f"Sampling and classifying {n}/{len(topic_rows)} examples from topic {topic} (seed: {SEED})")

        subset = topic_rows.sample(n=n, random_state=SEED)
        model.examples_df = topic_rows.drop(subset.index)
        for row in subset.itertuples():
            result.append(do_classification(model, row, nshot=NSHOT, reasoning=REASON))

    result = pd.DataFrame(result)
    result.to_csv(f"data/intermediate/classification/gpt_{MODEL}_{NSHOT}shot_{'reason' if REASON else 'noreason'}.csv")
    report = result.groupby("topic").apply(compute_metrics, include_groups=False).reset_index()
    print(report)

# %%
