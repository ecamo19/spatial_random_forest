# Objetive ---------------------------------------------------------------------
# Remove species that will not be considered in the analisys

here::i_am('data_analysis/scripts/script_clean_species_abundance_data.R')


# Load packages ----------------------------------------------------------------
library(dplyr)
library(janitor)
# For column to row function
library(tibble)
# For pivot
library(tidyr)

# Load data ---------------------------------------------------------------------

## Species list
species_list <- read.csv("./data/cleaned_data/species_list_updated.csv",
                            header = TRUE) %>%
                select(-X)

## Abundance data --------------------------------------------------------------
raw_abund_data <-
    readxl::read_xlsx("./data/raw_data/raw_species_abundance.xlsx", sheet = 2)

species_abundance <-
    raw_abund_data %>%
        clean_names() %>%

        # Remove species
        select(-c("brospa", "hirtme", "ruptca", "quetoc", "maytgu"))


# Clean data -------------------------------------------------------------------
data_abund_long <-
    species_abundance %>%
        # Change to long format
        pivot_longer(!parcela, names_to = "spcode", values_to = "abundance")

# Check which species in the species list are not in the abundance dataset ------
anti_join(data_abund_long, species_list, by = "spcode")

# Join datasets ----------------------------------------------------------------
species_abundance_data <-
    inner_join(species_list, data_abund_long, by = "spcode") %>%
        select(parcela, spcode, abundance) %>%
        arrange(spcode) %>%
        pivot_wider(names_from = spcode, values_from = abundance)

# Save data ---------------------------------------------------------------------
write.csv(species_abundance_data, "./data/cleaned_data/species_abundance_data.csv")

# Clean env at the end ----------------------------------------------------------
rm(list = ls())