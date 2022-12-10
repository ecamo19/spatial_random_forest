# Step done for running the code in the terminal -------------------------------
here::i_am("scripts/analysis/script_variable_importance.R")
setwd(here::here())

# Load packages ----------------------------------------------------------------
library(stringr)
library(dplyr)
library(furrr)
library(tibble)
library(tidyr)
library(parallel)

# Set seed

#RNGkind("L'Ecuyer-CMRG")
set.seed(555)

# Load functions ---------------------------------------------------------------
source("./R/function_shuffling_data_frames.R")
source("./R/function_spatial_random_forest.R")

# Load data and models ---------------------------------------------------------

## Data ------------------------------------------------------------------------
source("./scripts/data_cleaned.R")

## Models ----------------------------------------------------------------------
load("./data/rdata_files/model_spatial_random_forest_fdis.RData")
load("./data/rdata_files/model_spatial_random_forest_redundancy.RData")

# Create list with shuffled dataframes -----------------------------------------
shuffled_predictors_list <- shuffle_columns(predictors_df = predictors, n_iter = 100)
length(shuffled_predictors_list)

# Benchmarks -------------------------------------------------------------------
benchmark_mse_fdis <- model_spatial_random_forest_fdis$mse    
benchmark_mse_redundancy <- model_spatial_random_forest_redundancy$mse

# VarImp -----------------------------------------------------------------------
future::plan("multisession")
    
## FDis ------------------------------------------------------------------------
var_imp_fdis <-
    furrr::future_map_dfr(shuffled_predictors_list, ~spatial_random_forest(y = y_fdis, 
                                                                           predictors = .x,
                                                                           coords = coords, 
                                                                           mtry = 13, 
                                                                           nthsize = 12,
                                                                           ntree = 999)$mse,
                           .options = furrr_options(seed = TRUE)) 

# Save
save(var_imp_fdis, file = "./data/rdata_files/var_imp_fdis.RData")

# Load list
#load(file = "./data/rdata_files/var_imp_fdis.RData")

#cat(crayon::bold(paste0("\nvar_imp_fdis\n ")))

#var_imp_fdis %>% 
    # Create dummy var. This is done for thr pivot_longer
#    add_column(a = 1) %>% 
    
    # Tidy long format dataframe
#    pivot_longer(!a,names_to = 'shuffled_var', values_to = "mse" ) %>% 
    
    # Remove numbers from shuffled_var
#    mutate(across('shuffled_var', str_replace_all, "[:digit:]|[_]", "")) %>% 
    
    # Remove dummy var
#    dplyr::select(-a) %>%
    
    # Remove NaN
#    dplyr::filter(!is.na(mse)) %>% 
    
#    group_by(shuffled_var) %>% 
    
    # Calculate new mse
#    summarise(mean_mse = mean(mse)) %>% 
    
    # Add mse from base model
#    add_column(mse_benchmark_fdis = benchmark_mse_fdis) %>% 
        
#    mutate(var_imp = if_else(mean_mse > benchmark_mse_fdis, "mse_increased",
#                             "mse_decreased"))

## Redundancy ------------------------------------------------------------------  
future::plan("multisession")

var_imp_redundancy <-       
     furrr::future_map_dfr(shuffled_predictors_list, ~spatial_random_forest(y = y_redun, 
                                                                           predictors = .x,
                                                                           coords = coords, 
                                                                           mtry = 13, 
                                                                           nthsize = 12,
                                                                           ntree = 999)$mse,
                           .options = furrr_options(seed = TRUE)) 

# Save
save(var_imp_redundancy, file = "./data/rdata_files/var_imp_redundancy.RData") 

# Load list
#load(file = "./data/rdata_files/var_imp_redundancy.RData")

#cat(crayon::bold(paste0("\nvar_imp_redundancy\n ")))

#var_imp_redundancy %>% 
    # Create dummy var. This is done for thr pivot_longer
#    add_column(a = 1) %>% 
    
    # Tidy long format dataframe
#    pivot_longer(!a, names_to = 'shuffled_var', values_to = "mse" ) %>% 
    
    # Remove numbers from shuffled_var 
#    mutate(across('shuffled_var', str_replace_all, "[:digit:]|[_]", "")) %>% 
    
    # Remove dummy var
#    dplyr::select(-a) %>% 
    
    # Remove NaN
#    dplyr::filter(!is.na(mse)) %>% 
    
#    group_by(shuffled_var) %>% 
    
    # Calculate new mse
#    summarise(mean_mse = mean(mse))  %>% 
    
    # Add mse from base model
#    add_column(mse_benchmark_redun = benchmark_mse_redundancy) %>% 
    
#    mutate(var_imp = if_else(mean_mse > benchmark_mse_redundancy, "mse_increased",
#                             "mse_decreased"))
