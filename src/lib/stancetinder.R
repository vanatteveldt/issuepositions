# remotes::install_github("ccs-amsterdam/annotinder-r")
library(annotinder)
library(glue)

CODINGJOBS = c(
  290 # First set of 100
  ,294 # Second set of 100, only with stance
  ,296 # Third set of 100, random sample
  ,297 # Fourth set of 100, only with stance,
  ,298 # Same sentences as 296-297, coded by additional authors
  ,325 # Set 4, 100 articles, coded with left/right dimensions per issue
)

connect_annotinder <- function() {
  # Login to annotinder, make sure .env file with ANNOTINDER_USERNAME and ANNOTINDER_PASSWORD exists
  dotenv::load_dot_env()
  backend_connect("https://uva-climate.up.railway.app", 
                  username=Sys.getenv("ANNOTINDER_USERNAME"), 
                  .password = Sys.getenv("ANNOTINDER_PASSWORD"))
}

get_stance_codebook <- function() {
  topics <- yaml::read_yaml("annotations/topics.yml")
  codebook = read_file("annotations/codebook.md")
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

test <- function() {
  jobid = annotinder::upload_job("test branch", units, get_stance_codebook())
  
  # Coderen
  url = glue::glue('https://uva-climate.netlify.app/?host=https%3A%2F%2Fuva-climate.up.railway.app&job_id={jobid}')
  print(url)
  browseURL(url)
  

}