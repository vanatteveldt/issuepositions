library(annotinder)
library(tidyverse)


CODERS = tribble(
  ~coder, ~abbrev,
  "a.m.j.van.hoof@vu.nl", "AvH",
  "m.e.reuver@vu.nl", "MR",
  "vanatteveldt@gmail.com", "WvA",
  "info@jessicafiks.nl", "JF",
  "nelruigrok@nieuwsmonitor.org", "NR",
  "s.sramota@vu.nl", "Sarah",
  "i.nait.el.ghazi@student.vu.nl", "ghazi",
  "n.karadavut@student.vu.nl", "karadavut",
  "s.b.van.haasteren@student.vu.nl", "haasteren",
  "o.ben.youssef@student.vu.nl", "youssef"
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
    filter(coder1 > coder2) |>
    pmap(function(coder1, coder2) confusion_matrix(annotations, coder1, coder2) |>
           add_column(coder1=coder1, coder2=coder2)) |>
    list_rbind()
}
plot_pairwise_confusion <- function(cms, coders=NULL) {
  if (!is.null(coders)) cms <- cms |> filter(coder1 %in% coders, coder2 %in% coders)
  ggplot(cms, aes(x=value.x, y=value.y, fill=n, label=n)) + geom_tile()+ geom_text() +
    scale_fill_gradient(low="white", high=scales::muted("green")) +
    theme_minimal() + theme(axis.text.x = element_text(angle=45, hjust=1)) + 
    xlab("") + ylab("") + theme(legend.position="none") +
    facet_grid(vars(coder1), vars(coder2))
}

a <- download(325)
plot_report(a, "topic", "IRR report for job 325")
cms = pairwise_confusion(a, "topic")
plot_pairwise_confusion(cms, coders=c("JF", "WvA", "NR", "Sarah"))
plot_pairwise_confusion(a, "topic")
  
