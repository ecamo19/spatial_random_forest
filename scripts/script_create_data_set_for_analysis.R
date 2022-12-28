# Objective ---------------------------------------------------------------------
# Gather all necessary data sets for creating a single one called
# data_set_for_stats

here::i_am("scripts/script_create_data_set_for_analysis.R")

# Load packages -----------------------------------------------------------------
library(dplyr)
library(janitor)

# Load data sets ----------------------------------------------------------------

env_data <-
    read.csv("./data/cleaned_data/env_data.csv") %>% select(-X)

plots_lat_long <-
    read.csv("./data/cleaned_data/plots_long_lat_wgs84.csv") %>%
    select(-X) %>%
    clean_names()

plot_agb <-
    read.csv("./data/cleaned_data/plot_agb.csv") %>% select(-X)


redundancy_and_functional_diversity <-
    read.csv("./data/cleaned_data/redundancy_and_functional_diversity.csv") %>%
        dplyr::select(-X)

# Join data ---------------------------------------------------------------------
data_for_analysis <-
    inner_join(plots_lat_long, env_data,
                by = c("plot","crtm_90_x", "crtm_90_y")) %>%

        # Add agb
        inner_join(., plot_agb,  by = "plot") %>%

        # Add indices
        inner_join(., redundancy_and_functional_diversity, by = "plot") %>%

        # Arrange and remove columns
        select(plot, x_wgs84, y_wgs84, AGB, n, u, redundancy, f_dis,everything(),
                -c(crtm_90_y,crtm_90_x, d, q, u, rao_q, f_eve, p_h)) %>%
        rename(n_species = n)

# Save data ---------------------------------------------------------------------
write.csv(data_for_analysis, "./data/cleaned_data/data_for_analysis.csv")

# Clean env at the end ----------------------------------------------------------
rm(list = ls())