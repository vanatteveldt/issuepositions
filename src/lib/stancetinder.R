# remotes::install_github("ccs-amsterdam/annotinder-r")
library(annotinder)
library(glue)


connect_annotinder <- function() {
  # Login to annotinder, make sure .env file with ANNOTINDER_USERNAME and ANNOTINDER_PASSWORD exists
  dotenv::load_dot_env()
  backend_connect("https://uva-climate.up.railway.app", 
                  username=Sys.getenv("ANNOTINDER_USERNAME"), 
                  .password = Sys.getenv("ANNOTINDER_PASSWORD"))
}

unit_markdown <- function(before, text_hl, after) {
  str_c(
  if_else(is.na(before), "", before),
  str_c(" **", str_replace_all(text_hl, "\\*\\*", "`"), "** "),
  if_else(is.na(after), "", after))
}

get_stance_codebook <- function() {
  topics <- yaml::read_yaml("codebook/topics.yml")
  codebook = read_file("codebook/codebook.md")
  cquestions <- purrr::map(names(topics), function(t) {
    label = topics[[t]]$label$nl
    codes = c(topics[[t]]$positive$label$nl, topics[[t]]$negative$label$nl, "Neutraal")
    if (length(codes) != 3) warning(glue("Topic {t} ({label}) codes: {length(codes)}"))
    help = str_c(glue("# {label}"),
                 glue("\n\n## {codes[1]}\n\n"),
                 topics[[t]]$positive$description$nl,
                 glue("\n\n## {codes[2]}\n\n"),
                 topics[[t]]$negative$description$nl
    )
    question(glue("{t}-stance"), type="annotinder", codes=codes, instruction = help,
             question=glue("Welke stelling heeft de actor over {label}?"))})
  
  cquestions = cquestions[order(map_chr(cquestions, function(q) q$question))]
  tcodes <- purrr::map(names(topics), function(t) code(topics[[t]]$label$nl, required_for=glue("{t}-stance")))
  tcodes <- tcodes[order(map_chr(tcodes, function(c) c$code))]
  tcodes <- c(tcodes, list(code("Ander/Geen")))
  questions = c(list(question("topic", question="Over welk onderwerp neemt de uitgelichte actor een stelling in?", codes=tcodes, instruction=codebook)),
                cquestions,
                list(question("other", question="Waren er nog bijzonderheden?", codes=c("Nee", "Actor heeft nog een onderwerp", "Onderwerp niet in codeboek", "Zin is dubbelzinnig"))))
  cb <- do.call(create_codebook, questions)
}

get_topic_instruction <- function(topic) {
  t <- yaml::read_yaml("codebook/topics.yml")[[topic]]
  hint = if (is.null(t$hints$nl)) {warning("No hints given"); ""} else glue::glue("\n\n**Aanwijzingen**: {t$hints$nl}")
  description = if(is.null(t$description$nl)) {warning("No description"); ""} else t$description$nl
  glue::glue("## Wat is het standpunt over {t$label$nl}?\n{description}\n\n
### {t$positive$label$nl}\n{t$positive$description$nl}\n\n
### {t$negative$label$nl}\n{t$negative$description$nl}\n\n
### Geen/Ander/Neutraal\nAls de actor geen standpunt heeft over {t$label$nl}, of als het standpunt niet duidelijk is of niet in deze dimensies past, kies dan **Geen**
{hint}")
}

get_instruction_unit <- function(topic) {
  t <- yaml::read_yaml("codebook/topics.yml")[[topic]]
  topic_instruction <- get_topic_instruction(topic)
  instruction_md = glue::glue("# Standpunt coderen over {t$label$nl}\n\n
In de volgende schermen staat elke keer een drietal zinnen met een gemarkeerde actor. 
De centrale vraag is wat het standpunt is van de actor over {t$label$nl}. 
Je kiest hiervoor uit de twee dimensies die hieronder uitgelegd worden,
dat wil zeggen is de actor voor '*meer {t$positive$label$nl}*', of juist voor '*meer {t$negative$label$nl}*'?
Als de actor juist tegen '{t$positive$label$nl}' is, kies dan '{t$negative$label$nl}' en andersom.  

Je mag deze ruim interpreteren, het gaat om de algemene politieke richting, niet om de exacte bewoording van de dimensie.
Als het standpunt echt niet bij de dimensies past, of niet duidelijk is, of over een ander ondewerp gaat, kies dan 'geen'.
{topic_instruction}

**Tip**: Je kan deze instructies altijd opnieuw bekijken met de (?) knop onderin")                             

  create_unit(id=".instruction", 
              list(type = "markdown", name = "instruction", value = instruction_md),
              # set_markdown("instruction", instruction_md),  << This gives an error??
              codebook = create_codebook(question("", codes="Continue")))
}


get_topic_stance_codebook <- function(topic) {
  t <- yaml::read_yaml("codebook/topics.yml")[[topic]]
  instruction <- str_c(get_topic_instruction(topic), read_file("codebook/codebook-nl.md"), sep="\n\n")
  codes = c(t$positive$label$nl, t$negative$label$nl, "Geen/Ander/Neutraal")
  create_codebook(question("stance", codes=codes, type="annotinder", instruction = instruction,
                           question=str_c("Wat is het standpunt van de genoemde actor over ", t$label$nl)))
}

test <- function() {
  jobid = annotinder::upload_job("test branch", units, get_stance_codebook())
  
  # Coderen
  url = glue::glue('https://uva-climate.netlify.app/?host=https%3A%2F%2Fuva-climate.up.railway.app&job_id={jobid}')
  print(url)
  browseURL(url)
}





download <- function(jobid) {
  coders_json = Sys.getenv("CODERS")
  CODERS <- jsonlite::fromJSON(coders_json) |> as_tibble()
  
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
    select(unit_id, coder, variable, status, value) |>
    left_join(CODERS) |>
    mutate(coder=if_else(is.na(abbrev), coder, abbrev)) |>
    select(-abbrev)
}

download_stances <- function(jobids) {
  results <- map(setNames(jobids, jobids), download)
  
  
  topics <- yaml::read_yaml("codebook/topics.yml")
  topiclist <- topics |> 
    map(function(t)
      tibble(stance=c("L", "R"),
             value=c(t$positive$label$nl, t$negative$label$nl))) |>
    list_rbind(names_to = "topic") |>
    bind_rows(tibble(stance="N", value="Geen/Ander/Neutraal"))
  
  
  #check if jobs contain correct variables
  keep(results, ~ !is.null(.x) && "variable" %in% names(.x)) |>
    
    list_rbind(names_to = "jobid") |>
    filter(variable == "stance") |>
    left_join(topiclist) |>
    arrange(coder, unit_id) |>
    group_by(jobid) |>
    filter(!all(is.na(topic))) |> #check if there are only neutral stances, results in error otherwise
    mutate(topic=unique(na.omit(topic)))
}