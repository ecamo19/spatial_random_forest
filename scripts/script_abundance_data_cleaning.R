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

# Load raw data ----------------------------------------------------------------
## Trait data to get new spcodes -----------------------------------------------
source("./scripts/script_effect_traits_data_cleaning.R")

## Abundance data --------------------------------------------------------------
raw_abund_data <- 
    readxl::read_xlsx("./data/raw_data/abundancia_aboveground_biomass_data/data_ABUND_sp_parcela.xlsx",
                      sheet = 2) %>% 
    
        clean_names() %>% 
    
        # Remove species
        select(-c("brospa", "hirtme", "ruptca","quetoc", "maytgu" ))

print(paste0("raw_abund_data has: ", dim(raw_abund_data)[1]," plots and ", 
             dim(raw_abund_data)[2], " species"))


## Get spcodes from trait dataset --------------------------------------------- 
spcodes <- 
    data_effect_traits %>% 
        select(1:3) %>% 
        arrange(spcode)

# spcodes == 255

# Clean data -------------------------------------------------------------------
data_abund_long <- 
    raw_abund_data %>%
        # Change to long format
        pivot_longer(!parcela, names_to = "spcode", values_to = "abundance") 
        
# Test -------------------------------------------------------------------------
data_abund_long %>% 
    anti_join(.,spcodes, by = "spcode")

# spcode and data_abund_long equal if 0

## Double check spcodes --------------------------------------------------------
data_abund_long %>% 
    distinct(spcode) %>%   
    cbind(., spcodes) %>% 
    rename(sp1 = "spcode") %>%
    
    # Compare if the names are the same
    mutate(all_true = if_else(all(sp1 == spcode) , "all_fine", "different_codes")) %>% 
    
    # Return the code names that are different
    filter(if_any("all_true", ~ . == "different_codes"))

# Join datasets ----------------------------------------------------------------
data_abundance_4_3_spcodes <- 
    inner_join(spcodes, data_abund_long, by = "spcode") %>% 
        select(parcela, spcode_4_3 , abundance)  %>% 
        arrange(spcode_4_3) %>%
        pivot_wider(names_from = spcode_4_3, values_from = abundance)
    
## Compare original and new datasets -------------------------------------------

### Janitor test ---------------------------------------------------------------
print(paste0(" Janitor test, Any mismatch btw raw and new dataset? ",
             compare_df_cols(data_abundance_4_3_spcodes,raw_abund_data, 
                             return = "mismatch")))

print(paste0(" Janitor test, equal raw and new dataset? ", 
             compare_df_cols_same(data_abundance_4_3_spcodes,raw_abund_data)))

### Remove colnames and just compare values ------------------------------------
data_new <- data_abundance_4_3_spcodes[,1:ncol(data_abundance_4_3_spcodes)]
names(data_new) <- NULL

data_original <- raw_abund_data[,1:ncol(raw_abund_data)]
names(data_original) <- NULL

print(paste0("Same dimmenstions btw raw and new dataset? ",
             dim(data_new) == dim(data_original)))

#print(paste0("all equal raw and new dataset? ", 
#             all_equal(data_new, data_original)))

## Check differences -----------------------------------------------------------
#diffdf(data_original,data_new)

# Remove all variables except new data -----------------------------------------

rm(list = c("data_abund_long","data_effect_traits", "data_new", "data_original",
            "raw_abund_data", "spcodes"))


cat(crayon::blue(paste0("\nData set available: ", ls())))
