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

suppressWarnings({
for (each_sample in seq(1,5)) {
    
    # Sample data, train 75% test 25%
    # samples <- data_for_analysis$rendundancy %>%
    #     createDataPartition(p = 0.75, list = FALSE)
    
    ## Save data into train and test
    
    # ### Train set
    # train_data  <- data_for_analysis[samples, ]
    # 
    # ####  Save response, predictors and coordinates in different objects
    # y_train <- train_data$rendundancy
    # x_train <- train_data %>% dplyr::select(!c(latitude, longitude, rendundancy))
    # coords_train <-train_data %>% dplyr::select(longitude, latitude) 
    # 
    # ### Test set
    # test_data <- data_for_analysis[-samples, ]
    
    ####  Save response, predictors and coordinates in different objects
    y <- $rendundancy
    x <- test_data %>% dplyr::select(!c(latitude, longitude, rendundancy))
    coords <-test_data %>% dplyr::select(longitude, latitude) 
    
    
    # # Data info
    # cat(bgBlue(paste0("\nSample number: ", each_sample, "\n")))
    # 
    # cat(blue(paste0("\nDimensions train dataset: Rows ", dim(train_data)[1], 
    #                 " Cols ", dim(train_data)[2],  "\n")))
    # 
    # cat(blue(paste0("\nDimensions test dataset: Rows ", dim(test_data)[1], 
    #                 " Cols ", dim(test_data)[2],  "\n")))
    
    # Fit Spatial Random forest
    spatial_random_forest <- RFGLS_estimate_spatial(y = y, 
                                                    
                                                    # Use predictors from train data
                                                    X = as.matrix(x), 
                                                    
                                                    # Use Coords from train data
                                                    coords = as.matrix(coords), 
                                                    
                                                    # Tuning parameters
                                                    ntree = 99,
                                                    mtry = 2,
                                                    cov.model = "exponential",
                                                    nthsize = 20)
    
    ## MSE train
    mse_train <- mean((spatial_random_forest$y - spatial_random_forest$predicted)^2)
    

    # # Get predictions using test data
    # spatial_predictions <- RFGLS_predict_spatial(spatial_random_forest,
    #                                              
    #                                                     # Use test predictors
    #                                                     Xtest = x_test,
    #                                              
    #                                                     # Use Coordinates from test set 
    #                                                     coords.0 = as.matrix(coords_test))
    # 
    ## Get MSE baseline
    mse <- mean((test_data$rendundancy - unlist(spatial_predictions))^2)
    
    cat(bold(paste0("\nMSE Train vrs MSE Test: ")))
    cat(cyan(paste0("\nMSE Train: ", mse_train)))
    cat(cyan(paste0("\nMSE Test: ", mse_test, "\n")))
    
    # Permutation Feature Importance algorithm
    
    ##  How the algorithm works?

    ##  R/ If I randomly shuffle a single column of the validation data, leaving the 
    ##  target and all other columns in place, how would that affect the accuracy 
    ##  of predictions in that now-shuffled data ?
    
    cat(bgBlue(paste0("\nVariable importance calculation\n")))
    
    for (each_predictor in seq(ncol(x_test))) {
        
        # Reset data
        x_test_shuffled <- x_test
        
        # Shuffle predictor
        x_test_shuffled[,each_predictor] <- sample(x_test_shuffled[,each_predictor])
        
        cat(bold(paste0("\nShuffled predictor: ", 
                                colnames(x_test_shuffled[each_predictor]),"\n"
                                )))
        
        # Get predictions using shuffled test data
        spatial_predictions_shuffle <- RFGLS_predict_spatial(
            
                                                    # Model trained
                                                    spatial_random_forest,
                                                     
                                                    # Use test predictors
                                                    Xtest = x_test_shuffled,
                                                     
                                                    # Use Coordinates from test set 
                                                    coords.0 = as.matrix(coords_test))
        
        ## Get MSE for model with shuffled predictor
        mse_test_shuffle <- mean((test_data$rendundancy - 
                                      unlist(spatial_predictions_shuffle))^2)
        
        cat(cyan(paste0("MSE test shuffle: ", mse_test_shuffle, "\n")))
        
        #new_rmse - rmse_full_mod 
        cat(cyan(paste0("Variable importance: ", (mse_test_shuffle - mse_test), 
                        "\n")))
        
        # Close second loop    
        }
    
    # Close first loop
    }
    
# Close the suppressWarnings    
})  


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

