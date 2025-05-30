# remotes::install_github("ccs-amsterdam/annotinder-r")
library(tidyverse)
library(annotinder)

source("src/lib/stancetinder.R")

# Read sentences, filter for sentences with issue

units <- read_csv("data/intermediate/units_tk2023.csv")
with_issue <- read_csv("data/intermediate/annoations_01_dutch_types.csv")|>
  filter(`issue position`=="Ja")

# Retrieve existing codings from annotinder
  
get_annotations_wider <- function(jobid) {
  download_annotations(jobid) |> 
    select(-seconds, -jobset, -coder_id) |>
    pivot_wider(names_from=variable) |>
    add_column(jobid=jobid, .before=1)
}
password = rstudioapi::askForPassword(prompt = 'Password: ')
backend_connect("https://uva-climate.up.railway.app", username="nelruigrok@nieuwsmonitor.org", .password = password)

coded <- map(CODINGJOBS, get_annotations_wider, .progress=T) |> list_rbind()


# Set 298: Re-assign units from jobs 296 and 297
# d3 = semi_join(units, filter(coded, jobid %in% 296:297))

# Re-Assign job 325 in sets of 20/40/40
d3 <- coded |> 
  filter(jobid == 325) |> 
  select(unit_id) |> 
  unique() |>
  left_join(units) 

# Create annotinder objects

d3 = d3 |> mutate(md = str_c(
  if_else(is.na(before), "", before),
  str_c(" **", str_replace_all(text_hl, "\\*\\*", "`"), "** "),
  if_else(is.na(after), "", after)
  ))


cb = get_stance_codebook()


# Job uploaden naar de server
units1 =  create_units(d3[1:20, ], id = 'unit_id', set_markdown('text_hl', md)) 
jobid1 = annotinder::upload_job("Proefcoderen 1 (20 zinnen)", units, cb)

units2 =  create_units(d3[21:60, ], id = 'unit_id', set_markdown('text_hl', md)) 
jobid2 = annotinder::upload_job("Proefcoderen 2 (40 zinnen)", units2, cb)

units3 =  create_units(d3[61:100, ], id = 'unit_id', set_markdown('text_hl', md)) 
jobid3 = annotinder::upload_job("Proefcoderen 3 (40 zinnen)", units3, cb)

