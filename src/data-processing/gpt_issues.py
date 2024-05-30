import re
import csv
import os
import sys
import openai
import dotenv

from lib import topics


prompt_pre = """
You will be provided with a Dutch language sentence as well as some context before and after the sentence. 
In that sentence, a specific actor is expressing an issue position.
Your task is to identify the issue that that actor is taking a position on.
You can choose from the answers listed below:
"""
prompt_post = """Please answer with a single word, e.g. Environment or Housing. 
If the actor does not take a position on any of these issues, answer None. 
"""


def describe_topic(t):
    descriptions = [t.get("description"), t.get("positive"), t.get("negative")]
    return ". ".join(d for d in descriptions if d)


prompt_topic = "\n".join(
    f"Code: {key}. Description: {describe_topic(val)}"
    for (key, val) in topics.get_topics_internationalized("en").items()
)
prompt = f"{prompt_pre}\n\n{prompt_topic}\n\n{prompt_post}"

dotenv.load_dotenv()
client = openai.OpenAI(
    api_key=os.environ.get("OPENAI_API_KEY"),
)


w = csv.writer(sys.stdout)
w.writerow(["unit_id", "gold", "gpt_response", "gpt_rank", "gpt_token", "gpt_logprob"])
gold_sentences = csv.DictReader(open("data/raw/annotations_stances_1_gold.csv"))
for i, row in enumerate(gold_sentences):
    sent = row["text"]
    if not (m := re.search(r"\*\*(.*?)\*\*", sent)):
        raise ValueError(f"Cannot parse {sent!r}")
    actor = m.group(1)
    sent_clean = re.sub(r"\*\*", "", sent)
    text = f'Sentence: "{sent_clean}". Context: "{row["before"]}. {row["after"]}". Actor: {actor}'
    messages = [
        {"role": "system", "content": prompt},
        {"role": "user", "content": text},
    ]
    response = client.chat.completions.create(
        model="gpt-4o",
        messages=messages,  # type: ignore
        logprobs=True,
        top_logprobs=10,
        temperature=0.7,
    )
    choice = response.choices[0]
    # 'logprob' object of first token in response
    logprobs = choice.logprobs.content[0].top_logprobs  # type: ignore
    print(
        f"[{i}] {sent_clean} -> {choice.message.content} {[x.token for x in logprobs]}",
        file=sys.stderr,
    )
    for j, toplogprob in enumerate(logprobs):
        w.writerow(
            [
                row["unit_id"],
                row["gold_topic"],
                choice.message.content,
                j,
                toplogprob.token,
                toplogprob.logprob,
            ]
        )
