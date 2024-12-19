create_train_unit <- function(unit_id, md, explanation, gold, ...) {
  create_unit(unit_id, 
              list(type = "markdown", name = "staat dit ergens dan?", value = md),
              list(type="train", variable="stance", value=gold, operator="==", 
                   message="**Incorrect**. Het gegevens antwoord is niet correct. Lees onderstaande uitleg en probeer het opnieuw",
                   damage=0, submessage=explanation),
              type="train")
}

create_message_unit <- function(md, ...) {
  id <- paste0(".message.", paste(sample(c(LETTERS, letters, 0:9), 30, TRUE), collapse=""))
  md <- str_c(md, ...)
  create_unit(id=id, 
              list(type = "markdown", name = "instruction", value = md),
              codebook = create_codebook(question("", codes="Continue"))
              )
}

library(googlesheets4)
library(tidyverse)

# Get gold codings
gold_job = 457
gs4_auth(email = "n.karadavut@student.vu.nl")
gold =googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/1CKxjOn-x3Fbk2TVopi1K7WhswcELxbzcyx_o-9l_2oI/edit?gid=871520840#gid=871520840", sheet = as.character(gold_job)) |>
  rename_with(str_to_lower) |>
  select(unit_id, topic, gold, example, explanation)
topic = unique(gold$topic)

cb <- get_topic_stance_codebook(topic)

t <- yaml::read_yaml("annotations/topics.yml")[[topic]]
gold_labels = tribble(
  ~gold, ~gold_label,
  "L", t$positive$label$nl,
  "N", "Geen/Ander/Neutraal",
  "R", t$negative$label$nl)

if (length(topic) != 1) stop("Topic needs to be unique!")

all_units <- read_csv("data/intermediate/units_tk2023.csv")

units <- inner_join(gold, all_units) |>
  left_join(gold_labels) |>
  mutate(md = unit_markdown(before, text_hl, after)) |> 
  select(unit_id, md, gold=gold_label, example, explanation)


easy_units <- units |> filter(example == "easy") |> pmap(create_train_unit) |> list_c()
hard_units <- units |> filter(example == "hard") |> pmap(create_train_unit) |> list_c()
other_units = units |> filter(!example %in% c("easy", "hard")) |> 
  select(unit_id, md) |>
  create_units(id='unit_id', set_markdown('text_hl', md))
job_units = c(
  get_instruction_unit(topic=topic),
  create_message_unit("We beginnen met een aantal trainingscoderingen.\n\nCodeer elke zin volgens de instructies van de vorige pagina. ",
                      "Als hij doorgaat na de volgende zin was jouw antwoord correct. ",
                      "Als je het verkeerde antwoord gaf krijg je uitleg over de codering en met je het nog een keer proberen."),
  easy_units,
  hard_units,
  create_message_unit("Hierna volgen de eerste echte coderingen. Je krijgt hier geen feedback meer op.\n\n",
                      "Tip: Je kan met het (?) symbool altijd de instructies opnieuw raadplegen.\n\nVeel succes!"),
  other_units)

upload_job("Test instructions", job_units, cb)


