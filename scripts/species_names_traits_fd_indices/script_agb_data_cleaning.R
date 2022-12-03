# Objetive ---------------------------------------------------------------------

# Load packages ----------------------------------------------------------------
library(dplyr)
library(janitor)
# For column to row function
library(tibble)
# For pivot 
library(tidyr)

# Load raw data ----------------------------------------------------------------

## AGB data --------------------------------------------------------------------
raw_agb_data <- 
    readxl::read_xlsx("./raw_data/abundancia_aboveground_biomass_data/data_AB_sp_parcela.xlsx",
                      sheet = 2) %>% 
    
        # Remove last row 
        slice(1:127) %>% 
        clean_names() %>%
        
        # Remove species
        select(-c("brospa", "hirtme", "ruptca","quetoc", "maytgu" ))

## Read trait data to get new spcodes ------------------------------------------
traits <- 
    read.csv("./data_for_analisys/traits_data.csv", header = T) %>% 
        select(-X)

### Get spcodes from trait dataset --------------------------------------------- 
spcodes_traits_only <- 
    traits %>% 
        select(1:3) %>%
        arrange(spcode)

# Clean data -------------------------------------------------------------------
data_agb_long <- 
    raw_agb_data %>%
        # Change to long format
        pivot_longer(!parcela, names_to = "spcode", values_to = "agb") 
        
# Test -------------------------------------------------------------------------
data_agb_long %>% 
    anti_join(.,spcodes_traits_only, by = "spcode")

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
