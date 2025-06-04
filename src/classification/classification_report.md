# Performance of automatic classification


We tested a variety of models in different x-shot settings and with ~~or
without~~ chain-of-reasoning prompts.

Specifically, the model was asked to judge the stance of actors in 100
sentences on 12 topics. The specific meaning of each stance depends on
the topic, but the options were always L (mostly left/progressive
stances), N (neutral) or R (more right-wing/conservative). For more
information, see the [codebook](./codebook/codebook.md) and [topic
list](./codebook/topics-en.md) ([dutch](./codebook/topics-nl.md)).

# Overall performance

The table below gives the overall (macro-averaged) performance of each
model:

| model   | shot  | reason |    n |   acc |     f |
|:--------|:------|:-------|-----:|------:|------:|
| gpt-4.1 | 0shot | reason | 1200 | 0.598 | 0.605 |
| gpt-4.1 | 1shot | reason | 1200 | 0.647 | 0.653 |
| gpt-4.1 | 3shot | reason | 1200 | 0.677 | 0.680 |
| o4-mini | 0shot | reason | 1200 | 0.662 | 0.662 |
| o4-mini | 1shot | reason | 1200 | 0.683 | 0.682 |
| o4-mini | 3shot | reason | 1200 | 0.684 | 0.685 |

# Per topic performance

The table below shows the f-score for each model per topic
(macro-averaged over the stances including N), with the best model per
topic indicated in bold:

![](classification_report_files/figure-commonmark/pertopic-1.png)

# Per class performance

Finally, the tables below give per-class precision/recall/f scores and
confusion matrices for each invidual model:

## Model gpt-4.1: 0shot (reason)

![](classification_report_files/figure-commonmark/detailed-1.png)![](classification_report_files/figure-commonmark/detailed-2.png)

## Model o4-mini: 0shot (reason)

![](classification_report_files/figure-commonmark/detailed-3.png)![](classification_report_files/figure-commonmark/detailed-4.png)

## Model gpt-4.1: 1shot (reason)

![](classification_report_files/figure-commonmark/detailed-5.png)![](classification_report_files/figure-commonmark/detailed-6.png)

## Model o4-mini: 1shot (reason)

![](classification_report_files/figure-commonmark/detailed-7.png)![](classification_report_files/figure-commonmark/detailed-8.png)

## Model gpt-4.1: 3shot (reason)

![](classification_report_files/figure-commonmark/detailed-9.png)![](classification_report_files/figure-commonmark/detailed-10.png)

## Model o4-mini: 3shot (reason)

![](classification_report_files/figure-commonmark/detailed-11.png)![](classification_report_files/figure-commonmark/detailed-12.png)
