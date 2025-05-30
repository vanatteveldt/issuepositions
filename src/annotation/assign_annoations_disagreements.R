library(tidyverse)

source(here::here("src/lib/annotinder_data.R"))

# Load in coder abbreviations and topic
CODERS <- c("WA","NR","SH","NK","KN","NPR","JE","AM")

# Load units coded so far
all_coded_units <- read_csv("data/intermediate/stances.csv") 

# Retrieve assigned jobs from Google sheets and units per job from annotinder
library(googlesheets4)
jobs <- get_assigned_jobs() |>
  mutate(coder = recode(coder, "Amani" = "AM", "Karishma" = "KN", "Nisa" = "NK", "Sascha" = "SH", "Nathanael" = "NPR", "Jelle" = "JE", "Nel" = "NR", "Wouter" = "WA")) |>
  filter(!coder == "Iedereen")


all_assigned_units <- get_units_per_job(unique(jobs$jobid)) |>
  rename(jobid = Jobid)

all_assigned_combined <- inner_join(jobs, all_assigned_units, relationship="many-to-many") |>
  distinct()

mode <- function(x) {
  x = na.omit(x)
  if (length(x) == 0) return(NA)
  names(which.max(table(x)))
}

all_units <- full_join(
  select(all_coded_units, topic, unit_id, coder, stance, coded_jobid=jobid),
  select(all_assigned_combined, topic, unit_id, coder, assigned_jobid=jobid) 
) |>
  group_by(topic, unit_id) |>
  summarise(n_assigned=n(),
            n_coded=sum(!is.na(stance)),
            majority = mode(stance),
            agreement = mean(stance == majority, na.rm = T)
) |>
  arrange(topic, unit_id)


# filter for no agreement and less than 4 codings
todo <- all_units |> 
  filter(n_assigned < 4, agreement < 1) 
#  filter(topic == "Agriculture")



# Who can still code the remaining todo units?
inner_join(todo, all_assigned_combined) |>
  group_by(topic, coder) |>
  summarize(n_assigned=n()) |>
  ungroup() |>
  complete(topic, coder,fill = list(n_assigned=0)) |>
  inner_join(todo |> group_by(topic) |> summarize(n_todo=n())) |>
  mutate(can_do=n_todo - n_assigned)


# Assign a coder to a topic:

TOPIC = "Defense"
CODER = "AM"

# filter for coder and topic (set topic at top of script)
todo_for_coder = todo |>
  anti_join(
    all_assigned_combined |> 
    filter(coder == CODER) |> 
    select(unit_id, topic)
    ) |>
  filter(topic == TOPIC)

# Select items to code
to_assign <- todo_for_coder |> 
  slice_sample(n=100) |>
  pull(unit_id)

source(here::here("src/lib/stancetinder.R"))

message(glue::glue("To assign {length(to_assign)} units in topic {TOPIC}"))

# load csv with markdown info
units_tk <- read_csv("data/intermediate/units_tk2023.csv")

# Create units
units <- units_tk |> 
  filter(unit_id %in% to_assign) |> 
  mutate(md = unit_markdown(before, text_hl, after)) |>
  select(unit_id, md) |>
  create_units(id='unit_id', set_markdown('text_hl', md))

get_instruction_unit(topic=TOPIC)[[1]]
units2 = c(get_instruction_unit(topic=TOPIC), units)
units2[[1]]$unit$markdown_fields[[1]]$value

cb <- get_topic_stance_codebook(TOPIC)
connect_annotinder()
upload_job(glue::glue("No Agreement set 2: {TOPIC} for {CODER}"), units2, cb)




