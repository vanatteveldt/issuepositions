library(tidyverse)

t = read_csv("topics_dict.csv") |> rename(gold=nl, gold_en=en) |> unique()

prefixes <- t |> mutate(token_pref = str_sub(gold_en, end=3), token_complete=gold_en) |> 
  select(token_pref, token_complete) |>
  unique()
  
read_csv("gpt2b.csv")|> separate(gold, into=c("nl", "position"),sep = " : ") |> select(nl)  |> unique() |> write_csv("~/Downloads/topics.csv")

d = bind_rows(read_csv("gpt2.csv"), read_csv("gpt2b.csv")) |>
  mutate(gold = str_remove_all(gold, " : .*")) |>
  inner_join(t) |>
  rename_with(.cols=starts_with("gpt_"), ~str_remove(., "gpt_"))


top = d |> filter(rank==0) |> mutate(correct = response == gold_en)
top |> group_by(gold_en == 'None')  |> summarize(correct=mean(correct), n=n())

topchoice = d |> filter(rank==0) |> select(unit_id, gold_en, response) |> 
  add_column(rank=-1, logprob=0)

choices = d |> 
  mutate(token_pref = str_sub(token, end=3)) |> 
  inner_join(prefixes)  |>
  select(unit_id, gold_en, rank, logprob, response=token_complete) |>
  bind_rows(topchoice) |>
  group_by(unit_id, response) |>
  slice_min(order_by=rank, n=1, with_ties=FALSE) |>
  ungroup() |>
  mutate(correct = response == gold_en,
         gold_none = if_else(gold_en == "None", "None", "Issue")) |>
  arrange(unit_id, rank) |>
  group_by(unit_id) |> mutate(rank2=row_number()) |> ungroup()
  

ntot = choices |> group_by(gold_none) |> summarize(ntot=length(unique(unit_id)))


choices |>
  filter(response != 'None') |>
  group_by(unit_id) |>
  arrange(rank) |>
  mutate(rank3=row_number()) |>
  ungroup() |>
  arrange(unit_id, rank) |>
  group_by(gold_none, rank3) |>
  summarize(n=n(), correct=mean(correct)) |>
  left_join(ntot) |>
  mutate(tp=n*correct, re=cumsum(tp)/ntot, pr=cumsum(tp)/cumsum(n))
  
choices |>
  filter(response != 'None') |>
  group_by(unit_id) |>
  arrange(rank) |>
  mutate(rank3=row_number()) |>
  ungroup() |> 
  filter(logprob >= -5) |>
  group_by(gold_none) |>
  summarize(n=n(), avg_correct=mean(correct), found=sum(correct)) |>
  left_join(ntot) |> 
  mutate(recall=found/ntot) |>
  relocate(ntot, .after=1)


choices |> filter(response != 'None')

choices |> filter(unit_id == "1853b9b6144334fbfb974e64bcca4831e790f072062163032a7ea055-27-Overig")

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


choices |> filter(gold_en != 'None') |>
  
