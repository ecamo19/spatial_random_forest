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
# For working with strings
library(stringr)

# Load raw data ----------------------------------------------------------------

## Data with no changes --------------------------------------------------------
original_env_data <- 
    readxl::read_xlsx("./data/raw_data/abiotic_data/ENVIRONMENT.xlsx",
                      sheet = 2) %>% 
    select(!RESEARCHER) %>% 
    mutate(across(where(is.integer),as.numeric)) %>% 
    arrange(PLOT) 

## Data with changes done during master thesis ---------------------------------
# original_env_data_2 <- 
#     read.csv("./raw_data/abiotic_data/data_enviroment_worldclim.csv",
#                       header = T) %>% 
#     mutate(across(where(is.integer),as.numeric)) %>% 
#     arrange(PLOT) 
    
# Check differences between datasets -------------------------------------------

## Check dimensions ------------------------------------------------------------ 
#dim(original_env_data) == dim(original_env_data_2)

## Check differences -----------------------------------------------------------
#diffdf(original_env_data,original_env_data_2)

# Clean data -----------------------------------------------------------------
data_env <- 
    original_env_data %>% 
        # Remove TEMPSD column because values dont make sense
        select(-TEMPSD) %>% 
        
        # Convert TEMPS (TEMPMIN, TEMP ETC). Temp min of 199 does not make sense,  
        mutate(TEMPMIN = TEMPMIN/10,
               TEMP = TEMP/10,
               
               # Round to 3 decimal points
               SLOPE_DEG = round(SLOPE_DEG, 3),
               SLOPE_PER = round(SLOPE_PER, 3)) %>% 
        
        # Remove spaces and points
         mutate(across(where(is.character), str_replace_all, pattern = ". ",
                  replacement = "_"))  %>% 
        clean_names() %>% 
        arrange(plot)


print("data_env loaded")
# Remove unsed data ------------------------------------------------------------
rm(original_env_data)  



