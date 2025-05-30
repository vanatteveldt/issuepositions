# Create the 'gold standard' units to test GPT issue allocation
# Input: Google sheet "Coding round 4"
# Ouput: data/intermediate/gold_325.csv

library(googlesheets4)
library(tidyverse)

topics <- yaml::read_yaml("annotations/topics.yml")
googlesheets4::gs4_auth()
d = googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/1CKxjOn-x3Fbk2TVopi1K7WhswcELxbzcyx_o-9l_2oI/edit?gid=871520840#gid=871520840", sheet = "Coding round 4") |>
  filter(!is.na(unit_id))

d |> select(unit_id, before, text_hl, after, decision) |>
  mutate(gold_topic=str_remove_all(decision, "/[LRN]"),
         gold_stance=str_extract(decision, "/([LRN])", group=1))
write_csv("data/intermediate/gold_325.csv")
