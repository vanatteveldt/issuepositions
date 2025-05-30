install.packages("here")
install.packages("Annotinder")
install.packages("remotes")
remotes::install_github("ccs-amsterdam/annotinder-r")
library(tidyverse)
library(here)
library(annotinder)
library(dotenv)
library(purrr)

source(here::here("src/lib/stancetinder.R"))
connect_annotinder()

# Download issues
issues = read_csv("data/intermediate/gpt_issues_all.csv")
all_units <- read_csv("data/intermediate/units_tk2023.csv")
head(issues)
source(here::here("src/lib/stancetinder.R"))

table(issues$topic)

TOPIC = "Education"

# Select items to code
# 1. filter on topic
# 2. remove if already coded (to be added)
# 3. take sample if needed


## gebruiken voor test
to_assign <- issues |> 
  filter(set %in% c(25))|>
  filter(topic == TOPIC, logprob >= -5) |> 
  #slice_sample(n=40) |> 
  pull(unit_id)

to_assign <- issues |> 
  filter(topic == TOPIC, logprob >= -5) |> 
  filter(set == 11) |> ## hier wijs je een specifieke set toe
  pull(unit_id)

message(glue::glue("To assign {length(to_assign)} units in topic {TOPIC}"))

# Create units
units <- all_units |> 
  filter(unit_id %in% to_assign) |> 
  mutate(md = unit_markdown(before, text_hl, after)) |>
  select(unit_id, md) |>
  create_units(id='unit_id', set_markdown('text_hl', md))
get_instruction_unit(topic=TOPIC)[[1]]
units2 = c(get_instruction_unit(topic=TOPIC), units)
units2[[1]]$unit$markdown_fields[[1]]$value

cb <- get_topic_stance_codebook(TOPIC)
connect_annotinder()
upload_job("Stance set 1: Education", units2, cb)

