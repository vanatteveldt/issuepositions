"""
Use GPT to determine the target issue in the identified units

Input:  data/intermediate/units_tk2023.csv, data/intermediate/gold_325.csv
Output: data/intermediate/gpt_issues_all.csv, data/intermediate/gpt_issues_gold_325.csv
"""

import hashlib
import logging
import random
import re
import csv
import os
import sys
import openai
import dotenv

from lib.topics import describe_topic, get_topics_internationalized
from lib.gpt_topics import prompt_post, prompt_pre

# To refresh / redownload gold codings, use:
# wget -O data/intermediate/gold_325.csv "https://docs.google.com/spreadsheets/d/e/2PACX-1vTjlgsCqJy2vNbXlzwMc7ygvRnKo6dQd3pgcAVCfKncecocWtAbwiyIzTAbnLVmN_M-QhFxFLDbw5Xz/pub?gid=871520840&single=true&output=csv"


def read_units(fn):
    """Get the gold sentences, create single text, and add gold key"""
    # Translate Dutch labels to topic keys
    topics_nl = get_topics_internationalized("nl")
    keys = {topics_nl[key]["label"]: key for key in topics_nl}
    keys["O.wijs, Cult. & Wetensch."] = "Education"
    keys["Ander"] = "None"
    keys["Defensie"] = "Defense"

    for row in csv.DictReader(open(fn)):
        sent = row["text_hl"]
        if not sent:
            continue
        if not (m := re.search(r"\*\*(.*?)\*\*", sent)):
            logging.warning(f"Cannot parse {sent!r}")
            continue
        actor = m.group(1)
        sent_clean = re.sub(r"\*\*", "", sent)
        text = ". ".join(
            t for t in [row["before"], sent_clean, row["after"]] if t
        ).replace("..", ".")
        gold = keys[row["decision"].split("/")[0]] if "decision" in row else None
        yield dict(id=row["unit_id"], text=text, actor=actor, gold=gold)


def read_units_done(fn):
    return {row["unit_id"] for row in csv.DictReader(open(fn))}


def get_prefixes(lang):
    # Determine prefix of every (localized) code to the issue key
    # Note: we renamed 'beter bestuur' to bestuur, so replace Bet by Bes
    topics = get_topics_internationalized(lang)
    return {
        topics[key]["label"].split()[0][:3].replace("Bet", "Bes"): key for key in topics
    }


def create_prompt(lang):
    topics = get_topics_internationalized(lang)
    prompt_topic = "\n".join(describe_topic(key, lang) for key in topics)
    prompt = f"{prompt_pre[lang]}\n\n{prompt_topic}\n\n{prompt_post[lang]}"
    return prompt


def process_gpt(units, lang, writer):
    writer.writerow(["unit_id", "gold", "response", "topic", "rank", "logprob"])
    dotenv.load_dotenv()
    # client = openai.OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))
    client = openai.OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
    prompt = create_prompt(lang)
    keys = get_prefixes(lang)

    for i, row in enumerate(units):
        unit = f'Text: "{row["text"]}". Over welk onderwerp heeft {row["actor"]} een standpunt?'
        messages = [
            {"role": "system", "content": prompt},
            {"role": "user", "content": unit},
        ]
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=messages,  # type: ignore
            logprobs=True,
            top_logprobs=10,
            temperature=0.7,
        )
        # first choice and 'logprob' object of first token in response
        choice = response.choices[0]
        logprobs = choice.logprobs.content[0].top_logprobs  # type: ignore
        print(
            f"[{i}] {row['text'][:20]} -> {choice.message.content} {[x.token for x in logprobs]}",
            file=sys.stderr,
        )
        # Write main response
        response = (
            choice.message.content.replace("Onderwerp:", "")
            .replace("Issue:", "")
            .strip()
        )
        key = keys.get(response[:3])
        writer.writerow([row["id"], row["gold"], response, key, 0, 0])
        # Write other responses
        seen = {keys.get(response[:3])}
        for j, toplogprob in enumerate(logprobs):
            response = toplogprob.token
            if response == "Onder":
                # Prevent false positive match of 'onderwerp' to 'onderwijs'
                continue
            key = keys.get(response[:3])
            if key and (key not in seen):
                writer.writerow(
                    [
                        row["id"],
                        row["gold"],
                        response,
                        keys.get(response[:3]),
                        j + 1,
                        toplogprob.logprob,
                    ]
                )
                seen.add(key)


if __name__ == "__main__":
    # gold = read_units("data/intermediate/gold_325.csv")
    # gold_ids = {row["id"] for row in gold}
    # units = list(read_units("data/intermediate/units_tk2023.csv"))

    # units = [u for u in units if u["id"] in gold_ids]
    # with open("data/intermediate/gpt_issues_gold_325.csv", "w") as f:
    #     print(f"Writing to {f.name}")
    #     writer = csv.writer(f)
    #     process_gpt(units, "nl", writer)

    # ids = {r["id"] for r in units} - gold_ids
    # units = [u for u in units if u["id"] in ids]
    # with open("data/intermediate/gpt_issues_set_rest.csv", "w") as f:
    #     print(f"Writing to {f.name}")
    #     writer = csv.writer(f)
    #     process_gpt(units, "nl", writer)
    units = read_units("data/intermediate/actors-to-annotate.csv")
    units = [
        u for u in units if int(hashlib.md5(u["id"].encode()).hexdigest(), 16) % 20 == 0
    ]
    print(len(units))
    print(units[0])
    with open("data/intermediate/gpt_issues_actors_0.csv", "w") as f:
        print(f"Writing to {f.name}")
        writer = csv.writer(f)
        process_gpt(units, "nl", writer)
