# Load packages ----------------------------------------------------------------
library(fastshap)
library(parallel)
library(ggplot2)

# Seed for reproducibility -----------------------------------------------------

# do some work involving random numbers.
RNGkind("L'Ecuyer-CMRG")
set.seed(123)
s <- .Random.seed

# do some work involving random numbers.
nextRNGStream(s)
nextRNGSubStream(s)

# Set WD for running the code in the Terminal ----------------------------------
here::i_am("scripts/shapley_values/shapley_values.R")
setwd(here::here())
getwd()

# Load data --------------------------------------------------------------------
source("./scripts/data_cleaned.R")
rm(y_fdis, y_redun, data_for_analysis)

# Load spatial RF models -------------------------------------------------------
#load(file = "./scripts/models_spatial_random_forest/model_spatial_random_forest_fdis.RData")
load(file = "./scripts/models_spatial_random_forest/model_spatial_random_forest_redundancy.RData")

# Get model's prediction function ----------------------------------------------
get_predic <- function(object, newdata) {    
    RandomForestsGLS::RFGLS_predict_spatial(object,
                                            Xtest = newdata,                                            
                                            # Use Coordinates from test set 
                                            coords.0 = as.matrix(coords))$prediction
}

# Shapley Values --------------------------------------------------------------- 

## Set parallel env  -----------------------------------------------------------

# Initiate cluster
cl <- parallel::makeCluster(detectCores()-1, type = "FORK")

doParallel::registerDoParallel(cl)

# Specify exactly what variables and libraries that you need for the parallel 
# function to work

parallel::clusterExport(cl = cl, varlist = c('coords', 'get_predic'), 
                        envir = environment())

# If you are using some special packages you will similarly need to load those 
# through clusterEvalQ
clusterEvalQ(cl, library(fastshap))

# Calculate Shapley values for fdis model --------------------------------------
shapley_values <- explain(object = model_spatial_random_forest_redundancy,
                                 X = predictors,
 
                                 pred_wrapper = get_predic,
 
                                 feature_names = colnames(predictors),
 
                                 nsim = 999,
 
                                 #adjust = TRUE,
                                 .parallel = TRUE,
                                 #.export = 
 
                                 # produce informative error messages?
                                 .inform = TRUE,
                                 .paropts = list(.packages = NULL))

# Close the cluster
parallel::stopCluster(cl)

## Save shapley values for fdis model ------------------------------------------
#save(shapley_values, file = "./scripts/shapley_values/shapley_fdis_values.RData")
save(shapley_values, file = "./scripts/shapley_values/shapley_redundancy_values.RData")

# Refs -------------------------------------------------------------------------

# http://gforge.se/2015/02/how-to-go-parallel-in-r-basics-tips/

# https://github.com/USGS-R/drb-inland-salinity-ml/blob/main/4_predict/src/train_models.R


