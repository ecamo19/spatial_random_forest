# Objetive ---------------------------------------------------------------------
# Estimate the abovegorund biomass of each plot using the biomass R package

# Load packages ----------------------------------------------------------------
library(BIOMASS)
library(dplyr)
library(readxl)

# Load data --------------------------------------------------------------------
basal_area_wide <- 
    read_excel('./data/raw_data/abundancia_aboveground_biomass_data/data_basal_area_sp_parcela.xlsx', sheet = 2)



