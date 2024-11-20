# install.packages(c("dbplyr", "RPostgres"))

library(tidyverse)

#' Retrieve the unites for each job from the annotinder postgres database
#' Note that you need to set the ANNOTINDER_POSTGRES_PASSWORD environment variable
get_units_per_job <- function(jobids) {
  dotenv::load_dot_env(file = ".env")
  con <- RPostgres::dbConnect(RPostgres::dbDriver("Postgres"), dbname = "railway", sslmode = 'require',
                              host = "roundhouse.proxy.rlwy.net", port = 41380,
                              user = "postgres", password = Sys.getenv("ANNOTINDER_POSTGRES_PASSWORD"))
  dplyr::tbl(con, "unit") |> 
    select(Jobid=codingjob_id, unit_id=external_id) |>
    filter(Jobid %in% jobids) |> 
    collect() |>
    filter(unit_id != ".instruction")
}


get_assigned_jobs <- function() {
  #coding jobs before 495 were training an contain many duplicates, jobs after 619 were not yet finished
  read_sheet("https://docs.google.com/spreadsheets/d/1CKxjOn-x3Fbk2TVopi1K7WhswcELxbzcyx_o-9l_2oI/edit?gid=1748110643#gid=1748110643") |>
    filter(Jobid >= 495) |>
    select(Jobid, Set, Topic, starts_with("Codeur")) |>
    pivot_longer(starts_with("codeur"), values_to="codeur") |>
    select(-name) |>
    filter(!is.na(codeur))
}