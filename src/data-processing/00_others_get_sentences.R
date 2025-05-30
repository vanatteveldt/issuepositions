library(udpipe)
library(tidyverse)
library(tidytext)

d_nisa <- read_csv("data/intermediate/actor_nisa.csv")
d_madelon <- read_csv("data/intermediate/actor_madelon.csv")
d <- bind_rows(
  d_nisa,
  d_madelon |> anti_join(d_nisa, by="unit_id")
) |> select(doc_id = unit_id, offset, length, value, span=text)

docs = read_csv("data/tmp/tk2023_articles.csv") |>
  select(doc_id=`.id`, text)

to_annotate <- d |> left_join(docs) |> 
  mutate(text = str_replace_all(trimws(text), "\\s*\\n\\s*", "\u2029"),
         text = str_c(
           str_sub(text, end=offset),
           "\u2045",
           str_sub(text, offset, offset+length),
           "\u2046",
           str_sub(text, offset+length+1)
         ),
         text = str_replace_all(text, "\u2045 ", " \u2045") |> 
           str_replace_all("\u2045\u2029", "\u2029\u2045") |> 
           str_replace_all("\u2029", ".\n\n") |> 
           str_replace_all("(\\.)\\.", "\\1")
         ) |>
  unnest_sentences(output="text", input="text", to_lower=FALSE) |>
  group_by(doc_id, offset, value) |>
  arrange(doc_id, offset, value) |>
  mutate(sentence_id = row_number(), before=lag(text), after=lead(text)) |>
  ungroup() |>
  filter(str_detect(text, "\u2045")) |>
  mutate(text_hl=str_replace_all(text, "\u2045|\u2046", "**"), 
         text=str_remove_all(text, "\u2045|\u2046"),
         unit_id=str_c(doc_id, offset, value, sep="::"),
         end=offset+length) |>
  select(unit_id, doc_id, actor=value, sentence_id, start=offset, end, text, text_hl, before, after)
  
write_csv(to_annotate,"data/intermediate/actors-to-annotate.csv")

  