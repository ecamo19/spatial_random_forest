# Objective --------------------------------------------------------------------
# This script takes all the raw files contaning the traits and creates a dataset
# called traits_db

here::i_am("data_analysis/scripts/trait_db_contruction.R")
setwd(here::here())


# Load Packages ----------------------------------------------------------------
library(janitor)
library(dplyr)
# For tables
library(reactable)
# For pivot function
library(tidyr)
# For reading html files
library(rvest)
# For pluck function
library(purrr)
# For read xls files
library(readxl)
# For working with names
library(stringr)
# For converting pdf to data
library(tabulizer)
# For adding columns
library(tibble)
# For wood density estimation
library(BIOMASS)

# Species list -----------------------------------------------------------------
species_list <- read.csv("./data/cleaned_data/species_list.csv") %>%
        select(-X)


## Full species list -----------------------------------------------------------

# Create spcode with the first 4 characters from the genus and the first 2
# from species

species_list <-

    species_list %>%

        # Step done if mophospecies name == sp get it,
        # elif mophospecies name == sp{:digit:} get the 4 characters i.e sp01
        mutate(gen4 = str_extract(genero, "^.{4}"),
                sp3 = if_else(str_length(especie) == 2, str_extract(especie, "^.{2}"),
                             if_else((str_length(especie) > 2) & (str_length(especie) <= 4) & (str_detect(especie, "^sp")),
                                     str_extract(especie, "^.{4}"), str_extract(especie, "^.{3}")))) %>%

        unite(spcode_4_3, c("gen4","sp3"), sep = "") %>%
        arrange(spcode)




