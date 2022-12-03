# Function ----------------------------------------------------------------------
# This function creates n_iter dataframes with a single columns shuffled column
# while keeping the others same. The function is for calculating the variable 
# importance for a spatial random forest
set.seed(6896)

shuffle_columns <- function(predictors_df, n_iter = 1){
    
    data_shuffled_list <- list()
    row_number <- 0
    
    for (each_iter in seq(n_iter)) {
    
        for (each_predictor in seq(1, ncol(predictors_df))){
        
            # Reset data and use another predictor
            predictors_shuffled <- predictors_df
        
            # Data frame with shuffled predictor
            predictors_shuffled[, each_predictor] <- 
                sample(predictors_shuffled[, each_predictor])
        
            # Append dataframe to list
            data_shuffled_list[[row_number + 1]] <- predictors_shuffled
        
            # Name each dataframe within the list: \
            # Name format: var_shuffled_{var shuffled}_row_number 
            names(data_shuffled_list)[row_number + 1] <- 
                            paste0(#"var_shuffled_", 
                                    colnames(predictors_shuffled[each_predictor]),
                                   "_", (row_number + 1))
            
            # Move to the next row         
            row_number <- row_number + 1
    
        # Closes second loop
        }
        
    # Closes first loop    
    }

# Return a list of length of ncol(predictors)
return(data_shuffled_list)
    
# Closes function
}






















