library(tidyverse)

# Load units coded so far and filter on agreement
all_coded_units <- read_csv("data/intermediate/coded_units.csv")

# Retrieve assigned jobs from Google sheets and units per job from annotinder
jobs <- get_assigned_jobs()

all_assigned_units <- get_units_per_job(unique(jobs$Jobid))

#jobs_with_units <- inner_join(jobs, all_assigned_units, relationship='many-to-many')

all_coded_unit_ids = pull(all_coded_units, unit_id)

unfinished_units = filter(all_assigned_units, !(unit_id %in% all_coded_unit_ids))

no_agreement_units <- all_coded_units |>
  filter(agreement <= 0.5) |>
  filter(!(unit_id %in% unfinished_units)) |>
  pivot_longer(-variable:-agreement, names_to="coder") |>
  filter(!is.na(value))

# ??
source(here::here("src/lib/stancetinder.R"))

# Load in coder abbreviations and topic
CODERS <- c("AvH","MR","WA","JF","NR","S", "ING","NK","SH","OY","KN","NPR","JE","AM")
present_coders <- intersect(CODERS, colnames(no_agreement_units))

TOPIC = "CivilRights"

coder = "AM"

# Filter for coded unit ids by coder and topic
filter_for_coder <- function(no_agreement_units, coder_name, topic_name){
  coded_unit_ids <- no_agreement_units |>
    filter(coder == coder_name) |>
    pull(unit_id)

  filtered_data <- no_agreement_units |>
    filter(!(unit_id %in% coded_unit_ids)) |>
    filter(topic == topic_name)
  
  return(filtered_data)
}

filtered_data = filter_for_coder(no_agreement_units, coder, TOPIC)

# Select items to code
to_assign <- filtered_data |> 
  slice_sample(n=50) |>
  pull(unit_id)

message(glue::glue("To assign {length(to_assign)} units in topic {TOPIC}"))

# Create units
units <- coded_units |> 
  filter(unit_id %in% to_assign) |> 
  mutate(md = unit_markdown(before, text_hl, after)) |>
  select(unit_id, md) |>
  create_units(id='unit_id', set_markdown('text_hl', md))

get_instruction_unit(topic=TOPIC)[[1]]
units2 = c(get_instruction_unit(topic=TOPIC), units)
units2[[1]]$unit$markdown_fields[[1]]$value

cb <- get_topic_stance_codebook(TOPIC)
connect_annotinder()
upload_job(glue::glue("Tie breaker set 1: {TOPIC} for {coder}"), units2, cb)
