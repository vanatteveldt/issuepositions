library(here)
library(amcat4r)
library(tidyverse)
library(boolydict)
library(googlesheets4)
library(tidytext)
library(corpustools)
library(udpipe)

# Step 1: Download texts and metadata from AmCAT
amcat4r::amcat_login("https://amcat4.labs.vu.nl/amcat")

# Get all data from 3 weeks before the elections
docs = amcat4r::query_documents("dutch_news_media",
                              fields = c('_id', 'date', 'publisher', 'title', 'url', 'text'),
                              filters=list(date=list(gte='2023-11-01', lte='2023-11-22')),
                              max_pages = Inf, scroll='5m')

# Filter excluding financieel dagblad and television listings
docs <- docs |> 
  filter(publisher != 'fd',
         str_detect(title, 'België 1|BVN|NPO 1|NPO 2|NPO 3|INHOUD|Kruiswoordtest', negate=TRUE))

saveRDS(docs, here("data/tmp/data_tk2023.rds"))
    
# Step 2: Filter documents to mention a political party
docs = readRDS("data/tmp/data_tk2023.rds")

gs4_deauth()
politiek <- read_sheet('https://docs.google.com/spreadsheets/d/1d3G1_y_HJP2Ik1v7rKrxeAXL4uCt5mLNgc8uC7vzQyI/edit#gid=0', sheet = "combi")
docs <- docs |> dict_filter(politiek)

udpipe

###TOKANIZATION is done separately for newspapers to avoid R crashing
nrc = data|>
  filter(publisher=="nrc")|>
  rename(doc_id=.id)

tokens_nrc = udpipe::udpipe(nrc, "dutch", parser="none") |> 
  as_tibble() |> select(doc_id:sentence_id, start:upos)



saveRDS(tokens_nrc, "data/tokens_nrc2023.rds")

##hieronder plak ik de eerder gemaakte rds aan elkaar

media = c("ad","nrc","trouw","vk","nos", "nu","telegraaf")
media

resultaten = list()

for (m in media){
  d = readRDS(paste0("data/tokens_",m,"2023.rds"))
  resultaten[[m]]=d
}
tokens = dplyr::bind_rows(resultaten)

#selection of tokens to exclude FD 
tokens = tokens|>
  filter(doc_id %in% data$.id)


saveRDS(tokens,"data/tokens_tk2023.rds")


##HERE it starts for TOKENS

tokens = readRDS("data/tokens_tk2023.rds")

tokens = tokens|>
  filter(doc_id %in% data$.id)

googlesheets4::gs4_deauth()
issues <- read_sheet('https://docs.google.com/spreadsheets/d/1rHS7pnuuUWl_1lM9eWmtV0fwj4-2-2R2M4Yg375ecvs/edit#gid=0', sheet = "totaal")
partijen <- read_sheet('https://docs.google.com/spreadsheets/d/1d3G1_y_HJP2Ik1v7rKrxeAXL4uCt5mLNgc8uC7vzQyI/edit#gid=0', sheet = 1)


##FOR SUCCES
hits2 = tokens |> 
  filter(paragraph_id<3) |>
  dict_add(issues, text_col = 'token', by_label='label', fill = 0)

focus2 = hits2 |> 
  pivot_longer(-doc_id:-upos, names_to = 'poll', values_to='npoll') |>
  filter(npoll > 0) |>
  group_by(doc_id) |>
  slice_min(order_by=start, n=1, with_ties = F) |>
  select(doc_id, sentence_id, token_id) |>
  add_column(focus=1)


sents2=tokens |>
  filter(paragraph_id<3) |>
  filter(doc_id %in% focus2$doc_id) |>
  left_join(focus2) |> 
  left_join(select(focus, doc_id, sentence_id, sentence_focus=focus)) |>
  as_tibble() |>
  mutate(token = if_else(!is.na(focus), str_c("**", token, "**"), token)) |>
  mutate(sent_id=paste0(doc_id,"-",sentence_id))|>
  group_by(doc_id, sent_id) |> 
  summarize(text = str_c(token, collapse=" "),
            sent_text = str_c(if_else(is.na(sentence_focus), "", token), collapse=" ") |> trimws())|>
  mutate(before=ifelse(sent_text !="" & doc_id==lag(doc_id), lag(text), sent_text),
         after=ifelse(sent_text !="" & doc_id==lead(doc_id), lead(text), sent_text),
  )|>
  filter(sent_text !="")

