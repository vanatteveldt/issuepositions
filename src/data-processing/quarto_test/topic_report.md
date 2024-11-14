# Progression Report


This file is used to visually represent the current status of coding
data. Included are the reliability scores for coders and topics.

## Data

Raw data can be found in the [data
folder](https://github.com/vanatteveldt/issuepositions/tree/main/data)
folder and code used to generate statistics and plots is available in
[topic_status_report](https://github.com/vanatteveldt/issuepositions/blob/main/src/data-processing/topic_status_report.R)
file.

``` r
library(tidyverse)
library(irr)
library(ggplot2)
library(readr)
library(kableExtra)
library(simplermarkdown)
library(knitr)
```

``` r
all_units <- read_csv("~/VU/issuepositions/data/intermediate/coded_units.csv")
gpt_issues_all <- read_csv("~/VU/issuepositions/data/intermediate/gpt_issues_all.csv") |>
  filter(logprob >= -5)
```

## Coder Reliability

The overall reliability across all coded units is a Krippendorff’s alpha
of **0.71**

![](topic_report_files/figure-commonmark/plot-alpha-1.png)

## Topic Reliability

The following table reports the progression of issues coded and the
current reliability (calculated using Krippendorff’s alpha) for each
topic.

|     Topic      | Completed | Total | Percentage Done | Reliability (α) |
|:--------------:|:---------:|:-----:|:---------------:|:---------------:|
|   Education    |    50     | 15877 |      0.3%       |      0.26       |
|  CivilRights   |   1820    | 17137 |      10.6%      |      0.67       |
|       NA       |   5411    | 28852 |      18.8%      |      1.00       |
|  Immigration   |   2168    | 17483 |      12.4%      |      0.71       |
|    Defense     |     0     | 16000 |       0%        |      0.00       |
|  Environment   |   1373    | 16970 |      8.1%       |      0.67       |
|    Economic    |     0     | 16905 |       0%        |      0.00       |
|     Health     |     0     | 16166 |       0%        |      0.00       |
| Infrastructure |     0     | 15519 |       0%        |      0.00       |
|     Order      |     0     | 15945 |       0%        |      0.00       |
|   Government   |     0     | 17093 |       0%        |      0.00       |
|       EU       |     0     | 15703 |       0%        |      0.00       |
|    Housing     |     0     | 15740 |       0%        |      0.00       |
|  Agriculture   |     0     | 16106 |       0%        |      0.00       |

Topic Status Overview
