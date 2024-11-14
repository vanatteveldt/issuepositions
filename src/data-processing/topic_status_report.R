library(irr)
library(ggplot2)

gpt_issues_all <- read_csv("data/intermediate/gpt_issues_all.csv")
gpt_issues_all |> filter(logprob >= -5)

all_coded_units <- read_csv("data/intermediate/coded_units.csv")

# # Identify the abbreviations of coders that are present in all_units
present_coders <- intersect(CODERS$abbrev, names(all_coded_units))

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


overall_kripp_alpha <- alpha(all_units_numeric)

pairwise_kripp_alpha <- pairwise_alpha_new(all_units_numeric)

print(overall_kripp_alpha)

print(pairwise_kripp_alpha)


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


plot_pairwise_kripp_alpha(pairwise_kripp_alpha)


# create topic info table

# count units per topic coded


topic_count <- function(df, topic_name){
  # count number of rows containing a topic
  return (nrow(df[df$topic == topic_name,]))
}

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
  topic_info = tibble(topic_name = character(), completed_count = numeric(), total_count = numeric(), reliability = numeric())
  
  for (topic_name in unique(all_units_numeric$topic)) {
    completed_count <- topic_count(df, topic_name)
    total_count <- topic_count(total_df, topic_name)
    topic_alpha <- topic_alpha(df, topic_name)
    
    topic_info <- topic_info |>
      add_row(topic_name=topic_name, completed_count=completed_count, total_count=total_count, reliability=topic_alpha) |>
      mutate(percentage_done = 100*completed_count/total_count)
    
  }
  return(topic_info)
}

topic_info = topic_status(all_units, gpt_issues_all)
print(topic_info)

no_agreement_units <- all_coded_units |>
  filter(agreement < 1) |>
  arrange(topic, unit_id)