#####ISSUE POSITIONS ONLY ACTOR 

hits = tokens |> 
  dict_add(partijen, text_col = 'token', by_label='label', fill = 0)


focus = hits |> 
  pivot_longer(-doc_id:-upos, names_to = 'party', values_to='nparty') |>
  filter(nparty > 0) |>
  group_by(doc_id) |>
  slice_min(order_by=start, n=1, with_ties = F) |>
  select(doc_id, sentence_id, token_id, party) |>
  add_column(focus=1)



sents=tokens |>
  filter(doc_id %in% focus$doc_id) |>
  left_join(focus) |> 
  left_join(select(focus, doc_id, sentence_id, sentence_focus=focus, party)) |>
  as_tibble() |>
  mutate(token = if_else(!is.na(focus), str_c("**", token, "**"), token)) |>
  mutate(sent_id=paste0(doc_id,"-",sentence_id))|>
  group_by(doc_id, sent_id, party) |> 
  summarize(text = str_c(token, collapse=" "),
            sent_text = str_c(if_else(is.na(sentence_focus), "", token), collapse=" ") |> trimws())|>
  mutate(before=ifelse(sent_text !="" & doc_id==lag(doc_id), lag(text), sent_text),
         after=ifelse(sent_text !="" & doc_id==lead(doc_id), lead(text), sent_text),
  )|>
  filter(sent_text !="")

head(sents)


####SELECTION ACTOR ISSUE within context
googlesheets4::gs4_deauth()
issues <- read_sheet('https://docs.google.com/spreadsheets/d/1rHS7pnuuUWl_1lM9eWmtV0fwj4-2-2R2M4Yg375ecvs/edit#gid=0', sheet = "totaal")
partijen <- read_sheet('https://docs.google.com/spreadsheets/d/1d3G1_y_HJP2Ik1v7rKrxeAXL4uCt5mLNgc8uC7vzQyI/edit#gid=0', sheet = 1)


actors = tokens |> 
  dict_add(partijen, text_col = 'token', by_label='label', fill = 0)|>
  mutate(tot =BBB+CDA+CU+D66+FvD+`GL/PvdA`+JA21+NSC+PVV+PvdD+SGP+SP+VVD+Volt+Overig)|>
  filter(tot>0)


issue = tokens |> 
  mutate(sent_id = paste0(doc_id,"-",sentence_id))|>
  dict_add(issues, text_col = 'token', by_label='label', fill = 0)|>
  filter(issue>0)

focus = actors |> 
  group_by(doc_id) |>
  slice_min(order_by=start, n=1, with_ties = F) |>
  select(doc_id, sentence_id, token_id) |>
  add_column(focus=1)


sents=tokens |>
  filter(doc_id %in% focus$doc_id) |>
  left_join(focus) |> 
  left_join(select(focus, doc_id, sentence_id, sentence_focus=focus)) |>
  as_tibble() |>
  mutate(token = if_else(!is.na(focus), str_c("**", token, "**"), token)) |>
  mutate(sent_id=paste0(doc_id,"-",sentence_id))|>
  group_by(doc_id, sent_id) |> 
  summarize(text = str_c(token, collapse=" "),
            sent_text = str_c(if_else(is.na(sentence_focus), "", token), collapse=" ") |> trimws())|>
  mutate(isissue = as.numeric(sent_id %in% issue$sent_id)) |>
  mutate(before=ifelse(sent_text !="" & doc_id==lag(doc_id), lag(text), sent_text),
         after=ifelse(sent_text !="" & doc_id==lead(doc_id), lead(text), sent_text),
      #   issue_before=ifelse(doc_id == lag(doc_id), lag(isissue), 0),
       #  issue_after=ifelse(doc_id == lead(doc_id), lead(isissue), 0),
  )|> 
  filter(sent_text !="", isissue + issue_before + issue_after > 0)

sents
head(sents)



