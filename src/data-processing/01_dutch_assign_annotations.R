# remotes::install_github("ccs-amsterdam/annotinder-r")
library(tidyverse)
library(annotinder)

# Read sentences, filter for sentences with issue

units <- read_csv("data/intermediate/units_tk2023.csv")
with_issue <- read_csv("data/intermediate/annoations_01_dutch_types.csv")|>
  filter(`issue position`=="Ja")

# Login to annotinder, make sure .env file with ANNOTINDER_USERNAME and ANNOTINDER_PASSWORD exists
dotenv::load_dot_env()
backend_connect("https://uva-climate.up.railway.app", 
                username=Sys.getenv("ANNOTINDER_USERNAME"), 
                .password = Sys.getenv("ANNOTINDER_PASSWORD"))



# Retrieve existing codings from annotinder
  
get_annotations_wider <- function(jobid) {
  download_annotations(jobid) |> 
    select(-seconds, -jobset, -coder_id) |>
    pivot_wider(names_from=variable) |>
    add_column(jobid=jobid, .before=1)
}

jobs = c(
  290, # First set of 100
  294, # Second set of 100, only with stance
  296, # Third set of 100, random sample
  297 # Fourth set of 100, only with stance
)

coded <- map(jobs, get_annotations_wider, .progress=T) |> list_rbind()

# Re-assign units from jobs 296 and 297

d3 = semi_join(units, filter(coded, jobid %in% 296:297))

# Create annotinder objects

d3 = d3 |> mutate(md = str_c(
  if_else(is.na(before), "", before),
  str_c(" **", str_replace_all(text_hl, "\\*\\*", "`"), "** "),
  if_else(is.na(after), "", after)
  ))

units = create_units(d3, id = 'unit_id', set_markdown('text_hl', md)) 

topic = question('topic', 'Wat is het onderwerp van deze tekst?', codes = c('Defensie', 'Gezondheids (zorg)', 'Boeren platteland', 
                                                                            'Beter Bestuur', 'Sociale zekerheid', 'Werk (gelegenheid)',
                                                                            'Investeren infrastructuur','Beperking Immigratie','Burgerrechten',
                                                                            'Internat.recht en ontw. samenwerking','Investeren in onderwijs en wetenschap', 
                                                                            'Investeren in Cultuur','Overheidsfin. op orde (belastingen)',
                                                                            'Natuur en Klimaat','Woning(bouw)','Criminaliteits bestrijding veiligheid','Europese Unie',
                                                                            'Ondernemers klimaat', 'Ander/geen onderwerp'))

position = question('position', 'Is de actor voor, neutraal of tegen het onderwerp?', codes = c('Voor',
                                                                                                'Neutraal',
                                                                                                'Tegen'))

# quality = question('quality', 'Stond er in deze zin nog een issuepositie van deze actor?', codes = c('Ja', 'Nee'))

codebook = create_codebook(topic=topic,position=position)

# Job uploaden naar de server
jobid = annotinder::upload_job("betrouwbaarheid5", units, codebook)


# Coderen
url = glue::glue('https://uva-climate.netlify.app/?host=https%3A%2F%2Fuva-climate.up.railway.app&job_id={jobid}')
print(url)
browseURL(url)
cat(d3$md[1])
