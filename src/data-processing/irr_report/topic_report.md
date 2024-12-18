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
library(dplyr)
library(purrr)
```

``` r
gpt_units <- read_csv(here::here("data/intermediate/coded_units_gpt_nshot.csv"))|>
  select(-jobids)

all_units <- read.csv(here::here("data/intermediate/stances.csv")) |>
  ungroup() |>
  list_units() |>
  arrange(unit_id) |>
  select(-jobids) |>
  inner_join(gpt_units)

gpt_issues_all <- read_csv(here::here("data/intermediate/gpt_issues_all.csv")) |>
  filter(logprob >= -5)
```

## Coder Reliability

The overall reliability across all coded units is a Krippendorff’s alpha
of **0.73**

![](topic_report_files/figure-commonmark/plot-alpha-1.png)

## Topic Reliability

The following table reports the progression of issues coded and the
current reliability (calculated using Krippendorff’s alpha) for each
topic.

<center>

|     Topic      | Completed | Total | Percentage Done | Reliability (α) |
|:--------------:|:---------:|:-----:|:---------------:|:---------------:|
|  Agriculture   |    790    |  611  |       77%       |      0.69       |
|  CivilRights   |   1819    | 1787  |       98%       |      0.68       |
|    Defense     |    682    |   0   |       0%        |       NA        |
|       EU       |    387    |   0   |       0%        |       NA        |
|    Economic    |   1588    | 1472  |       93%       |      0.67       |
|   Education    |    561    |   1   |       0%        |      1.00       |
|  Environment   |   1650    | 1650  |      100%       |      0.70       |
|   Government   |   1774    |   0   |       0%        |       NA        |
|     Health     |    849    |   0   |       0%        |       NA        |
|    Housing     |    422    |   0   |       0%        |       NA        |
|  Immigration   |   2163    | 1944  |       90%       |      0.83       |
| Infrastructure |    203    |   0   |       0%        |       NA        |
|     Order      |    627    |   0   |       0%        |       NA        |

</center>

## Topic: Agriculture

![](topic_report_files/figure-commonmark/pairwise-plots-1.png)

#### Topic α score: 0.6871619

## Topic: CivilRights

![](topic_report_files/figure-commonmark/pairwise-plots-2.png)

#### Topic α score: 0.6784887

## Topic: Economic

![](topic_report_files/figure-commonmark/pairwise-plots-3.png)

#### Topic α score: 0.6706365

## Topic: Education

![](topic_report_files/figure-commonmark/pairwise-plots-4.png)

#### Topic α score: 1

## Topic: Environment

![](topic_report_files/figure-commonmark/pairwise-plots-5.png)

#### Topic α score: 0.695394

## Topic: Immigration

![](topic_report_files/figure-commonmark/pairwise-plots-6.png)

#### Topic α score: 0.8340466