d2 = sents|>
  filter(sent_id %in% c$unit_id)
####Even sample voor het coderen
sents2$newrow <- sample(7, size = nrow(sents2), replace = TRUE)
numbers = 1:7
for (i in numbers){
  name = paste0('f', i)
  name = sents2|>
    filter(newrow==i)
}

write_csv(sents, "data/tk2023_issue_coding.csv")
d2 = sents2|>
  filter(! sent_id %in% artcodings$sent_id)|>
  filter(newrow>=3)

arts = artcodings|>
  mutate(doc_id, s = separate(sent_id,"-"))



issue2= read_csv("data/tk2023_issue2_nl.csv")
d2=sents|>
  filter(! sent_id %in% issue2$sent_id)


# Data, hier met tekst en titel
units = create_units(data3, id = 'sent_id', set_text('sent_text', sent_text, bold=T, before = before, after =after )) 
class(units)

frame = question('frame', 'Wat is het frame van deze zin?', codes = c('Issue positie', 'Succes & falen', 'Conflict', "Anders"))
issueposition = question("issue position", 'Wordt er in deze zin een issuepositie weergegeven?', codes = c('Ja', 'Nee'))
conflict = question('conflict', 'Wordt er in deze zin een conflict weergegeven?', codes = c('Ja', 'Nee'))
succes = question("succes en falen",'Gaat het over succes en falen van een actor?', codes = c('Ja', 'Nee'))
codebook = create_codebook(issueposition=issueposition, conflict=conflict, succes=succes)

# Job uploaden naar de server
annotinder::backend_connect("https://uva-climate.up.railway.app", username="nelruigrok@nieuwsmonitor.org", .password = "test")
jobid = annotinder::upload_job("test", units, codebook)


# Coderen
url = glue::glue('https://uva-climate.netlify.app/?host=https%3A%2F%2Fuva-climate.up.railway.app&job_id={jobid}')
print(url)
browseURL(url)

# Resultaten downloaden

todo = seq(235:237,1)
artcodings = list()
id=236
for(id in todo) {
  message("* Getting job ",id, " (", length(artcodings)+1, "/", length(todo), ")")
  c3 = download_annotations(id)
  if (is.null(c)) next
  artcodings[[as.character(id)]] = c
}

length(unique(c$unit_id))
c=c|>
  bind_rows(c2)

head(sents)
head(c)

table(c3$unit_id %in% c2$unit_id)
table(sents$sent_id %in% c$unit_id)

table(c$status)
tbc = c|>
  filter(! unit_id %in% n$unit_id )|>
  distinct(unit_id)

table(n$unit_id %in% tbc$unit_id)
d3=sents|>
  filter(sent_id %in% tbc$unit_id)

table(c$unit_id %in% sents$sent_id)
table(c$variable)

#hieronder wordt alles aan elkaar gekoppeld
artcodings = dplyr::bind_rows(artcodings)|>
  select(-jobset)
#Rename values into numbers
table(artcodings$value)
##SPLITTEN DATA IN FRAMES


issues = c|>
  filter(variable =="issue position")|>
  rename(sent_id = unit_id)|>
  left_join(sents)|>
  rename(label=value)|>
  mutate(sent_text= gsub("[**]","", sent_text))|>
  mutate(sent_text = trimws(sent_text))|>
  mutate(label_text = if_else(label == "Nee", "issue_no", "issue_yes"))|>
  select(sent_id, sent_text, label)

conflict = c|>
  filter(variable =="conflict")|>
  rename(sent_id = unit_id)|>
  left_join(sents)|>
  rename(label=value)|>
  mutate(sent_text= gsub("[**]","", sent_text))|>
  mutate(sent_text = trimws(sent_text))|>
  mutate(label_text = if_else(label == "Nee", "issue_no", "issue_yes"))|>
  select(sent_id, sent_text, label)

sf = c|>
  filter(variable =="succes en falen")|>
  rename(sent_id = unit_id)|>
  left_join(sents)|>
  rename(label=value)|>
  mutate(sent_text= gsub("[**]","", sent_text))|>
  mutate(sent_text = trimws(sent_text))|>
  mutate(label_text = if_else(label == "Nee", "issue_no", "issue_yes"))|>
  select(sent_id, sent_text, label)

