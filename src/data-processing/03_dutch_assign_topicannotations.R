library(tidyverse)

# Download issues
issues = read_csv("data/intermediate/gpt_issues_set_4.csv")
all_units <- read_csv("data/intermediate/units_tk2023.csv")

source(here::here("src/lib/stancetinder.R"))

table(issues$topic)

TOPIC = "CivilRights"

# Select items to code
# 1. filter on topic
# 2. remove if already coded (to be added)
# 3. take sample if needed

to_assign <- issues |> 
  filter(topic == TOPIC, logprob >= -5) |> 
  # slice_sample(n=100) |> 
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
upload_job("Stance set 1: CivilRights", units2, cb)
