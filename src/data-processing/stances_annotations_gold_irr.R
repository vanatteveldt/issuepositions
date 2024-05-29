library(tidyverse)
library(annotinder)

dotenv::load_dot_env()
backend_connect("https://uva-climate.up.railway.app", 
                username=Sys.getenv("ANNOTINDER_USERNAME"), 
                .password = Sys.getenv("ANNOTINDER_PASSWORD"))

a <- download_annotations(294) |> 
  select(unit_id, coder, variable, value) |>
  mutate(coder=case_match(str_remove(coder, "@.*"),
                          "nelruigrok" ~ "JF",
                          "nel" ~ "NR",
                          "vanatteveldt" ~ "WvA"))

var = "topic"

a |> filter(variable == var) |>
  select(-variable) |>
  pivot_wider(names_from=coder) |>
  column_to_rownames("unit_id") |>
  as.matrix() |>
  t() |>
  irr::kripp.alpha()
 

# Write CSV to resolve conflicts and create gold standard

s <- a |> filter(variable != "quality") |>
  arrange(unit_id, coder, desc(variable)) |>
  group_by(unit_id, coder) |>
  summarize(stance=str_c(value, collapse=" : "))


texts = read_csv("data/intermediate/units_tk2023.csv") |>
  select(unit_id, before, text_hl, after)

to_check <- s |> pivot_wider(names_from=coder, values_from=stance) |>
  mutate(score=(JF == NR) + (NR == WvA) + (JF == WvA))

right_join(texts, to_check) |>
  write_csv("data/tmp/moregold.csv")

