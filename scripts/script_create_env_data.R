# Objetive ---------------------------------------------------------------------
# Combine soil macro and micro climatic data into single data frame
here::i_am('data_analysis/scripts/script_create_env_data.R')

# Load packages ----------------------------------------------------------------
library(dplyr)
library(janitor)
# For column to row function
library(tibble)
# For pivot
library(tidyr)
# For working with strings
library(stringr)

# Load raw data ----------------------------------------------------------------

# Macro env
macroclim_soil_env_data <-
    readxl::read_xlsx("./data/raw_data/raw_plot_enviroment.xlsx", sheet = 2) %>%
    clean_names()


# Check differences between datasets -------------------------------------------

# Clean data -----------------------------------------------------------------
env_data <-
    macroclim_soil_env_data %>%

        mutate(tempmin = tempmin/10,
               temp = temp/10,
               tempsd = tempsd/100,

               # Round to 3 decimal points
               slope_deg = round(slope_deg, 3),
               slope_per = round(slope_per, 3)) %>%

        # Remove spaces and points
        mutate(across(where(is.character), str_replace_all, pattern = ". ",
                  replacement = "_"))  %>%
        clean_names() %>%
        arrange(plot) %>%

        # Remove features
        dplyr::select(-c(forest_type, tempmin, slope_deg, limo, precdriest)) %>%

        # Remove last row with NAs
        na.omit()

# Save data --------------------------------------------------------------------
write.csv(env_data, "./data/cleaned_data/env_data.csv")
