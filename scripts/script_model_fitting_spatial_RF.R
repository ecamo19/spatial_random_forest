# Set WD for running the code in the Terminal ----------------------------------
here::i_am("scripts/analysis/model_fitting_spatial_RF.R")
setwd(here::here())

# Load packages ----------------------------------------------------------------
library(dplyr)
library(parallel)
library(purrr)
library(furrr)
library(tidyr)
library(GpGp)

# Seed for reproducibility -----------------------------------------------------

# do some work involving random numbers.
RNGkind("L'Ecuyer-CMRG")
set.seed(123)
s <- .Random.seed

# do some work involving random numbers.
nextRNGStream(s)
nextRNGSubStream(s)

# Load  ------------------------------------------------------------------------
source("./scripts/data_cleaned.R")
source("./R/function_spatial_random_forest.R")

# Tuning Random Forest hyperparameters -----------------------------------------

# Params to search
mtry <- list(5, 10, 11, 12, 13)
nthsize <- list(10, 20, 30, 40)
 
# Create df
tuning_param  <- 
      crossing(mtry, nthsize) %>% 
      unnest(cols = c(mtry, nthsize)) 


# Redundancy model -------------------------------------------------------------

## Tuning parameters -----------------------------------------------------------

tuning_param_redun  <-
    tuning_param %>%
        mutate(mse = pmap(tuning_param,
                          ~ with(list(...),
                                 spatial_random_forest(y = y_redun,
                                                       coords = coords,
                                                       predictors = predictors,
                                                       mtry = mtry,
                                                       ntree = 99,
                                                       nthsize = nthsize)$mse))
    ) %>% 
    unnest(cols = c(mse)) %>%
    arrange(mse)
    
tuning_param_redun

## Model fitting ---------------------------------------------------------------

model_spatial_random_forest_redundancy <- 
    spatial_random_forest(y = y_redun, 
                          predictors = predictors,
                          coords = coords, 
                          mtry = 13, 
                          nthsize = 12, 
                          ntree = 15000)


model_spatial_random_forest_redundancy$predicted   

save(model_spatial_random_forest_redundancy, 
           file = "./data/rdata_files/model_spatial_random_forest_redundancy.RData")


# FDis model -------------------------------------------------------------------

## Tuning parameters -----------------------------------------------------------

tuning_param %>%
     mutate(mse = pmap(tuning_param,
                       ~ with(list(...),
                              spatial_random_forest(y = y_fdis,
                                                    coords = coords,
                                                    predictors = predictors,
                                                    mtry = mtry,
                                                    ntree = 99,
                                                    nthsize = nthsize)$mse))) %>%
      unnest(cols = c(mse)) %>%
      arrange(mse)

# Best mtry = 13 nthsize = 10

## Model fitting ---------------------------------------------------------------
model_spatial_random_forest_fdis <- 
    spatial_random_forest(y = y_fdis, 
                          predictors = predictors,
                          coords = coords, 
                          mtry = 13, 
                          nthsize = 12, 
                          ntree = 15000)

model_spatial_random_forest_fdis$predicted
 
save(model_spatial_random_forest_fdis, 
          file = "./data/rdata_files/model_spatial_random_forest_fdis.RData")

