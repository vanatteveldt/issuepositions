library(annotinder)
library(tidyverse)


CODERS = tribble(
  ~coder, ~abbrev,
  "a.m.j.van.hoof@vu.nl", "AvH",
  "m.e.reuver@vu.nl", "MR",
  "vanatteveldt@gmail.com", "Wouter",
  "info@jessicafiks.nl", "Jessica",
  "nelruigrok@nieuwsmonitor.org", "Nel",
  "s.sramota@vu.nl", "Sarah",
  "i.nait.el.ghazi@student.vu.nl", "Ihsane",
  "n.karadavut@student.vu.nl", "Nisanur",
  "s.b.van.haasteren@student.vu.nl", "Sascha",
  "o.ben.youssef@student.vu.nl", "Oumaima",
  "k.narain@student.vu.nl", "Karishma"
)
  
download <- function(jobid) {
  dotenv::load_dot_env()
  backend_connect("https://uva-climate.up.railway.app", 
                  username=Sys.getenv("ANNOTINDER_USERNAME"), 
                  .password = Sys.getenv("ANNOTINDER_PASSWORD"))
  download_annotations(jobid) |> select(unit_id, coder, variable, value) |> 
    left_join(CODERS) |> 
    mutate(coder=if_else(is.na(abbrev), coder, abbrev)) |> 
    select(-abbrev)
}

a
pairwise_alpha(a$unit_id, a$coder,a$stance)
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

topics <- yaml::read_yaml("annotations/topics.yml")
topiclist <- topics |> map(function(t) 
  tibble(stance=c("L", "R"), 
         value=c(t$positive$label$nl, t$negative$label$nl))) |>
  list_rbind(names_to = "topic") |>
  bind_rows(tibble(stance="N", value="Geen/Ander/Neutraal")) 

download_stances <- function(jobids) {
  purrr::map(setNames(jobids, jobids), download) |> 
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
    mutate(majority=mode(stance),
           agreement=mean(stance==majority)) |>
    ungroup() |>
    pivot_wider(names_from=coder, values_from=stance)
}

jobs = c(361, 368)
a <- download_stances(jobs) |> 
  filter(jobid == 368 | coder != "NR") |>
  mutate(jobid=if_else(jobid == "368", "361", jobid)) 

a <- download_stances(401)
table(a$jobid, a$coder)


a |> group_by(jobid, unit_id, coder) |> filter(n() >1)
  

a |> filter(jobid == "361")  |> list_units() |>
  write_csv("/tmp/361.csv")

nel = a|>
  filter(coder=="NR")
write_csv(nel,"/tmp/nel.csv")
  
table(l$jobid, is.na(l$WvA))

plot_report(a, "stance", "IRR report for job 401")

plot_pairwise_confusion(a, "Wouter", "Nel",var="stance")


cms |> filter(coder1 == "Jessica") |> group_by(value.x) |> summarize(n=sum(n))

# Codeurs vergelijken met gold standard

gold <- googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/1CKxjOn-x3Fbk2TVopi1K7WhswcELxbzcyx_o-9l_2oI/edit?gid=871520840#gid=871520840")  |>
  select(unit_id, decision) |> 
  filter(!is.na(unit_id)) |>
  add_column(coder="Gold") |> 
  separate(decision, into=c("topic", "stance"), sep="/") |>
  pivot_longer(topic:stance, names_to="variable") 

b <- a |> 
  bind_rows(gold) |>
  filter(variable == "topic", coder != "NR", coder != "Sarah") 

a |> select(unit_id, coder, stance) |> pivot_wider(names_from=coder, values_from=stance)


list_units(a) |> write_csv("/tmp/401.csv")

a |> select(unit_id) |> write_csv("data/intermediate/set_2_ids.csv")
