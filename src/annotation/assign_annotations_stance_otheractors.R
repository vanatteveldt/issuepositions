library(tidyverse)
library(here)
library(annotinder)
library(dotenv)
library(purrr)

source(here::here("src/lib/stancetinder.R"))
connect_annotinder()

# Download issues
issues = bind_rows(read_csv("data/intermediate/gpt_issues_actors_0.csv"), read_csv("data/intermediate/gpt_issues_actors_1.csv"))
all_units <- read_csv("data/intermediate/actors-to-annotate.csv")

# in contrast to units_tk2023.csv, this file misses the columns 'context_start' and 'context_end'
# let's create them.
all_units <- all_units %>%
  mutate(context_start = if_else(is.na(before), start, start-nchar(before))) %>%
  mutate(context_start = if_else(context_start < 0, 1, context_start)) %>%
  mutate(context_end = if_else(is.na(after), end, end+nchar(after)))
  
head(issues)
source(here::here("src/lib/stancetinder.R"))

# Overview of topics:
issues |> filter(logprob >= -6) |> group_by(topic) |> summarize(n=n()) |> arrange(-n)

TOPIC = "CivilRights"

# Select items to code
# 1. filter on topic
# 2. remove if already coded (to be added)
# 3. take sample if needed

to_assign <- issues |> 
  filter(topic == TOPIC, logprob >= -5) |> 
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

