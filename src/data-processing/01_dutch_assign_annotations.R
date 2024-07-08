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

coded <- map(CODINGJOBS, get_annotations_wider, .progress=T) |> list_rbind()


# Set 298: Re-assign units from jobs 296 and 297
# d3 = semi_join(units, filter(coded, jobid %in% 296:297))

# Set 324 Assign 100 more uncoded units
set.seed(123)
d3 <- semi_join(units, with_issue) |> anti_join(coded) |> slice_sample(n=100)

# Create annotinder objects

d3 = d3 |> mutate(md = str_c(
  if_else(is.na(before), "", before),
  str_c(" **", str_replace_all(text_hl, "\\*\\*", "`"), "** "),
  if_else(is.na(after), "", after)
  ))

units = create_units(d3, id = 'unit_id', set_markdown('text_hl', md)) 

cb = get_stance_codebook()

# Job uploaden naar de server
jobid = annotinder::upload_job("dimensies", units, cb)


# Coderen
url = glue::glue('https://uva-climate.netlify.app/?host=https%3A%2F%2Fuva-climate.up.railway.app&job_id={jobid}')
print(url)
browseURL(url)
cat(d3$md[1])
