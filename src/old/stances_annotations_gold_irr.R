library(tidyverse)
library(annotinder)

dotenv::load_dot_env()
backend_connect("https://uva-climate.up.railway.app", 
                username=Sys.getenv("ANNOTINDER_USERNAME"), 
                .password = Sys.getenv("ANNOTINDER_PASSWORD"))

annotations = c(
   290 # First set of 100
  ,294 # Second set of 100, only with stance
  ,296 # Third set of 100, random sample
  ,297 # Fourth set of 100, only with stance,
  ,298 # Same sentences as 296-297, coded by additional authors
  ,325 # New set of 100 with 'dimensional' codes
)

dl_stance_annotations <- function(jobid) {
  a <- download_annotations(jobid) |> 
  select(unit_id, coder, variable, value) |>
    add_column(jobid=jobid, .before = 0)
  if (jobid == 294)  {
    a |> mutate(coder=case_match(coder,
                                 "nel@nelruigrok.nl" ~ "NR", 
                                 "nelruigrok@nieuwsmonitor.org" ~ "JF",
                                 "vanatteveldt@gmail.com" ~ "WvA"))
  } else {
    a |> mutate(coder=case_match(coder,
                                 "info@jessicafiks.nl" ~ "JF",
                                 "nelruigrok@nieuwsmonitor.org" ~ "NR",
                                 "vanatteveldt@gmail.com" ~ "WvA",
                                 "marikenvandervelden@gmail.com" ~ "MvdV",
                                 "s.sramota@vu.nl" ~ "Sarah",
                                 "m.e.reuver@vu.nl" ~ "MR",
                                 .default = coder))
  }
}


alpha <- function(codes) {
  # kripp.alpha likes numbers, so convert to factor -> number
  irrlist <- codes |> 
    select(unit_id, coder, value) |>
    mutate(value = as.numeric(as.factor(codes$value))) |>
    pivot_wider(names_from=coder) |>
    column_to_rownames("unit_id") |>
    as.matrix() |>
    t() |> 
    irr::kripp.alpha(method="nominal")
  return(irrlist$value)
}

irr_stance <- function(data, coder1, coder2) {
  topics = data |> 
    filter(variable == "topic", coder %in% c(coder1, coder2))

  agree = topics |> 
    group_by(unit_id) |> 
    summarize(nunique=length(unique(value))) |>
    filter(nunique == 1)
  
  positions <- data |>
    filter(variable == "position", coder %in% c(coder1, coder2)) |>
    semi_join(agree)
  tibble(coders=str_c(coder1, coder2, sep="-"), 
         alpha_topic=alpha(topics), n_stance=nrow(agree), alpha_stance=alpha(positions))
}

irr.table <- function(data) {
  totals = tibble(
    coders = "Total",
    alpha_topic = data |> filter(variable == "topic") |> alpha(),
    n_stance = length(unique(data$unit_id)),
    alpha_stance = data |> filter(variable == "position") |> alpha()
  )
  coderpairs = expand_grid(unique(data$coder), unique(data$coder)) |> 
    rename(coder1=1, coder2=2) |>
    filter(coder1 > coder2)
  
  bind_rows(
    pmap(coderpairs, 
         function(coder1, coder2) irr_stance(data, coder1, coder2)) |> list_rbind(),
    totals
    )
}

# Get annotations, remove Sarah for now, and map 296-297 to 298 since they're the same units

a <- map(annotations, dl_stance_annotations, .progress = T) |> list_rbind() |>
  mutate(jobid = if_else(jobid %in% 296:297, 298, jobid)) |>
  filter(coder != "Sarah")

dict <- read_csv("data/raw/topics_dict.csv") |> unique()
# Check that all topics are in the dictionary
a |> filter(variable == "topic", !value %in% dict$nl)

a <- a |> left_join(rename(dict, value=nl)) |>
  mutate(value=if_else(variable=="topic", en, value)) |>
  select(-en)


alphas <- bind_rows(
  unique(a$jobid) |> map(function(job) filter(a, jobid==job) |> irr.table() |> add_column(jobid=as.character(job), .before=0)) |> list_rbind(),
  irr.table(a) |> add_column(jobid="Total", .before=0),
)

