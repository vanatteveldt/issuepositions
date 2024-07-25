library(tidyverse)

d <- read_csv("data/intermediate/gold_325_gpt_issues_nl.csv")  |>
  replace_na(list(topic="None"))

d |> filter(topic == "Education") |> 
  filter(logprob >= -5) |>
  with(table(gold == "Education", response))

d |> filter(response == "Onder") |> with(table(rank))

choices = d |>
  filter(response != "Onder") |>
  select(unit_id, gold, topic, rank, logprob) |>
  mutate(correct = topic == gold,
         gold_none = if_else(gold == "None", "None", "Issue")) |>
  arrange(unit_id, rank) |>
  group_by(unit_id) |> mutate(rank2=row_number()) |> ungroup()
  

# Pre/Re per rank
ntot = choices |> group_by(gold_none) |> summarize(ntot=length(unique(unit_id)))
choices |>
  #filter(response != 'None') |>
  arrange(unit_id, rank) |>
  group_by(gold_none, rank2) |>
  summarize(n=n(), correct=mean(correct)) |>
  left_join(ntot) |>
  mutate(tp=n*correct, re=cumsum(tp)/ntot, pr=cumsum(tp)/cumsum(n))

  
choices |>
  group_by(unit_id) |>
  filter(logprob >= -5) |>
  group_by(gold_none) |>
  summarize(n=n(), avg_correct=mean(correct), found=sum(correct)) |>
  left_join(ntot) |> 
  mutate(recall=found/ntot) |>
  relocate(ntot, .after=1)


metrics <- function(logprob_threshold) {
  n_actual = choices |> filter(gold != 'None', rank==0) |> nrow()
  choices |>
    filter(topic != 'None') |>
    filter(logprob >= logprob_threshold) |>
    summarize(logprob=logprob_threshold, n_actual=n_actual, n_positives=n(), tp=sum(correct)) |>
    mutate(pr=tp/n_positives,
           re=tp/n_actual,
           f1=2*pr*re/(pr+re),
           f3=10*pr*re/(9*pr + re))
}



roc <- map(-1:-20, metrics) |> list_rbind() |> 
  mutate(label=glue::glue("lp≥{logprob};n={n_positives};f3={round(f3,2)}")) 

ggplot(roc, aes(x=pr, y=re, label=label)) + 
  geom_line() + 
  geom_point() + 
  geom_text(data=filter(roc, logprob < -4, logprob > -16, !logprob %in% c(-6, -8, -10, -12)), hjust = 0, nudge_y = .002) +
  geom_text(data=filter(roc, logprob >= -4), hjust = 1, nudge_y = -.002, nudge_x=-.01) +
  xlab("Precision") + ylab("Recall of non-None issues") + ggtitle("ROC curve for coding tokens >= logprob (NL prompt)") + 
  theme_minimal()




choices = choices |> group_by(unit_id) |> arrange(rank) |> mutate(rank2=row_number()) |> ungroup()

correct_rank = choices |> 
  filter(correct) |>
  group_by(unit_id) |> 
  summarize(rank=min(rank), rank2=min(rank2))

correct_rank |> filter(rank == 0)

top |> select(unit_id, gold_en) |>
  left_join(correct_rank) |>
  group_by(rank2, gold_en == 'None') |>
  summarize(n=n()) |>
  View()
            

d |> filter(gpt_token %in% t$gold_en)


top |> group_by(gold_en) |> summarize(n=n(), correct=mean(correct))
d |> filter(!correct) |> group_by(gold_en, gpt) |> summarize(n=n()) |> mutate(ngold=n()) |> arrange(desc(ngold), gold_en, -n) |> select(-ngold)



texts = read_csv("data/raw/annotations_stances_1_gold.csv") |> select(unit_id, before, text, after)
d
inner_join(texts, d) |> filter(!correct) |> View()

metrics = function(d, topic) {
  ngold = sum(d$gold_en == topic)
  tp = sum(d$gpt == topic & d$gold_en == topic)
  fp = sum(d$gpt == topic & d$gold_en != topic)
  fn = sum(d$gpt != topic & d$gold_en == topic)
  pr = if_else(tp+fp==0, 0, tp / (tp + fp))
  re = if_else(tp+fn==0, 0, tp / (tp + fn))
  tibble(topic=topic, ngold=ngold, pr=pr, re=re, f1=if_else(pr+re==0, 0, 2*pr*re/(pr+re)))
}


f = d$gold_en |> unique() |> map(function(t) metrics(d, t)) |> list_rbind() |> arrange(-f1)
f
c(n=nrow(d), F1_macro=mean(f$f1), Accuracy=mean(d$correct)) |> round(2)

lp0 = d |> filter(rank == 0) |> select(unit_id, logprob_0=logprob)
choices |> inner_join(lp0) |> mutate(lp = if_else(rank==-1, logprob_0, logprob)) |>
  mutate(isnone=if_else(gold_en == 'None', 'None', 'Issue'),
         gptnone=if_else(response == 'None', 'None', 'Issue')) |>
  filter(rank2 <= 3) |> 
  ggplot(aes(x=correct, y=lp, color=correct, shape=gptnone)) + 
  geom_jitter(height=0, width=.25) + 
  facet_grid(cols=vars(rank2), rows=vars(isnone)) + 
  scale_color_manual(values=c('FALSE'='darkred', 'TRUE'='darkgreen')) + 
  theme_minimal() + theme(legend.position = "none", axis.text.x = element_blank()) + 
  ylab("Logprob") + ggtitle("Logprob per rank for top-3 tokens")


choices |> filter(logprob >= -9) |> 
  group_by(gold_en, response) |>
  summarize(n=length(unique(unit_id))) |>
  mutate(p=n/sum(n)) |>
  ggplot(aes(x=gold_en, y=response, fill=n, label=round(p, 2))) + geom_tile() + geom_text() + 
  scale_fill_gradient(low="white", high="darkgreen") + 
  xlab("Gold (true) topic") + ylab("GPT predicted topic (top-N)") + 
  ggtitle("Confusion matrix of GPT topic predictions", "(column percentages)") +
  theme_minimal() + theme(axis.text.x = element_text(angle=45, hjust = 1))


choices |> filter(logprob >= -5) |> 
  group_by(gold, topic) |>
  summarize(n=length(unique(unit_id))) |>
  mutate(p=n/sum(n)) |>
  ggplot(aes(x=gold, y=topic, fill=n, label=round(p, 2))) + geom_tile() + geom_text() + 
  scale_fill_gradient(low="white", high="darkgreen") + 
  xlab("Gold (true) topic") + ylab("GPT predicted topic (top-N)") + 
  ggtitle("Confusion matrix of GPT topic predictions", "(column percentages)") +
  theme_minimal() + theme(axis.text.x = element_text(angle=45, hjust = 1))

recall <- choices |> filter(logprob >= -5) |> 
  group_by(gold, unit_id) |> 
  summarize(found=max(correct)) |>
  summarize(recall=mean(found), n_gold=n()) |> 
  rename(topic=gold)
precision <- choices |> filter(logprob >= -5) |>
  group_by(topic) |>
  summarize(precision=mean(correct), n_gpt=n())
inner_join(recall, precision) |> arrange(-n_gold)

