library(annotinder)
library(tidyverse)
library(googlesheets4)
library(jsonlite)
library(irr)

#load anonimised coders
dotenv::load_dot_env(file = ".env")
coders_json = Sys.getenv("CODERS")
CODERS <- fromJSON(coders_json) %>% as_tibble()

  
download <- function(jobid) {
  dotenv::load_dot_env(file = ".env")
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


topics <- yaml::read_yaml("C:/Users/jelle/OneDrive/Documents/VU/issuepositions/annotations/topics.yml")

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
    
    #check if jobs contain correct variables
    purrr::keep(results, ~ !is.null(.x) && "variable" %in% names(.x)) |>
    
    list_rbind(names_to = "jobid") |>
    filter(variable == "stance") |>
    left_join(topiclist) |>
    arrange(coder, unit_id) |>
    group_by(jobid) |>
    mutate(topic=unique(na.omit(topic)))
}

list_units <- function(annotations) {
  units <- read_csv("data/intermediate/units_tk2023.csv", 
                    col_select=c("unit_id", "before", "text_hl", "after"), 
                    col_types="cccc") 
  mode <- function(x) names(which.max(table(x)))
  annotations |> 
    left_join(units, by="unit_id") |>
    mutate(text=str_c(before, text_hl, after)) |>
    select(-variable, -value, -before, -text_hl, -after) |>
    group_by(jobid, unit_id) |>
    mutate(
      majority = mode(stance),
      agreement = mean(stance == majority)) |>
    ungroup() |>
    pivot_wider(names_from=coder, values_from=stance)
}

# retrieve Jobids from google sheets
# set OAuth token to access sheets doc
all_jobids <- read_sheet("https://docs.google.com/spreadsheets/d/1CKxjOn-x3Fbk2TVopi1K7WhswcELxbzcyx_o-9l_2oI/edit?gid=1748110643#gid=1748110643") |>
  filter(Jobid >= 495 & Jobid <= 618) |>     #coding jobs before 495 were training an contain many duplicates, jobs after 619 were not yet finished
  pull(Jobid) |> 
  unique()

all_stances <- download_stances(all_jobids) |>
  #for duplicates, keep latest coding
    group_by(unit_id, coder, topic, variable) |> 
    slice_max(order_by = jobid, n=1)

all_units <- all_stances |>
  list_units() |>
  arrange(unit_id, jobid)

# # Identify the abbreviations of coders that are present in all_units
present_coders <- intersect(CODERS$abbrev, names(all_units))

# # Convert only the columns for the present coders to numeric values
all_units_numeric <- all_units |> 
   mutate(across(all_of(present_coders), ~ as.numeric(factor(.))))

write_csv(all_units_numeric, "data/intermediate/coded_units.csv")

# Reliability calculation and plotting

# Prepare the data as a matrix for Krippendorff's alpha calculation
all_units_matrix <- all_units_numeric |>
  select(all_of(present_coders)) |>
  as.matrix() |>
  t()

# Calculate Krippendorff's alpha for entire dataset
kripp_alpha <- kripp.alpha(all_units_matrix, method = "nominal")


print(kripp_alpha)



alpha <- function(units, coders, values) {
  # kripp.alpha likes numbers, so convert to factor -> number
  tibble(unit_id=units, coder=coders, value=values) |>
    mutate(value = as.numeric(as.factor(value))) |>
    pivot_wider(names_from=coder) |>
    column_to_rownames("unit_id") |>
    as.matrix() |>
    t() |> 
    irr::kripp.alpha(method="nominal") |>
    with(value)
}


pairwise_alpha <- function(units, coders, values) {
  a <- tibble(unit_id=units, coder=coders, value=values)
  result = NULL
  for (coder1 in unique(coders)) {
    for (coder2 in unique(coders)) {
      if (coder2 > coder1) {
        sub = a |> filter(coder %in% c(coder1, coder2)) |>
          group_by(unit_id) |> 
          filter(n() == 2) 
        result = bind_rows(result, tibble(
          coder1=coder1, coder2=coder2, n=length(unique(sub$unit_id)), 
          alpha=alpha(sub$unit_id, sub$coder, sub$value)))
        
      }
    }
  }
  result
}

plot_report <- function(annotations, var="topic", title="IRR Report") {
  annotations <- annotations |> filter(variable == var)
  alpha <- with(annotations, round(alpha(unit_id, coder, value), 2))
  n <- length(unique(annotations$unit_id))
  report <- with(annotations, pairwise_alpha(unit_id, coder, value))
  ggplot(report, aes(y=coder1, x=coder2, fill=alpha, label=str_c(round(alpha, 2), "\nn=",n))) + 
    geom_tile() + geom_text() + scale_fill_gradient2(midpoint=.5, high=scales::muted("green")) +
    ggtitle(title, str_c("Overall alpha=", round(alpha,2),", n=", n)) +
    theme_minimal() + xlab("") + ylab("") + theme(legend.position="none")
}

confusion_matrix <- function(annotations, coder1, coder2) {
  inner_join(filter(annotations, coder==coder1),
             filter(annotations, coder==coder2),
             by="unit_id") |>
    group_by(value.x, value.y) |>
    summarize(n=n(), .groups="drop")
}

pairwise_confusion <- function(annotations, var="topic") {
  annotations <- annotations |> filter(variable == var)
  coders = unique(annotations$coder)
  cms <- expand_grid(coder1=coders, coder2=coders) |>
    filter(coder1 != coder2) |>
    pmap(function(coder1, coder2) confusion_matrix(annotations, coder1, coder2) |>
           add_column(coder1=coder1, coder2=coder2)) |>
    list_rbind()
}
plot_pairwise_confusion <- function(annotations, coder1, coder2, var="topic") {
  pairwise_confusion(annotations, var=var) |>
    filter(coder1==.env$coder1, coder2==.env$coder2) |>
    ggplot(aes(x=value.x, y=value.y, fill=n, label=n)) + geom_tile() + geom_text() +
    scale_fill_gradient(low="white", high=scales::muted("green")) +
    theme_minimal() + theme(axis.text.x = element_text(angle=45, hjust=1)) + 
    xlab(coder1) + ylab(coder2) + theme(legend.position="none")
}

# plot_report(a, "stance", "IRR report for job 401")

# table(a$jobid, a$coder)


# a |> group_by(jobid, unit_id, coder) |> filter(n() >1)
  

# a |> filter(jobid == "417")  |> list_units() 

# nel = a|>
#   filter(coder=="NR")
# write_csv(nel,"/tmp/nel.csv")
  
# table(l$jobid, is.na(l$WvA))


# plot_pairwise_confusion(a, "Jessica", "Nel",var="stance")


# cms |> filter(coder1 == "Jessica") |> group_by(value.x) |> summarize(n=sum(n))

# # Codeurs vergelijken met gold standard

# gold <- googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/1CKxjOn-x3Fbk2TVopi1K7WhswcELxbzcyx_o-9l_2oI/edit?gid=871520840#gid=871520840")  |>
#   select(unit_id, decision) |> 
#   filter(!is.na(unit_id)) |>
#   add_column(coder="Gold") |> 
#   separate(decision, into=c("topic", "stance"), sep="/") |>
#   pivot_longer(topic:stance, names_to="variable") 

# b <- a |> 
#   bind_rows(gold) |>
#   filter(variable == "topic", coder != "NR", coder != "Sarah") 

# a |> select(unit_id, coder, stance) |> pivot_wider(names_from=coder, values_from=stance)


# list_units(a) |> write_csv("/tmp/416.csv")

# a |> select(unit_id) |> write_csv("data/intermediate/set_2_ids.csv")

