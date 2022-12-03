# Load packages ----------------------------------------------------------------
library(modelr)
library(dplyr)
library(purrr)
library(tibble)
library(tidyr)
library(caret)
library(crayon)
library(RandomForestsGLS)

# Load data --------------------------------------------------------------------
data_complete <- 
    read.csv("./data/data_for_analisys/data_functional_diversity.csv") %>% 
    dplyr::select(-X)

## Clean data ------------------------------------------------------------------

# Removing predictors that give the same information. This was decided based on
# a corr plot
 
data_for_analysis <-     
    data_complete %>% 
    
    # Remove predictors
    dplyr::select(-c(elevevation_cat, precdriest,
                     preccv, tempmin, slope_deg, clay,
                     f_dis, f_eve,rao_q, plot)) %>% 
    
    # Scale predictors
    mutate(across(!c('rendundancy', 'longitude', 'latitude'), scale)) %>% 
    
    # Order data set
    dplyr::select(rendundancy, everything()) 
    
# Estimate the predictive performance of model ---------------------------------


## Loop ------------------------------------------------------------------------
set.seed(666)

# Create empty dataframe for storing mse values for shuffled variables
mse_values_df <- data.frame(mse_value = numeric(0), 
                            predictor_shuffled = character(0))


suppressWarnings({
    for (each_sample in seq()) {
    
        ### Partition data into different objects response, predictors and 
        ### coordinates 
    
        ### Response
        y <- data_for_analysis$rendundancy
    
        ### Predictors
        predictors <- data_for_analysis %>% dplyr::select(!c(latitude, 
                                                         longitude, rendundancy))
    
        # Cooords
        coords <- data_for_analysis %>% dplyr::select(longitude, latitude) 
    
    
        # Fit Spatial Random forest
        spatial_random_forest <- 
                RFGLS_estimate_spatial(y = y,
                                       
                                        # Predictors 
                                        X = as.matrix(predictors), 
                                                    
                                        # Coordinates 
                                        coords = as.matrix(coords), 
                                                    
                                        # Tuning parameters
                                        ntree = 99,
                                        mtry = 2,
                                        cov.model = "matern",
                                        nthsize = 20)
        
    # Permutation Feature Importance algorithm
    
    ##  How the algorithm works?

    ##  R/ If I randomly shuffle a single column of the validation data, leaving the 
    ##  target and all other columns in place, how would that affect the accuracy 
    ##  of predictions in that now-shuffled data ?
    ##  
    for (each_predictor in seq(predictors)) {
        
         # Reset data
        predictors_shuffled <- predictors
         
         # Shuffle predictor
        predictors_shuffled[, each_predictor] <- 
                                    sample(predictors_shuffled[, each_predictor])
         
        #cat(bold(paste0("\nShuffled predictor: ", 
        #                         colnames(predictors_shuffled[each_predictor]),
        #                 "\n")))
         
         # Get predictions using shuffled test data
        spatial_random_forest_shuffle <- 
                    RFGLS_estimate_spatial(y = y,
                                            # Predictors with
                                            # one var suffled
                                                              
                                            X = as.matrix(predictors_shuffled), 
                                                                
                                            # Use Coords from train data
                                            coords = as.matrix(coords), 
                                                                
                                            # Tuning parameters
                                            ntree = 999,
                                            mtry = sqrt(ncol(predictors)),
                                            cov.model = "matern", 
                                            nthsize = 20)
         
         # Calculate mse for spatial random forest and for varImp
    
        mse <- mean((y - spatial_random_forest$predicted)^2)
        
        #cat(cyan(paste0("\nMSE Spatial Random Forest: ", mse, "\n")))
         
         ## Get MSE for model with shuffled predictor
        mse_shuffle <- mean((y - spatial_random_forest_shuffle$predicted))^2
         
        #cat(cyan(paste0("MSE Spatial Random Forest shuffled var: ", mse_shuffle, 
         #               "\n")))
         
         # new_mse - mse_full_mod 
        #cat(cyan(paste0("Variable importance: ", (mse - mse_shuffle), "\n")))
        
        
        # Add mse values to a empty dataframe
        mse_values_df <- mse_values_df %>% 
             
                    # Add mse value  
            add_row(mse_value = mse_shuffle,  
                    
                    # Add the name of the predictor 
                    # shuffled
                    predictor_shuffled = colnames(predictors_shuffled[each_predictor]))
        
         # Close second loop
         }
    
    #rownames(mse_values_df) <- paste0(seq(14,26))
     # Close first loop
    }
    
# Close the suppressWarnings    
})  

mse_values_df %>% 
    as_tibble() %>% 
    mutate(predictor_shuffled = factor(predictor_shuffled)) %>% 
    group_by(predictor_shuffled) %>% 
    summarise(mean = mean(mse_value))


# Test section -----------------------------------------------------------------

# Stuff to improve -------------------------------------------------------------

# + Read this https://towardsdatascience.com/stop-permuting-features-c1412e31b63f

# # + Read this https://machinelearningmastery.com/feature-selection-with-real-and-categorical-data/  

# + Look a the distribution of the predictors. Are they normal? 

# + Choose the right cov.model

# + Scale Variable importance

# + Tunning parameters  


# Refs -------------------------------------------------------------------------
# Cross validation idea 
# https://www.r-bloggers.com/2021/10/cross-validation-in-r-with-example/
# Video about structure of permutation importance
# https://www.youtube.com/watch?v=VUvShOEFdQo