alphas |> filter(jobid != "Total") |> ggplot(aes(x=jobid, y=alpha_topic, color=coders, group=coders)) +geom_line()
alphas |> filter(jobid != "Total") |> ggplot(aes(x=jobid, y=alpha_stance, color=coders, group=coders)) +geom_line()

alphas |> filter(jobid == 298, coders == "Total")

d <- alphas |> filter(jobid == "Total", coders != "Total") |>
  separate(coders, into=c("coder1", "coder2")) |>
  select(-jobid, -n_stance)
rbind(d, rename(d, coder2=coder1, coder1=coder2)) |>

  pivot_longer(-coder1:-coder2) |>
  mutate(name=fct_rev(name)) |> 
  ggplot(aes(x=coder1, y=coder2, fill=value, label=round(value,2))) +
  geom_tile() + geom_text() + theme_minimal() + 
  theme(panel.grid.major = element_blank(), legend.position = "none") + 
  #scale_fill_gradient(low="white", high="darkgreen") + 
  scale_fill_gradient2(low="darkred", mid="white", high="darkgreen", midpoint = .6) + 
  xlab("") + ylab("") + 
  facet_grid(cols=vars(name)) + 
  ggtitle("Agreement on topic and stance", "Note: Stance agreement for sentences where coders agreed on topic")



map(unique(a$coder), function(coder) irr_stance(a, coder)) |> list_rbind()

irr_stance(a, "NR")

# Write CSV to resolve conflicts and create gold standard


s <- a |> filter(variable != "quality") |>
  arrange(unit_id, coder, desc(variable)) |>
  group_by(unit_id, coder) |>
  summarize(stance=str_c(value, collapse=" : "))


texts = read_csv("data/intermediate/units_tk2023.csv") |>
  select(unit_id, before, text_hl, after)

to_check <- s |> pivot_wider(names_from=coder, values_from=stance) |>
  mutate(score=(JF == NR) + (NR == WvA) + (JF == WvA))

right_join(texts, to_check) |>
  write_csv("data/tmp/moregold.csv")

# Third round of coding


s <- a |> filter(variable != "quality") |>
  arrange(unit_id, coder, desc(variable)) |>
  group_by(jobid, unit_id, coder) |>
  pivot_wider(names_from=variable) |>
  mutate(position=case_match(position, "Neutraal" ~ "=", "Voor" ~ "+", "Tegen" ~ "-"),
         stance=str_c(topic, position)) |> 
  filter(jobid == 298) |>
  ungroup()

units <- s |>
  group_by(unit_id, topic) |>
  mutate(nt=n()) |>
  group_by(unit_id, stance) |>
  mutate(ns=n()) |>
  group_by(unit_id) |>
  summarize(topic_agree=max(nt), agree_stance=max(ns), 
         maj.topic=collapse::fmode(topic),
         maj.stance=collapse::fmode(stance))


topics <- s |> select(unit_id, coder, topic) |>
  mutate(coder = str_c(coder, "_t")) |>
  pivot_wider(names_from=coder, values_from=topic) 

stances <- s |> select(unit_id, coder, stance) |>
  pivot_wider(names_from=coder, values_from=stance) 


units |> left_join(texts) |> left_join(topics) |> left_join(stances) |>
  write_csv("/tmp/evenmoregold.csv")

left_join(units, topics)  |> group_by(MR_t, maj.topic)  |> summarize(n=n())|> filter(MR_t!=maj.topic) |> arrange(-n)

left_join(units, topics)  |> group_by(WvA_t, maj.topic)  |> summarize(n=n())|> filter(WvA_t!=maj.topic) |> arrange(-n) |> filter(n>1)
left_join(units, topics)  |> group_by(JF_t, maj.topic)  |> summarize(n=n())|> filter(JF_t!=maj.topic) |> arrange(-n) |> filter(n>1)
left_join(units, topics)  |> group_by(NR_t, maj.topic)  |> summarize(n=n())|> filter(NR_t!=maj.topic) |> arrange(-n) |> filter(n>1)

