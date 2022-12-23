# Objective --------------------------------------------------------------------
# Compare species list with TNRS to get the correct species names
here::i_am("data_analysis/scripts/script_get_tnrs_and_species_list_updated.R")

# Load packages ----------------------------------------------------------------
library(purrr)
library(dplyr)
library(janitor)
library(tidyr)
library(readr)
library(stringr)
#devtools::install_github('https://github.com/EnquistLab/RTNRS')
library(TNRS)

# Load species list ------------------------------------------------------------
species_list <- read.csv("./data/cleaned_data/original_species_list.csv") %>%
        select(-X)

# Taxonomic Name Resolution Service --------------------------------------------

## Function for making the call to BIEN database -------------------------------
source("./R/function_get_tnrs_names.R")

## Clean data ------------------------------------------------------------------

species_list_no_morpho <-

    species_list %>%

        # Remove morphospecies
        filter(!(str_detect(especie, "^sp") & (str_length(especie) <= 4)))


# Test single name -------------------------------------------------------------

get_tnrs_names(species_list_no_morpho[2,]$genero,
           species_list_no_morpho[2,]$especie)


## Iterate  --------------------------------------------------------------------
tnrs_names <- map2_dfr(.x = species_list_no_morpho$genero,
                       .y = species_list_no_morpho$especie,
                       .f = get_tnrs_names)

# Compare names ----------------------------------------------------------------
tnrs_names <-
    tnrs_names %>%

    # Change manually Species' name
    mutate(Accepted_species = if_else((Name_submitted == "Billia colombiana"),"Putzeysia rosea",
                                            if_else(Name_submitted == "Hyeronima oblonga", "Stilaginella oblonga",Accepted_species))) %>%

    # Species' reference manually changed
    mutate(Accepted_name_url = if_else((Name_submitted == "Billia colombiana"),"http://legacy.tropicos.org/Name/15500015",
                                      if_else(Name_submitted == "Hyeronima oblonga", "http://legacy.tropicos.org/Name/12802334", Accepted_name_url))) %>%

    # Create column with the final name used
    mutate(name_used =  if_else(Name_submitted != Accepted_species, Accepted_species, Name_submitted))  %>%

    clean_names()


# Create spcode with the first 4 characters from the genus and the first 3
# letters from species

species_list_new_spcodes <-
    species_list %>%

        # Step done if mophospecies name == sp get it,
        # elif mophospecies name == sp{:digit:} get the 4 characters i.e sp01

        # First get the first 4 letters from the genus
        mutate(gen4 = str_extract(genero, "^.{4}"),

                # get the first 3 letters from the species
                sp3 = if_else(str_length(especie) == 2,
                                        str_extract(especie, "^.{2}"), # nolint

                                        if_else((str_length(especie) > 2) & (str_length(especie) <= 4) & (str_detect(especie, "^sp")), # nolint

                                     # Extract
                                     str_extract(especie, "^.{4}"),

                                     # ELSE
                                     str_extract(especie, "^.{3}")))) %>%

        unite(spcode_4_3, c("gen4", "sp3"), sep = "") %>%
        arrange(spcode)

# Get only the spcodes and names -----------------------------------------------
names_spcodes <-
    species_list_new_spcodes %>%
        mutate(genero = str_to_title(genero)) %>%

        # Create name_submitted column
        unite(name_submitted, c(genero, especie), sep = " ", remove = FALSE) %>%

        # Remove morphospecies
        filter(!(str_detect(especie, "^sp") & (str_length(especie) <= 4))) %>%

        select(-c(genero, especie, familia))

# Add spcodes 4-3 to the TNRS file ---------------------------------------------
tnrs_species_list <-
    tnrs_names %>%
        dplyr::select(-id)  %>%
        inner_join(., names_spcodes, by = "name_submitted") %>%
        dplyr::select(spcode, spcode_4_3, everything())

# Full species list with new spcodes -------------------------------------------
# This list only shows the accepted name and the old name
species_list_updated <-
    tnrs_species_list %>%

        # Species' name manually changed
        mutate(accepted_species = case_when(
            name_submitted == "Billia colombiana" ~ "Putzeysia rosea",
            name_submitted == "Hyeronima oblonga" ~ "Stilaginella oblonga",
            TRUE ~ accepted_species))  %>%

        select(spcode, spcode_4_3, name_submitted, taxonomic_status,
               accepted_species) %>%
        arrange(name_submitted) %>%

        # In this list Brosimum panamense is treat as a different species
        # and is not. Removed
        filter(!name_submitted == "Brosimum panamense",
               !name_submitted == "Hirtella media") %>%

        select(-taxonomic_status)

# Save data --------------------------------------------------------------------
write_csv(tnrs_names, "./data/cleaned_data/tnrs_names.csv", col_names = TRUE)

write_csv(species_list_updated, "./data/cleaned_data/species_list_updated.csv",
                                                                col_names = TRUE)