write_csv(sf,"data/sf_eng.csv")
write_csv(conflict,"data/conflict_eng.csv")
write_csv(issue,"data/issue_eng.csv")

library(httr)
library(jsonlite)
library(deeplr)



get_deepl = function(text){
  toEnglish(
    text,
    source_lang = "nl",
    split_sentences = TRUE,
    preserve_formatting = FALSE,
    get_detect = FALSE,
    auth_key = "00abd0d1-c264-4b2b-9101-17f5a9a92b22"
  )
}

get_deepls = function(texts) purrr::map_chr(texts, get_deepl)

add_deepls = function(data, in_column, out_column) {
  if (!out_column %in% colnames(data)) data[[out_column]] = NA_character_
  for (i in seq_along(data[[in_column]])) {
    tryCatch( {
    result = data[[out_column]][i]
    if (is.na(result)) {
      message(i)
      data[i, out_column] <- get_deepl(data[[in_column]][i])
    }}, error = function(e) {warning(str_c("Error in line ", i))})
    
    if (i %% 100 == 0) {
      message(str_c(i, ", saving results as data.rds"))
      saveRDS(data, "data.rds")
    }
  }
  return(data)
}

out = add_deepls(test, "sent_text", "translated")



coded1804_eng = coded1804|>
  mutate(before = ifelse(is.na(before),"-",before))|>
  mutate(after = ifelse(is.na(after),"-",after))|>
  mutate(before = ifelse(! is.na(before), get_deepls(before), before),
         after = ifelse(! is.na(after),get_deepls(after), after),
         sent_text = get_deepls(sent_text))|>
  mutate(label_text = if_else(label == 0, "issue_no", "issue_yes"))


write_csv(coded1804_eng,"data/coded1804_eng.csv")




tot = artcodings|>
  bind_rows(nl)

table(issue3$label)
issue2=read_csv("data/tk2023_issue2_eng.csv")
issue3=issue2|>
  bind_rows(artcodings_tot)
write_csv(stance2, "data/tk2023_issue4_nl.csv")

###
stance = read_csv("data/tk2023_issue3_nl.csv")
table(stance2$label_text, stance2$value)

stance2=stance|>
  mutate(value = label_text)
actors=sents|>
  ungroup()|>
  select(sent_id, party)
stance2=stance|>
  left_join(actors)

eng = eng|>
  select(-label, -label_text, -value)

nl = read_csv("data/tk2023_issue1_nl.csv")
artcodings

sf = artcodings|>
  select(sent_id, label, label_text)|>
  left_join(eng)

write_csv(sf,"data/tk2023_sf1_eng.csv")

###TO BE CODED


nos_data=data|>
  filter(publisher=="NOS.nl")

tokens_nos=tokens|>
  filter(doc_id %in% nos_data$.id)

nos=tokens_nos |>
  mutate(sent_id=paste0(doc_id,"-",sentence_id))|>
  group_by(doc_id, sent_id) |> 
  summarize(sent_text = str_c(token, collapse=" ") |> trimws())|>
  filter(sent_text !="")

nos_eng = add_deepls(nos, "sent_text", "translated")

write_csv(nos_eng, "data/stances_tobecoded.csv")


head(c)
nel = n|>
  mutate(coder="nel")|>
  filter(status=="DONE")|>
  filter(! unit_id %in% nel2$unit_id)

nel2 = n2|>
  mutate(coder="nel")|>
  filter(status=="DONE")
  

table(nel$unit_id %in% nel2$unit_id)

jessica = c|>
  mutate(coder='jessica')

tbc=jessica|>
  filter(! unit_id %in% nel$unit_id)

coded = nel|>
  bind_rows(nel2,jessica)|>
  filter(variable=="conflict")
coded

check =coded|>
  group_by(unit_id)|>
  summarise(n=n())|>
  arrange(-n)

table(coded$variable)
library(reshape2)

coded2=coded%>%select(unit_id,variable,coder, value)
cm = acast(coded2, unit_id ~ coder, value.var='value')
kappa=irr::kappa2(cm)
kappa
