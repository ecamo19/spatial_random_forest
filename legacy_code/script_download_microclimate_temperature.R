
# For reference ----------------------------------------------------------------

# https://rdrr.io/github/ilyamaclean/microclima/man/ 
# https://rdrr.io/github/ilyamaclean/microclima/man/get_NCEP.html

# Load packages ----------------------------------------------------------------
library(raster)
library(NicheMapR)
library(microclima)
library(dplyr)
library(tibble)
library(tidyr)
library(furrr)
library(lubridate)

# Load plot locations ----------------------------------------------------------
parcelas_lon_lat <- read.csv("~/Documents/projects/redundancy_and_diversity_across_elevation/stats/data/raw_data/data_posicion_parcelas.csv") %>%
    dplyr::select(plot,longitude,latitude)

# Function for downloading data  -----------------------------------------------

get_daily_temp  <- function(data){
    
    get_NCEP(long = data$longitude, lat = data$latitude,
             
                    tme = seq(ymd("19800101"),
                              ymd("20111231"), 
                              by = "day"))
}


# Get precipitation data -------------------------------------------------------
plan("multisession")

daily_temp_1980_2011 <-
    
    parcelas_lon_lat %>%
    
    # Step done keeping track of the id
    mutate(plot_id = plot) %>%
    column_to_rownames(., var = "plot_id") %>%
    
    # Split by plot
    split(.$plot) %>%
    
    # Iterate
    furrr::future_map(.,get_daily_temp)

# Save data --------------------------------------------------------------------
save(daily_temp_1980_2011, file = "~/Documents/projects/redundancy_and_diversity_across_elevation/stats/data/raw_data/microclimate/raw_daily_temp.RData")
    


