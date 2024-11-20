library(irr)
library(ggplot2)
library(readr)

gpt_issues_all <- read_csv("data/intermediate/gpt_issues_all.csv") |>
  filter(logprob >= -5)

all_units <- read_csv("data/intermediate/coded_units.csv")

# # Identify the abbreviations of coders that are present in all_units
present_coders <- intersect(CODERS$abbrev, names(all_units))

# # Convert only the columns for the present coders to numeric values
all_units_numeric <- all_units |> 
  mutate(across(all_of(present_coders), ~ as.numeric(factor(.))))

# Overall Reliability calculation
alpha <- function(all_units_numeric) {
  select(all_units_numeric, all_of(present_coders)) |>
    # Prepare numeric data as a matrix for Krippendorff calculation
    as.matrix() |>
    t() |>
    irr::kripp.alpha(method="nominal")
}

# Pairwise reliability
pairwise_alpha_new <- function(all_units_numeric) {
  coders <- present_coders
  result <- tibble(coder1 = character(), coder2 = character(), alpha = numeric())
  
  for (i in 1:(length(coders) - 1)) {
    for (j in (i + 1):length(coders)) {
      coder1 <- coders[i]
      coder2 <- coders[j]
      
      
      # Filter data to include only coder columns
      sub_data <- all_units_numeric |>
        select(all_of(c(coder1, coder2))) |>
        na.omit()
      
      # Check if there are enough data points for calculation
      if (nrow(sub_data) > 1) {
        
        # Calculate Krippendorff's alpha for the pair
        tryCatch({
          alpha_value <- irr::kripp.alpha(t(as.matrix(sub_data)), method = "nominal")
          # Store results
          result <- result |>
            bind_rows(tibble(coder1 = coder1, coder2 = coder2, alpha = alpha_value$value))
        }, error = function(e) {
          message("Error calculating alpha for ", coder1, " and ", coder2, ": ", e$message)
        })
      } else {
        message("Insufficient data for calculating alpha between ", coder1, " and ", coder2)
      }
    }
  }
  
  return(result)
}


#plotting reliability values between coders

plot_pairwise_kripp_alpha <- function(pairwise_kripp_alpha) {
  # Convert coder columns to factors to ensure correct plotting order
  pairwise_kripp_alpha <- pairwise_kripp_alpha %>%
    mutate(coder1 = factor(coder1, levels = unique(c(coder1, coder2))),
           coder2 = factor(coder2, levels = unique(c(coder1, coder2))))
  
  # Plot heatmap
  ggplot(pairwise_kripp_alpha, aes(x = coder1, y = coder2, fill = alpha, label=round(alpha,2))) +
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



# create topic info table

# count units per topic coded

topic_alpha <- function(df, topic_name) {
  all_units_numeric <- mutate(df, across(all_of(present_coders), ~ as.numeric(factor(.))))
  result <- all_units_numeric[all_units_numeric$topic == topic_name, ] |>
  select(all_of(present_coders)) |>
    # Prepare numeric data as a matrix for Krippendorff calculation
    as.matrix() |>
    t() |>
    irr::kripp.alpha(method="nominal") 
  return(result$value)
}


topic_status <- function(df, total_df){
  topic_info <- tibble(topic_name = character(), completed_count = numeric(), total_count = numeric(), percentage_done = character(), reliability_α = numeric())  # Initialize as character to hold the formatted percentage
  
  total_counts <- total_df |> 
    group_by(topic) |> 
    summarize(total_count=length(unique(unit_id))) |> 
    na.omit()
  completed_count <- df |> 
    group_by(topic) |> 
    summarize(completed_count=length(unique(unit_id))) |> 
    na.omit()
  
  alphas <- completed_count |> 
    pull(topic) |> 
    unique() |>
    map(function(topic) tibble(topic=topic, alpha=topic_alpha(df, topic)), .progress = T) |>
    list_rbind()
  
  left_join(total_counts, completed_count) |>
    replace_na(list(completed_count=0)) |>
    mutate(percentage_done = str_c(round(100*completed_count/total_count), "%")) |>
    left_join(alphas) 
}

overall_kripp_alpha <- alpha(all_units_numeric)

pairwise_kripp_alpha <- pairwise_alpha_new(all_units_numeric)

plot_pairwise_kripp_alpha(pairwise_kripp_alpha)

topic_info <- topic_status(all_units, gpt_issues_all)

print(topic_info)