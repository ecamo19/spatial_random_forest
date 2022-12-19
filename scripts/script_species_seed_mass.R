# Objetive ---------------------------------------------------------------------

# Load packages ----------------------------------------------------------------
library(dplyr)
library(janitor)
# For column to row function
library(tibble)
# For pivot 
library(tidyr)
# For datasets differences
library(diffdf)
library(stringr)

# Load raw data ----------------------------------------------------------------
# Letcher
raw_traits_letcher <- 
    as_tibble(read.csv("./data/raw_data/response_traits/original_raw_data_files/data_seed_lenght_original.csv",
                       header = T, na.strings = "NA")) %>% 
        clean_names()

# TRY
raw_trydb_traits <-
    read.delim("./data/raw_data/response_traits/species_traits.txt", header = T) %>% 
    clean_names()

# BIEN
raw_biendb <- 
    read.csv("./data/raw_data/data_from_bien_database_wet_forest.csv", header = T) %>% 
        clean_names()

# MY Spcodes
spcodes <- 
    read.csv("./data/data_for_analisys/response_traits.csv", header = T) %>% 
    dplyr::select(2:4) %>%
    arrange(spcode) %>% 
    separate(accepted_species,c("gen","sp")) %>% 
    mutate(across(where(is.character), str_to_lower)) %>% 
    
    # Remove morpho species
    filter(!(str_detect(sp, "^sp") & (str_length(sp) <= 4)))


# Seed mass data from letcher --------------------------------------------------
seed_mass_letcher <- 
    raw_traits_letcher %>% 
    
    dplyr::select(1:3,6)  %>% 
    
    # Tranform 
    mutate(seedmass_mg = as.numeric(seedmass_mg)) %>%  
    
    # Select seed_length traits
    mutate(across(where(is.character), str_to_lower)) %>% 
    
    # select only wet forests based on Letcher et al table
    # https://besjournals.onlinelibrary.wiley.com/doi/full/10.1111/1365-2745.12435
    filter(site %in% c("osa","car","bra","pan","chj","luq", "sar" )) %>% 
    
    # Remove species with no traits seedlength_mm
    filter(!if_all(c(seedmass_mg), ~ is.na(.))) %>% 
    
    # Remove duplicates
    unite(name,c("gen","sp"), sep = " ", remove = FALSE)  %>% 
    
    # Species mean wet forest
    group_by(name, gen, sp) %>% 
    summarize(seed_mass = mean(seedmass_mg)) 

# 301 species with seed mass values from the wet forest 

## How many of my species are in letcher? --------------------------------------
species_with_seed_mass_letcher <- 
    inner_join(spcodes, seed_mass_letcher, by = c("gen", "sp"))

# There are 55 of my species in letcher

## Which species have no traits in letcher? ------------------------------------
species_no_seed_mass_135 <- 
    anti_join(spcodes, seed_mass_letcher, by = c("gen", "sp"))

# There are 135 of my species in letcher with no traits

# Seed mass data from TRY ------------------------------------------------------
seed_mass_try <-  
    raw_trydb_traits %>%
        select(-x) %>% 
        gather(specie, number_ind, 3:179) %>% 
        
        #Select trait
        filter(trait %in% c("Seed dry mass")) %>% 
        
        # remove row with  individuals
        filter(number_ind > 0) %>% 
    
        separate(specie, c("genus", "species"), sep = "_") %>% 
        mutate(across(where(is.character), str_to_lower))

# There are 84 species with seed mass values in the TRY database

## How many of my species with no traits are in TRY? ---------------------------
species_with_seed_mass_try <- 
    inner_join(species_no_seed_mass_135, seed_mass_try, by = c("gen" = "genus", 
                                                           "sp" = "species"))

# There are 32 of my species in TRY
# Total 55 + 32

## Which species have no traits in TRY? ----------------------------------------
## species_no_seed_mass_135 
species_no_seed_mass_103 <- 
    anti_join(species_no_seed_mass_135, seed_mass_try, by = c("gen" = "genus", 
                                                              "sp" = "species"))

### Get data from TRY webside -------------------------------------------------- 
# For downloading data from try it is neccesary the species codes of the data
# base and trait codes
# Trait id == 26

# This file was downloaded from TRY and is for getting the species codes, I need
# 32 ids
data_trydb_spcodes <- 

    read.delim("./data/raw_data/response_traits/TryAccSpecies.txt", header = T) %>% 
        clean_names() %>% 
        mutate(across(where(is.character), str_to_lower)) %>% 
        select(acc_species_id, acc_species_name)
     
# This is the infor that I need for getting the trait data
species_with_seed_mass_try %>% 
    unite(name, c("gen", "sp"), sep = " ", remove = FALSE) %>% 
    
    inner_join(., data_trydb_spcodes, by = c("name" = "acc_species_name")) %>% 
    select(trait_id, acc_species_id) 


# Seed mass data from BIEN -----------------------------------------------------
seed_mass_bien <- 
    raw_biendb %>% 
    filter(trait_name == "seed mass") %>% 
    select(c(id,scrubbed_species_binomial, trait_name, trait_value,unit,
             project_pi_contact))  %>% 
    group_by(scrubbed_species_binomial) %>% 
    
    summarise(mean_seed_mass_mg = mean(as.numeric(trait_value)),
              n = n()) %>% 
    separate(scrubbed_species_binomial, c("genus", "species"), sep = " ") %>% 
    mutate(across(where(is.character), str_to_lower)) %>% 
    arrange(genus)

## How many of my species with traits are in BIEN? -----------------------------

seed_mass_3_bien <-  
    inner_join(species_no_seed_mass_103, seed_mass_bien, by = c("gen" = "genus",
                                                            "sp" = "species"))
# 3 species with seed mass values in BIEN

## Which species have no traits in BIEN? ---------------------------------------
anti_join(species_no_seed_mass_103,seed_mass_bien, by = c("gen" = "genus",
                                                          "sp" = "species"))

# 100 species have no seed mass data


# Join the 3 datasets ----------------------------------------------------------
# 90 species have seed mass 
seed_mass_3_bien
species_with_seed_mass_letcher
#species_with_seed_mass_try # Look zip file seed_mass_32_sp

