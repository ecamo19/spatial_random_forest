# Objetive ---------------------------------------------------------------------
# Estimate the abovegorund biomass of each plot using the biomass R package

here::i_am("data_analysis/scripts/script_get_agb_data.R")

# Load packages ----------------------------------------------------------------
library(dplyr)
library(janitor)
# For column to row function
library(tibble)
# For pivot
library(tidyr)
# For calculate Aboveground Biomass
library(BIOMASS)
# For reading .xlsx file
library(readxl)

# Load data --------------------------------------------------------------------
basal_area_wide <-
    read_excel("./data/raw_data/raw_species_basal_area.xlsx", sheet = 2)  %>%

        # Remove last row, for some reason read_excel imports a row filled with
        # NAs
        slice(1:127) %>%
        clean_names() %>%

        # Remove species
        select(-c("brospa", "hirtme", "ruptca", "quetoc", "maytgu"))

plot_lat_lon <- read.csv("./data/cleaned_data/lat_long_plots.csv")

## Read species list ----------------------------------------------------------
species_list_255 <-
    read.csv("./data/cleaned_data/species_list_updated.csv", header = TRUE) %>%
        select(-X)

# Clean data -------------------------------------------------------------------
basal_area_dbh_long <-
    basal_area_wide %>%

        # Change to long format
        pivot_longer(!parcela, names_to = "spcode",
                        values_to = "basal_area_m2_ha") %>%

        # Get DBH from Basal area
        # Basal area m2_ha = (pi * (DBH/2)^2)/10000
        # DBH cm = 2 * sqrt(BA*10000/pi)
        mutate(dbh_cm = 2 * sqrt(10000 * basal_area_m2_ha / pi))


# Join basal area with species names
inner_join(species_list_255, basal_area_dbh_long, by = "spcode") %>%
    ## add plot lat-lon



