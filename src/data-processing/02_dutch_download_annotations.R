library(annotinder)
password = rstudioapi::askForPassword(prompt = 'Password: ')
annotinder::backend_connect("https://uva-climate.up.railway.app", username="nelruigrok@nieuwsmonitor.org", .password = password)

get_annotations_wider <- function(id) {
  download_annotations(id) |> 
    select(-seconds, -jobset, -coder_id) |>
    pivot_wider(names_from=variable)
}


# Step 0: Older annotations only had doc-sentence, not doc-sentence-party, 
# so we rematch via coded sentences
sentences = read_csv("data/intermediate/sents_npo.csv")
# units_orig are the same units from 00, but with spaces also before periods
units_orig  = read_rds("data/intermediate/units_orig.rds")

#' Match (coded) sentences with the new units to find out which actor was selected
match_units <- function(doc_id) {
  units = units_orig |> filter(doc_id == .env$doc_id)
  sentences |> filter(doc_id == .env$doc_id) |> 
    mutate(index=stringdist::amatch(text, units$text, maxDist = Inf),
           matched=units$text[index],
           actor=units$actor[index],
           dist=stringdist::stringdist(text, matched)) 
}

# Apply match function per unique document
matched <- sentences |> 
  pull(doc_id) |> 
  unique() |> 
  purrr::map(match_units, .progress = TRUE) |> 
  list_rbind()
# Note, distances all occured because of only a single **actor** in the sentences, 
# but sometimes **actor** (**party**) in the units, giving a multiple of 4 for the distance.
# I manually checked all distances > 4, and a sample of distance 4, they all seemed fine. 
# The missing values were caused by 3 documents being on 31/10, so not included in final data set
# We'll just discard these and keep all the rest
actor_link <- matched |> 
  filter(!is.na(dist)) |> 
  mutate(unit_id=str_c(sent_id, actor, sep="-")) |>
  select(old_unit_id=sent_id, unit_id)
  
table(actor_link$actor)
# First round of annotations. 
ids = 235:237
annotations <- setNames(ids, ids) |> 
  purrr::map(get_annotations_wider) |>
  list_rbind(names_to = "job_id") |>
  rename(old_unit_id=unit_id) |>
  inner_join(actor_link) |>
  select(-old_unit_id) |>
  relocate(unit_id, .before=1)

write_csv(annotations, "data/intermediate/annoations_01_dutch_types.csv")

