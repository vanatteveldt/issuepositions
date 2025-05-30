# Calculate intercoder reliablity for the annotation of actors for the second part of the project
# i.e., beyond just political actors
# We calculate two measures: 
# - do annotators identify the same actors?  --> done in this script
# - do the annotators agree on which category an actor belongs to?  --> done in get_iaa_metrics.R (by Philipp Mendoza)



library(tidyr)
library(irr)
library(tidyverse)
library(here)

results = read_csv(here::here("data/raw/actor_test.csv"))
cleaned <- results |>  select(text, coder, value)

# We want to have one row per entity, one column per coder
# However, the same actor may occur multiple times (hence, is not unique and can be coded multiple times)
# Manual inspectation showed that none of the coders did not change their mind (hence, intra-coder reliability is (almost) perfect)
# We therefore just take the *first* coding of an actor, in case the actor is coded multiple times. 

wide <- cleaned |>
  pivot_wider(names_from = coder, values_from = value, values_fn = first)


## Some wrangling to please the IRR package and get the reliabilities.
wide <- wide[, -1]
wide[ , -1] <- lapply(wide[ , -1], as.character)
alpha_input <- as.matrix(wide)
irr::kripp.alpha(t(alpha_input), method = "nominal")
irr::kappa2(alpha_input)

print("For illustration purposes, let's calculate what would happen if actors that are overlooked by one annotator would be coded as 'wrong'.")
print("To be clear, this is not a useful measure, but it illustrates the important of also checking wether the actors are idenified.")
wide_narep = wide |>  mutate_all(coalesce, "overhethoofdgezien") 
alpha_input_narep <- as.matrix(wide_narep)
irr::kripp.alpha(t(alpha_input_narep), method = "nominal")
irr::kappa2(alpha_input_narep)



