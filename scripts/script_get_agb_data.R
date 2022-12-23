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


## Read species list ----------------------------------------------------------
species_list_257 <-
    read.csv("./data/cleaned_data/species_list.csv", header = TRUE) %>%
        select(-X)


# Clean data -------------------------------------------------------------------
basal_area_long <-
    basal_area_wide %>%

        # Change to long format
        pivot_longer(!parcela, names_to = "spcode",
                        values_to = "basal_area_m2_ha")

# Test -------------------------------------------------------------------------
basal_area_long %>%
    anti_join(., species_list_257, by = "spcode")

## Double check spcodes --------------------------------------------------------
data_agb_long %>%
    distinct(spcode) %>%
    cbind(., spcodes_traits_only) %>%
    rename(sp1 = "spcode") %>%
    mutate(same = if_else(sp1 == spcode, TRUE, FALSE)) %>%
    filter(if_any("same", ~ . == FALSE))

# Join datasets ----------------------------------------------------------------
data_agb_new_spcodes <-
    inner_join(spcodes_traits_only, data_agb_long, by = "spcode") %>%
        select(parcela, spcode_4_3 , agb)  %>%
        arrange(spcode_4_3) %>%
        pivot_wider(names_from = spcode_4_3, values_from = agb)

## Compare original and new datasets -------------------------------------------

# Janitor test
print(paste0(" Janitor test, Any mismatch btw raw and new dataset? ",
             compare_df_cols(data_agb_new_spcodes,raw_agb_data,
                             return = "mismatch")))

print(paste0(" Janitor test, equal raw and new dataset? ",
             compare_df_cols_same(data_agb_new_spcodes,raw_agb_data)))

# Remove colnames and just compare values
data_new <- data_agb_new_spcodes[,1:ncol(data_agb_new_spcodes)]
names(data_new) <- NULL

data_original <- raw_agb_data[,1:ncol(raw_agb_data)]
names(data_original) <- NULL

print(paste0("Same dimmenstions btw raw and new dataset? ",
             dim(data_new) == dim(data_original)))

print(paste0("all equal raw and new dataset? ",
             all_equal(data_new,data_original)))

# Remove all variables except new data -----------------------------------------
rm(list = ls()[c(1,3:7)])
print(paste0("Data set available: ", ls()))
