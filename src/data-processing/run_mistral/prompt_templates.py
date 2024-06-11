import pandas as pd
import csv
import re
import topics

def make_examples(examples_dataframe, n_shots):
    examples = examples_dataframe.sample(n_shots, random_state=42).reset_index()
    texts = examples_dataframe["text"]
    new_texts = ""
    
    for n in range(0, len(examples)):
        new_texts = new_texts + "\n" + f"example {n+1}:"
        new_text = f"argument: {texts[n]} \n "
        new_texts =  new_texts + "\n" + new_text
    return new_texts

def describe_topic(t):
    descriptions = [t.get("description"), t.get("positive"), t.get("negative")]
    return ". ".join(d for d in descriptions if d)

def basic_prompt(data,  n_shots=None):
    '''Prompt template function'''

    prompt_pre = """You will be provided with a Dutch language sentence as well as some context before and after the sentence. 
    In that sentence, a specific actor is expressing an issue position.
    Your task is to identify the issue that that actor is taking a position on.
    You can choose from the answers listed below: """

    prompt_post = """Please answer with a single word, e.g. Environment or Housing. 
    If the actor does not take a position on any of these issues, answer None. Do NOT repeat the query. 
    """

    prompt_topic = "\n".join(
        f"Code: {key}. Description: {describe_topic(val)}"
        for (key, val) in topics.get_topics_internationalized("en").items()
    )

    prompt = f"{prompt_pre}\n\n{prompt_topic}\n\n{prompt_post}"

    return prompt


def make_prompts(sentences, base_prompt):
    
    gold_sentences = csv.DictReader(open(sentences))
    prompts = []

    for i, row in enumerate(gold_sentences):
        sent = row["text"]
        if not (m := re.search(r"\*\*(.*?)\*\*", sent)):
            raise ValueError(f"Cannot parse {sent!r}")
        actor = m.group(1)
        sent_clean = re.sub(r"\*\*", "", sent)
        text = f'Sentence: "{sent_clean}". Context: "{row["before"]}. {row["after"]}". Actor: {actor}. Which issue? Answer:'
    
        prompt = base_prompt + text 
        prompts.append(prompt)
        
    return prompts