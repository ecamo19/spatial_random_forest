# Objective ---------------------------------------------------------------------
# Gather all necessary data sets for creating a single one called
# data_set_for_stats

here::i_am("scripts/script_create_data_set_for_stats.R")

# Load packages -----------------------------------------------------------------
library(dplyr)
library(janitor)

# Load data sets ----------------------------------------------------------------

env_data <-
    read.csv("./data/cleaned_data/env_data.csv") %>% dplyr::select(-X)

lat_long_plots <-
    read.csv("./data/raw_data/lat_long_plots.csv") %>%
    clean_names()

plot_agb <-
    read.csv("./data/cleaned_data/plot_agb.csv") %>% dplyr::select(-X)


redundancy_and_functional_diversity <-
    read.csv("./data/cleaned_data/redundancy_and_functional_diversity.csv") %>%
        dplyr::select(-X)

# Join data ---------------------------------------------------------------------
summary(lat_long_plots)
summary(env_data)

inner_join(lat_long_plots, env_data, by = c("crtm_90_x,crtm_90_y"))
plot_agb


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

