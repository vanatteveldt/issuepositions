#' IAA, Inter-Annotator Agreement Scores
#' Created by: Philipp Mendoza
#' Date: 2025-05-01
#' -------------------------------------------------------------------------
#' Description:
#' Goal:
#' Calculate span Inter Annotator Agreement between two annotors.
#' • Exact span matches, where two annotators identified exact the same Named Entity text spans.
#' • Relaxed span matches, where Named Entity text spans from two annotators overlap.
#' 
#' Sources: 
#' - Wang, K., Stevens, R., Alachram, H., Li, Y., Soldatova, L., King, R., Ananiadou, S., Schoene, A. M., Li, M., Christopoulou, F., Ambite, J. L., Matthew, J., Garg, S., Hermjakob, U., Marcu, D., Sheng, E., Beißbarth, T., Wingender, E., Galstyan, A., … Rzhetsky, A. (2021). NERO: A biomedical named-entity (recognition) ontology with a large, annotated corpus reveals meaningful associations through text embedding. Npj Systems Biology and Applications, 7(1), 1–8. https://doi.org/10.1038/s41540-021-00200-x
#' - Hripcsak, G. (2005). Agreement, the F-Measure, and Reliability in Information Retrieval. Journal of the American Medical Informatics Association, 12(3), 296–298. https://doi.org/10.1197/jamia.m1733


# load libraries -------------------------------------------------------------------
library("dplyr")
library("ggplot2")
library("purrr")
# library("valr")       # for range overlaps - not needed, too many dependencies
library("see")        # for half violin plots


# functions -------------------------------------------------------------
# General Formula for IAA:
iaa_score <- function(a, b, c) {
  if (a == 0 && b == 0 && c == 0) {
    NA_real_
  } else {
    2 * a / (2 * a + b + c)
  }
}

# Span match detection function. Works for two coders.
score_doc <- function(
    df_doc # should contain doc_id, coder_id, start, end
) {
  # input validation
  stopifnot(c("doc_id", "coder_id", "start", "end") %in% names(df_doc))
  ids <- unique(df_doc$coder_id)
  stopifnot(length(ids) == 2)
  
  # create two data frames for each coder
  c1 <- df_doc |>
    filter(coder_id == ids[1]) |>
    distinct() |> 
    mutate(span_id = row_number())
  c2 <- df_doc |>
    filter(coder_id == ids[2]) |>
    distinct() |> 
    mutate(span_id = row_number())
  
  # exact span match - "where two annotators identified exact the same Named Entity text spans."
  exact_pairs <- inner_join(c1, c2, by = c("start", "end"))
  a_exact <- nrow(exact_pairs)
  b_exact <- nrow(c1) - a_exact
  c_exact <- nrow(c2) - a_exact
  iaa_exact <- iaa_score(a_exact, b_exact, c_exact)
  
  # relaxed (overlap) span match - "where Named Entity text spans from two annotators overlap."
  # bed1 <- c1 |> select(chrom = doc_id, start, end, id1 = span_id)
  # bed2 <- c2 |> select(chrom = doc_id, start, end, id2 = span_id)
  # overlap_pairs <- valr::bed_intersect(bed1, bed2) |> distinct(id1.x, id2.y)
  
  overlap_pairs <- inner_join(
    c1 %>% rename(s1 = start, e1 = end, id1 = span_id),
    c2 %>% rename(s2 = start, e2 = end, id2 = span_id),
    by = "doc_id"
  ) %>%
    filter(s1 <= e2, e1 >= s2) %>%   # the overlap condition
    distinct(id1, id2)
  
  a_relaxed <- nrow(overlap_pairs)
  b_relaxed <- nrow(c1) - a_relaxed
  c_relaxed <- nrow(c2) - a_relaxed
  iaa_relaxed <- iaa_score(a_relaxed, b_relaxed, c_relaxed)
  
  # create output tibble row
  tibble(
    doc_id = df_doc$doc_id[1],
    a_exact, b_exact, c_exact, iaa_exact,
    a_relaxed, b_relaxed, c_relaxed, iaa_relaxed
  )
}


# example for current project ---------------------------------------------
# input for function: data frame with doc_id, coder_id, start, end.

# load data
annotations <- read.csv(here::here("data","raw","actor_test.csv"))

# shortly inspect
# annotations |> glimpse()

#' Relevant Data Structure:
#' - unit_id     ID of document
#' - coder_id    ID of coder
#' - offset      start position
#' - length      length of the match

# prepare data frame
df <-
  annotations |>
  mutate(end = offset + length - 1) |>
  select(
    coder_id,
    doc_id = unit_id,
    start = offset,
    end
  )

# compute metrics
res <- 
  df |>                                 
  group_split(doc_id, .keep = TRUE) |> 
  purrr::map_dfr(score_doc, .progress = TRUE)

# visualise metrics
res |>
  tidyr::pivot_longer(
    cols = c(iaa_exact, iaa_relaxed),
    names_to = "type",
    values_to = "value"
  ) |>
  ggplot(aes(x = "", y = value, fill = type)) +
  geom_violinhalf(alpha = 0.6, color = "transparent") +
  stat_summary(
    aes(group = type, yintercept = after_stat(y)),
    fun = mean,
    geom = "hline",
    linetype = "dashed"
  ) +
  labs(
    title = "Inter-Annotator Agreement Scores",
    fill = "Type of Match",
    x = "",
    y = "IAA Score"
  ) +
  coord_flip() +
  facet_wrap(~ type, ncol = 1, scales = "free") +
  theme_minimal()


