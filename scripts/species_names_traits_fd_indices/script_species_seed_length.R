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

## Read trait data to get spcodes ----------------------------------------------

spcodes_traits_only <- 
    read.csv("./data/raw_data/traits/response_traits/refrence_response_traits.csv", header = T) %>% 
    dplyr::select(2:4) %>% 
    arrange(spcode) %>% 
    separate(accepted_species,c("gen","sp")) %>% 
    mutate(across(where(is.character), str_to_lower)) %>% 
    
    # Remove morpho species
    filter(!(str_detect(sp, "^sp") & (str_length(sp) <= 4)))

## Read Letcher dataset --------------------------------------------------------

raw_traits_letcher <- 
    as_tibble(read.csv("./data/raw_data/traits/response_traits/original_raw_data_files/data_seed_lenght_original.csv",
                       header = T, na.strings = "NA")) %>%
    clean_names()  



## GET FACTOR Seed data length from letcher ------------------------------------

seed_length_factor <- 
        raw_traits_letcher %>% 
            dplyr::select(1:4) %>% 
            
            # Tranform 
            mutate(seedlength_cat = as.factor(seedlength_cat)) %>% 
            
            # Select seed_length traits
            mutate(across(where(is.character), str_to_lower)) %>% 
            
            # select only wet forests based on Letcher et al table
            # https://besjournals.onlinelibrary.wiley.com/doi/full/10.1111/1365-2745.12435
            filter(site %in% c("osa","car","bra","pan","chj","luq", "sar" )) %>% 
          
    
            # Remove species with no traits seedlength_cat 
            filter(!if_all(c(seedlength_cat), ~ is.na(.))) %>%
    
            # Remove duplicates
            unite(name,c("gen","sp"), sep = " ", remove = FALSE) %>% 
            distinct()

# Duplicte spacies
# osa hampea appendiculata
# sar alchornea latifolia            
# 798 species with seed length categorical from sarapiqui or osa 

### Species with data seed length factor in letcher ----------------------------

seed_length_letcher_factor <- 
    inner_join(seed_length_factor,spcodes_traits_only,by = c("gen","sp")) %>%
        
        group_by(name) %>% 
        
        # If I have values from two sites, select sar else select the only value
        mutate(test = if_else(n() > 1, TRUE, FALSE)) %>%
    
        # Create logical col for selection values from one side  
        filter(if_else(test == TRUE, site %in% "sar", TRUE)) %>% 
        select(spcode,spcode_4_3, everything(),
               -c(site, test))  

# 132 of my species with seed length factor in letcher 

sp_with_no_seed_length_58 <- 
    anti_join(spcodes_traits_only,seed_length_factor, by = c("gen","sp"))
# 58 of my species with no seed length factor


## GET NUMERIC Seed length data from letcher -----------------------------------

seed_length_numeric <- 
    raw_traits_letcher %>% 
        dplyr::select(1:3,11) %>% 
        
        # Tranform 
        mutate(seedlength_mm = as.numeric(seedlength_mm)) %>% 
        
        # Select seed_length traits
        mutate(across(where(is.character), str_to_lower)) %>% 
        
        # select only wet forests based on Letcher et al table
        # https://besjournals.onlinelibrary.wiley.com/doi/full/10.1111/1365-2745.12435
        filter(site %in% c("osa","car","bra","pan","chj","luq", "sar" )) %>% 
      
        # Remove species with no traits seedlength_mm
        filter(!if_all(c(seedlength_mm), ~ is.na(.))) %>%
        
        # Remove duplicates
        unite(name,c("gen","sp"), sep = " ", remove = FALSE) 

# 129 of my species with seed length numeric in letcher        

### Species with data seed length numeric in letcher ---------------------------

seed_length_letcher_numeric <- 
    inner_join(seed_length_numeric, spcodes_traits_only,by = c("gen","sp")) %>% 
      
        select(spcode,spcode_4_3, everything(),
               -site) 

# 22 of my species with seed length numeric in letcher 
# 168 species with no seed length numeric

## GET seed mass data from letcher ---------------------------------------------

seed_mass <- 
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

### Species with data seed mass numeric in letcher -----------------------------

data_seed_mass <- 
    inner_join(seed_mass, spcodes_traits_only,by = c("gen","sp")) %>% 
    select(spcode,spcode_4_3, everything())
 
    
# Join datasets ----------------------------------------------------------------

## Join seed length
data_seed_length <- 
    full_join(seed_length_letcher_numeric,seed_length_letcher_factor, 
          by = c("spcode", "spcode_4_3", "name", "gen", "sp")) %>% 
        select(-name)

data_no_seed_traits <- 
    anti_join(spcodes_traits_only,data_seed_length, by = c("gen","sp"))    


# With of the species with no seed lenght data have seed mass data
inner_join(data_no_seed_traits,data_seed_mass,  
          by = c("spcode", "spcode_4_3", "gen", "sp"))  %>% 
    select(-name)  
    

# Create full dataset ----------------------------------------------------------
data_seed_length <- 
    full_join(data_seed_length,data_no_seed_traits, 
          by = c("spcode", "spcode_4_3", "gen", "sp")) %>% 
    select(!c(gen, sp))
    

full_join(seed_length_letcher_numeric,seed_length_letcher_factor, 
          by = c("spcode", "spcode_4_3", "name", "gen", "sp")) %>% 
    select(-name)



# Revome datasets
rm("data_no_seed_traits", "raw_traits_letcher", "seed_length_factor", "data_seed_mass",
   "seed_length_letcher_factor", "seed_length_letcher_numeric", "seed_mass",
   "seed_length_numeric","sp_with_no_seed_length_58", "spcodes_traits_only")
