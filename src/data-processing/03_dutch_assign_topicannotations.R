library(tidyverse)

# Download issues
issues = read_csv("data/intermediate/gpt_issues_set_1.csv")
all_units <- read_csv("data/intermediate/units_tk2023.csv")

TOPIC = "Economic"

# Select items to code
# 1. filter on topic
# 2. remove if already coded (to be added)
# 3. take sample if needed

to_assign <- issues |> 
  filter(topic == TOPIC, logprob >= -5) |> 
  slice_sample(n=100) |> 
  pull(unit_id)

# Create units
units <- all_units |> filter(unit_id %in% to_assign) |> 
  mutate(md = unit_markdown(before, text_hl, after)) |>
  # Uncomment om de instructie onder elke zin te zetten
  #rowwise() |>
  #mutate(md = str_c(md, get_topic_instruction(TOPIC, actor), sep = "\n\n")) |>
  select(unit_id, md) |>
  create_units(id='unit_id', set_markdown('text_hl', md))

cb <- get_topic_stance_codebook(TOPIC)

upload_job("Test wouter", units, cb)
