# This function fits a spatial random forest and calculates the MSE of the model
spatial_random_forest <- function(y, coords, predictors, mtry, nthsize, ntree,
                                                                data = NULL) {

    # Get matern params 
    # 1 variance (sigma), 2 range (phi), 3 smoothness (nu = v ), 4 nugget(tau2)
    params <- GpGp::get_start_parms(y = y,
                    X = as.matrix(predictors), 
                    locs = as.matrix(coords), 
                    covfun_name = "matern_isotropic")

    spatial_random_forest <- RandomForestsGLS::RFGLS_estimate_spatial(y = y, 
                                                
                                                # Predictors 
                                                X = as.matrix(predictors), 
                                                
                                                # Coords 
                                                coords = as.matrix(coords), 
                                                
                                                # number of core to be used in 
                                                # parallel computing
                                                h = 8,
                                                
                                                # number of threads to be used
                                                n_omp = 16,
                                                
                                                # Spatial params (1, 0.1, 5, 
                                                # 0.5 defaults)
                                                cov.model = "matern",
                                                sigma.sq = params$start_parms[1],
                                                phi = params$start_parms[2],
                                                nu = params$start_parms[3],
                                                tau.sq = params$start_parms[4],
                                                
                                                # Tuning parameters
                                                ntree = ntree,
                                                mtry = mtry,
                                                nthsize = nthsize)
    
    # Return message MSE
    mse_spatial_random_forest <- mean((y - spatial_random_forest$predicted)^2)
    # cat(bold(paste0("\nMSE Spatial Random forest: ")))
    # cat(cyan(paste0(mse_spatial_random_forest)))
    
    # Add MSE to model list 
    spatial_random_forest[length(spatial_random_forest) + 1] <- mse_spatial_random_forest
    names(spatial_random_forest)[length(spatial_random_forest)] <- "mse"
    
    return(spatial_random_forest)
}
