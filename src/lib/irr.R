library(tidyverse)

dotenv::load_dot_env()
coders_json = Sys.getenv("CODERS")
CODERS <- jsonlite::fromJSON(coders_json) |> as_tibble()

# Compute overall reliability for this dataset, possibly filtering on specific coders
alpha <- function(data, coders = CODERS) {
  data <- data |>
    select(all_of(coders)) |>  
    filter(rowSums(!is.na(pick(everything()))) >= 2) # keep only rows with at least two values
  
  
  if (nrow(data) == 0) return(NULL)
  data |> 
    as.matrix() |>
    t() |>
    irr::kripp.alpha(method="nominal") |>
    pluck("value")
}

#' Compute pairwise reliability for a data set
pairwise_alpha <- function(data) {
  result <- tibble(coder1 = character(), coder2 = character(), alpha = numeric())
  
  expand_grid(coder1=CODERS, coder2=CODERS) |>
    filter(coder1 > coder2) |>
    pmap(function (coder1, coder2) 
      tibble(coder1=coder1, 
             coder2=coder2, 
             alpha=alpha(coded_units, c(coder1, coder2)))) |>
    list_rbind()
}


#' Plot pairwise alpha as tiles
plot_pairwise_alpha <- function(pairwise_alpha) {
  # Convert coder columns to factors to ensure correct plotting order
  ##pairwise_alpha <- pairwise_alpha |>
  ##  mutate(coder1 = factor(coder1, levels = unique(c(coder1, coder2))),
  #       coder2 = factor(coder2, levels = unique(c(coder1, coder2))))
  
  # Plot heatmap
  ggplot(pairwise_alpha, aes(x = coder1, y = coder2, fill = alpha, label=round(alpha,2))) +
    geom_tile(color = "white") +
    geom_text(color = "white") +
    scale_fill_gradient2(low = "darkred", high = "darkgreen", mid = "gold", midpoint = 0.5,
                         name = "Krippendorff's Alpha") +
    labs(title = "Pairwise Krippendorff's Alpha Between Coders",
         x = "",
         y = "") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "none") +
    coord_fixed()
}