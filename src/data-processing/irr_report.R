library(annotinder)
library(tidyverse)
library(googlesheets4)
library(jsonlite)
library(irr)
library(ggplot2)


#load anonimised coders
if (file.exists(".env")) dotenv::load_dot_env(file = ".env")
coders_json = Sys.getenv("CODERS")

CODERS <- jsonlite::fromJSON(coders_json) %>% as_tibble()


download <- function(jobid) {
  backend_connect("https://uva-climate.up.railway.app",
                  username=Sys.getenv("ANNOTINDER_USERNAME"),
                  .password = Sys.getenv("ANNOTINDER_PASSWORD"))

  annotations <- tryCatch({
    download_annotations(jobid)
  }, error = function(e) {
    message("Error downloading annotations for job ID: ", jobid)
    return(NULL)
  })

  # Check if the download was successful and contains the required columns
  if (is.null(annotations) || !all(c("unit_id", "coder", "variable", "value") %in% names(annotations))) {
    message("Download for job ID ", jobid, " did not return expected columns.")
    return(NULL)
  }

  #continue processing data if checks are passed
  annotations |>
    select(unit_id, coder, variable, value) |>
    left_join(CODERS) |>
    mutate(coder=if_else(is.na(abbrev), coder, abbrev)) |>
    select(-abbrev)
}


topics <- yaml::read_yaml("annotations/topics.yml")

topiclist <- topics |> map(function(t)
  tibble(stance=c("L", "R"),
         value=c(t$positive$label$nl, t$negative$label$nl))) |>
  list_rbind(names_to = "topic") |>
  bind_rows(tibble(stance="N", value="Geen/Ander/Neutraal"))

download_stances <- function(jobids) {
  #add error handling for non-existent job ids
  safe_download <- purrr::possibly(download, NULL)

  #use safe_download
  results <- purrr::map(setNames(jobids, jobids), safe_download)
  
  message(results)

  #check if jobs contain correct variables
  purrr::keep(results, ~ !is.null(.x) && "variable" %in% names(.x)) |>

    list_rbind(names_to = "jobid") |>
    filter(variable == "stance") |>
    left_join(topiclist) |>
    arrange(coder, unit_id) |>
    group_by(jobid) |>
    filter(!all(is.na(topic))) |> #check if there are only neutral stances, results in error otherwise
    mutate(topic=unique(na.omit(topic)))
}

# retrieve Jobids from google sheets
# set OAuth token to access sheets doc
all_jobids <- read_csv('https://docs.google.com/spreadsheet/ccc?key=1CKxjOn-x3Fbk2TVopi1K7WhswcELxbzcyx_o-9l_2oI&output=csv') |>
  filter(jobid > 495) |>  #coding jobs before 495 were training an contain many duplicates
  pull(jobid) |>
  unique()

message(all_jobids)

all_stances <- download_stances(all_jobids) |>
  #for duplicates, keep latest coding
  group_by(unit_id, coder, topic, variable) |>
  slice_max(order_by = jobid, n=1)

# save all coded stances as csv
write_csv(all_stances, "data/intermediate/stances.csv")


# for wide format use:

list_units <- function(annotations) {
  units <- read_csv("data/intermediate/units_tk2023.csv",
                    col_select=c("unit_id", "before", "text_hl", "after"),
                    col_types="cccc")
  mode <- function(x) names(which.max(table(x)))
  annotations |>
    left_join(units, by="unit_id") |>
    mutate(text=str_c(str_replace_na(before, ""), text_hl, str_replace_na(after, ""))) |>
    select(-variable, -value, -before, -text_hl, -after) |>
    group_by(unit_id, topic) |>
    mutate(
      jobids = str_c(unique(jobid), collapse=","),
      majority = mode(stance),
      agreement = mean(stance == majority)) |>
    select(-jobid) |>
    ungroup() |>
    pivot_wider(names_from=coder, values_from=stance) |>
    select(-"NA") #somehow a column named NA is created with a single value
}

all_units_wide <- all_stances |>
  ungroup() |>
  list_units() |>
  arrange(unit_id)