# classification


# Overall performance

| model   | shot  | reason |    n |   acc |     f |
|:--------|:------|:-------|-----:|------:|------:|
| gpt-4.1 | 0shot | reason | 1200 | 0.598 | 0.605 |
| gpt-4.1 | 1shot | reason | 1200 | 0.647 | 0.653 |
| gpt-4.1 | 3shot | reason | 1200 | 0.677 | 0.680 |
| o4-mini | 0shot | reason | 1200 | 0.662 | 0.662 |
| o4-mini | 1shot | reason | 1200 | 0.683 | 0.682 |
| o4-mini | 3shot | reason | 1200 | 0.684 | 0.685 |

# Per topic performance

![](classification_report_files/figure-commonmark/pertopic-1.png)

# Per class performance

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
