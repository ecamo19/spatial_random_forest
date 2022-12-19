# Objective --------------------------------------------------------------------
# This script takes all the raw files contaning the traits and creates a dataset
# called traits_db

here::i_am("data_analysis/scripts/data_cleaned.R")
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
source("./scripts/script_full_species_list.R")


## Full species list -----------------------------------------------------------

# Create spcode with the first 4 characters from the genus and the first 2
# from species

data_species_full_list <-

    data_species_full_list %>%

        # This step is done for when mophospecies is sp get it and if it is sp
        # get that 4 characters
        mutate(gen4 = str_extract(genero, "^.{4}"),
                sp3 = if_else(str_length(especie) == 2, str_extract(especie, "^.{2}"),
                             if_else((str_length(especie) > 2) & (str_length(especie) <= 4) & (str_detect(especie, "^sp")),
                                     str_extract(especie, "^.{4}"), str_extract(especie, "^.{3}")))) %>%

        unite(spcode_4_3, c("gen4","sp3"), sep = "") %>%
        arrange(spcode)



