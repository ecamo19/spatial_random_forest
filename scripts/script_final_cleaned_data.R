here::i_am("scripts/data_cleaned.R")
setwd(here::here())

# Load package for pipe --------------------------------------------------------
library(magrittr)

# Load data --------------------------------------------------------------------
data_complete <-
    read.csv("./data/functional_diversity_redundancy_indices/data_functional_diversity.csv") %>%
    dplyr::select(-X)

# Clean data -------------------------------------------------------------------

# Removing predictors that give the same information. This was decided based on
# a corr plot

data_for_analysis <-

    data_complete %>%

    # Remove predictors
    dplyr::select(-c(elevevation_cat, precdriest,
                     preccv, tempmin, slope_deg, clay,
                     f_eve,rao_q, plot)) %>%

    # Scale predictors
    # Not necessary anymore
    #dplyr::mutate(across(!f('c_dis','rendundancy', 'longitude', 'latitude'),
    #                     scale)) %>%

    # Order data set
    dplyr::select(rendundancy,f_dis, everything())


## Response vars ---------------------------------------------------------------
y_redun <- data_for_analysis$rendundancy
y_fdis <- data_for_analysis$f_dis

## Predictors ------------------------------------------------------------------
predictors <- data_for_analysis %>% dplyr::select(!c(latitude, f_dis, longitude,
                                                     rendundancy))

## Coordiantes -----------------------------------------------------------------
coords <- data_for_analysis %>% dplyr::select(longitude, latitude)

## Plot elevation --------------------------------------------------------------
elev <-
    data_complete %>%
            tibble::rownames_to_column("plot_number") %>%
            dplyr::select(plot_number, plot, elevevation_cat)

# Remove files -----------------------------------------------------------------
rm(list = c("data_complete"))

