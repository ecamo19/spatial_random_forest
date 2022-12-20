here::i_am("scripts/script_get_species_list.R")

# Metadata ---------------------------------------------------------------------
# Results of https://tnrs.biendata.org/

# Load packages ----------------------------------------------------------------
library(dplyr)
library(janitor)
# For read excel files
library(readxl)
# For separate function
library(tidyr)
# For strings
library(stringr)

# Full species list ------------------------------------------------------------

## Read data -------------------------------------------------------------------
raw_data_species_list <-

    read.csv("./data/raw_data/raw_effect_traits.csv",header = T) %>%

    # clean column names
    clean_names()

## Full species list -----------------------------------------------------------

data_species_full_list <-

    # Convert
    as_tibble(raw_data_species_list) %>%
    mutate(spcode = coespec) %>%
    select(familia, genero, especie, spcode) %>%

    # Replace all spaces and dots with _
    mutate(across(where(is.character), str_replace_all, pattern = "[/]",
                       replacement = "_")) %>%

    # Remove points
    mutate(across(where(is.character), str_replace_all, pattern = "[.]",
                  replacement = "")) %>%

    # Set levels to lower case
    mutate(across(where(is.character), str_to_lower))

## Number of species -----------------------------------------------------------
print(paste0("The total number of species (species and morpho-species) is: ",
             dim(data_species_full_list)[1]))


# Save species list  -----------------------------------------------------------
write.csv(data_species_full_list, "./data/cleaned_data/species_list.csv")
