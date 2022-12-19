# Objective --------------------------------------------------------------------
# Compare species list with TNRS to get the correct species names


# Load packages ----------------------------------------------------------------
library(purrr)
library(dplyr)
library(readr)
# For taxonomic names
#devtools::install_github('https://github.com/EnquistLab/RTNRS')
library(TNRS)

# Load species list ------------------------------------------------------------
species_list <- read.csv("./data/cleaned_data/species_list.csv") %>%
        select(-X)

# Taxonomic Name Resolution Service --------------------------------------------

## Function for making the call to BIEN database -------------------------------

tnrs_names <- function(genus,sp){

    # Format species name
    name <- paste0(str_to_title(genus), " ", sp)

    # Make the call to the database
    return(TNRS::TNRS(taxonomic_names = name))
}


## Clean data ------------------------------------------------------------------

species_list_no_morpho <-

    species_list %>%

        # Remove morphospecies
        filter(!(str_detect(especie, "^sp") & (str_length(especie) <= 4)))


# Test single name -------------------------------------------------------------

tnrs_names(species_list_no_morpho[2,]$genero,
           species_list_no_morpho[2,]$especie)


## Iterate  --------------------------------------------------------------------
tnrs_names <- map2_dfr(.x = species_list_no_morpho$genero,
                       .y = species_list_no_morpho$especie,
                       .f = tnrs_names)


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
    mutate(name_used =  if_else(Name_submitted != Accepted_species, Accepted_species, Name_submitted))


# Save data --------------------------------------------------------------------
write_csv(tnrs_names, "./data/cleaned_data/tnrs_names.csv", col_names = TRUE)

