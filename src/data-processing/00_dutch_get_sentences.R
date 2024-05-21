library(amcat4r)
library(tidyverse)
library(boolydict)
library(googlesheets4)
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

saveRDS(docs, "data/tmp/data_tk2023.rds")
    
# Step 2: Filter documents to mention a political party
docs = readRDS("data/tmp/data_tk2023.rds")

gs4_deauth()
politiek <- read_sheet('https://docs.google.com/spreadsheets/d/1d3G1_y_HJP2Ik1v7rKrxeAXL4uCt5mLNgc8uC7vzQyI/edit#gid=0', sheet = "combi")
docs <- docs |> dict_filter(politiek)

### Step 3: Tokenize all text with udpipe 
# (a bit expensize for just tokenizing, but maybe the POS will come in useful and at least it gives sentences and offsets as well)

tokens <- docs |> 
  rename(doc_id=.id) |>
  udpipe("dutch", parser="none") |> 
  as_tibble() |>
  tokens |>
  mutate(index=str_c(doc_id, ":", term_id)) |>
  select(index, doc_id:sentence_id, start:upos)

saveRDS(tokens,"data/tmp/tokens_tk2023.rds")

### Step 4: Select all sentence:actor pair and reconstruct sentence and context

tokens = readRDS("data/tmp/tokens_tk2023.rds")

gs4_deauth()
partijen <- read_sheet('https://docs.google.com/spreadsheets/d/1d3G1_y_HJP2Ik1v7rKrxeAXL4uCt5mLNgc8uC7vzQyI/edit#gid=0', sheet = 1)


#' Add spaces if the next word doesn't immediately follow this word
add_spaces <- function(token, sentence_id, start, end) {
  if_else(!is.na(lead(sentence_id)) & sentence_id == lead(sentence_id) & end < lead(start) - 1, str_c(token, " "), token)
}
#' Select the text indicated by a hit (doc+sentence+actor), as well as the before and after context
get_context <- function(doc_id, sentence_id, actor) {
  hit <- hits |> filter(doc_id == .env$doc_id, sentence_id == .env$sentence_id, actor == .env$actor)
  sentences <- tokens |> filter(doc_id == .env$doc_id) |>
    filter(sentence_id >= .env$sentence_id - 1, sentence_id <= .env$sentence_id + 1) |> 
    # Put ** around found terms so they highlight in annotinder, add spaces
    mutate(token_hl = if_else(term_id %in% hit$term_id, str_c("**", token, "**"), token)) |>
    mutate(token = add_spaces(token, sentence_id, start, end),
           token_hl = add_spaces(token_hl, sentence_id, start, end)) |>
    group_by(sentence_id) |>
    summarize(text=str_c(token, collapse=""), text_hl=str_c(token_hl, collapse=""), start=min(start), end=max(end))
  tibble(
    doc_id=doc_id,
    actor=actor,
    sentence_id=sentence_id,
    start = sentences$start[sentences$sentence_id == sentence_id],
    end = sentences$end[sentences$sentence_id == sentence_id],
    context_start = min(sentences$start),
    context_end = max(sentences$end),
    text = sentences$text[sentences$sentence_id == sentence_id],
    text_hl = sentences$text_hl[sentences$sentence_id == sentence_id],
    before = ifelse((sentence_id - 1) %in% sentences$sentence_id, sentences$text[sentences$sentence_id == sentence_id-1], NA_character_),
    after = ifelse((sentence_id + 1) %in% sentences$sentence_id, sentences$text[sentences$sentence_id == sentence_id+1], NA_character_),
  )
}
hits <- tokens |> dict_match(partijen, mode='terms', text_col='token', context_col = "doc_id")  |> 
  mutate(doc_id = tokens$doc_id[data_index],
         sentence_id = tokens$sentence_id[data_index],
         term_id = tokens$term_id[data_index],
         actor = partijen$label[dict_index])

units <- hits |> 
  select(doc_id, sentence_id, actor) |>
  unique() |> 
  purrr::pmap(get_context, .progress = TRUE) |>
  list_rbind() |>
  mutate(unit_id = str_c(doc_id, sentence_id, actor, sep="-")) |>
  relocate(unit_id, .before=1)
  
write_csv(units,"data/intermediate/units_tk2023.csv")
