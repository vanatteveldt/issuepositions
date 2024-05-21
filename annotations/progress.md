# Annotations: Overall approach and progress

Many existing projects would code this with a single codebook extracting the triples directly from text. However, we think that it is best to split the coding into smaller steps to make it easier to code and to make it possible to automate the easier steps (i.e. recognizing actors) while concentrating coding effort on the harder steps. 

Thus, we split the overall coding into four distinct sub-steps:
1. Does the sentence mention a (relevant) political actor?
2. Is that political actor expressing an issue position?
3. What issue is the actor expressing a position about?
4. What is the polarity of the issue

Note: Step one should be resolvable without extra coding with a combination of keyword search (gazetteering) and some form of co-reference resolution. 

Note2: If we can automatically identify issues that are mentioned in a text (e.g. using the existing CAP models), it might be better to swap step 3 and 2 and ask (“which issue(s) are mentioned in the text”) and (“does actor X express a position about issue Y”). 

# Progress

## Step 1: Does the sentence contain a political actor?

For step 1, we selected sentences mentioning a political actor from the (national) newspaper and NOS.nl coverage of the 2023 Dutch election using a simple keyword search (party name or party leader name). 
This yielded 24378 unique sentence-party combinations from 16.866 sentences (some sentences mention more than one party). 

[[script](/src/data-processing/02_dutch_download_annotations.R)][[data](/data/intermediate/units_tk2023.csv)]

## Step 2: Does the actor express an issue position?

From these, we [coded 1,335 sentences for whether or not it expresses an issue position](/data/intermediate/annoations_01_dutch_types.csv).
153 sentences were coded by two coder, giving a Krippendorff's alpha of .855 ([script]()). 

Based on these codings, we trained a BERT and BERT-NLI model to automate this coding step. 

+ [A simple BERT model](src/data-processing/10_dutch_bert.py) (that did not take into account the party for which the question was coded) without any hyperparameter tuning gave a precision of 79% and recall of 77%, for F1-score .78 (using 5-fold crossvalidation]
+ [A BERT-NLI model](src/data-processing/10_dutch_bert_nli.py) that used the party into the prompt/hypothesis formulation without any hyperparameter tuning gave a precision of 77% with a recall of 82%, for an F!-score of .79 (also with 5-fold xval)

## Step 3: What issue is the actor expressing a position about? (WIP)

This should be coded along the [issue dimensions defined in the codebook](codebook.md). These are essentially 'directed' versions of the [CAP codebook](https://www.comparativeagendas.net/pages/master-codebook), which turned out to be very close to the codes we used earlier (main difference is we collapsed some of the issues, had a specific issue for government finances, and missed the defense and agriculture issues, which are pretty relevant now anyways). 

We are currently testing the coding issue and polarity in a single job (i.e. asking "which of these dimensions is this a position on" and "is the actor in favour of or against <issue>".

If possible, it would probably be better to 'guess' the issue and ask a single question (favour/neutral/against/no position). The people on the CAP project released a model that should code issues, we can also try a zero/few shot model based on the first codings that are happening now
