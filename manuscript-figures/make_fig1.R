# Figure 8.1: Precision-recall curve of LLM-based pre-coding
#
# Computation copied verbatim from src/data-processing/12_gpt_issues_evaluate.R
# (the `choices` / `metrics` / `roc` part); only the plot styling differs:
#  - no in-figure title (the book caption replaces it)
#  - sized for a 5in-wide book page, all text >= 8pt
#  - greyscale, gridlines dark enough to survive printing, lines >= 0.5pt
#
# Run from the repository root:  Rscript --no-init-file manuscript-figures/make_fig1.R
# (--no-init-file skips the project's renv, which lacks svglite; needs tidyverse + svglite
#  in the user library, and inkscape + python3/PIL on the PATH)

library(tidyverse)

d <- read_csv("data/intermediate/gpt_issues_gold_325.csv", show_col_types = FALSE) |>
  replace_na(list(topic = "None"))

choices <- d |>
  filter(response != "Onder") |>
  select(unit_id, gold, topic, rank, logprob) |>
  mutate(correct = topic == gold,
         gold_none = if_else(gold == "None", "None", "Issue")) |>
  arrange(unit_id, rank) |>
  group_by(unit_id) |> mutate(rank2 = row_number()) |> ungroup()

metrics <- function(logprob_threshold) {
  n_actual <- choices |> filter(gold != "None", rank == 0) |> nrow()
  choices |>
    filter(topic != "None") |>
    filter(logprob >= logprob_threshold) |>
    summarize(logprob = logprob_threshold, n_actual = n_actual, n_positives = n(), tp = sum(correct)) |>
    mutate(pr = tp / n_positives,
           re = tp / n_actual,
           f1 = 2 * pr * re / (pr + re),
           f3 = 10 * pr * re / (9 * pr + re))
}

roc <- map(-1:-20, metrics) |> list_rbind() |>
  mutate(label = glue::glue("lp≥−{abs(logprob)}; n={n_positives}; F3={sub('^0', '', sprintf('%.2f', f3))}"))  # true minus sign, no leading zero

print(roc |> select(logprob, n_positives, tp, pr, re, f3), n = 20)

# ---------------------------------------------------------------- plot
txt <- 8 / .pt  # geom_text size (mm) for 8pt text
# linewidths: ggplot linewidth 1 is ~2.13pt, so 0.25 ~ 0.53pt (>= 0.5pt minimum)

p <- ggplot(roc, aes(x = pr, y = re, label = label)) +
  geom_line(linewidth = 0.4) +
  geom_point(size = 1.1) +
  # thresholds -1..-3: label to the left of the point
  geom_text(data = filter(roc, logprob >= -3), hjust = 1, nudge_y = -.002, nudge_x = -.01, size = txt) +
  # -4..-9: angled labels above the curve (parallel, so they do not collide)
  geom_text(data = filter(roc, logprob <= -4, logprob > -10),
            hjust = 0, nudge_y = .002, nudge_x = .006, angle = 45, size = txt) +
  # -10..-15: vertical labels below the curve (as in the original; -16 and lower fall off the axis)
  geom_text(data = filter(roc, logprob <= -10, logprob >= -16),
            hjust = 1, nudge_y = -.002, nudge_x = -.01, angle = 90, size = txt) +
  xlab("Precision") + ylab("Recall of non-None issues") +
  scale_y_continuous(limits = c(.85, 1)) +
  scale_x_continuous(limits = c(.3, .9), breaks = seq(.3, .9, .1)) +
  theme_minimal(base_size = 9, base_family = "Liberation Sans") +
  # grey80 = 20% tint, the lightest T&F allow; 0.25 ~ 0.53pt (>= 0.5pt minimum)
  theme(panel.grid.major = element_line(colour = "grey80", linewidth = 0.25, linetype = "22"),
        panel.grid.minor = element_blank(),
        axis.text = element_text(colour = "black", size = 8),
        axis.title = element_text(colour = "black", size = 9))

# Export via SVG + Inkscape rather than cairo_ps/cairo_pdf: the cairo devices round glyph
# advances to whole points, which gives visibly uneven letter spacing at 8-9pt.
out <- "manuscript-figures"
svg <- file.path(out, "fig1.svg")
ggsave(svg, p, device = svglite::svglite, width = 5, height = 3.6, units = "in", bg = "white")
ink <- function(...) {
  status <- system2("inkscape", c(shQuote(svg), ...), stdout = FALSE, stderr = FALSE)
  if (status != 0) stop("inkscape export failed")
}
ink("--export-type=eps", "--export-text-to-path", paste0("--export-filename=", shQuote(file.path(out, "Figure 8.1.eps"))))
ink("--export-type=pdf", "--export-text-to-path", paste0("--export-filename=", shQuote(file.path(out, "Figure 8.1.pdf"))))
png <- file.path(out, "fig1_1200.png")
ink("--export-type=png", "--export-dpi=1200", "--export-background=white", "--export-background-opacity=1",
    paste0("--export-filename=", shQuote(png)))
# greyscale 1200 dpi TIFF from the Inkscape render
system2("python3", c("-I", "-c", shQuote(paste0(
  "from PIL import Image; Image.MAX_IMAGE_PIXELS=None; ",
  "Image.open('", png, "').convert('L').save('", file.path(out, "Figure 8.1.tif"),
  "', dpi=(1200,1200), compression='tiff_lzw')"))))
file.remove(png, svg)
