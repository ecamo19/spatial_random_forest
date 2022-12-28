# Load packages  ---------------------------------------------------------------
library(lubridate)
library(raster)
library(NicheMapR)
library(microclima)
library(dplyr)
library(tibble)
library(tidyr)
library(furrr)

# Load plot locations ----------------------------------------------------------
parcelas_lon_lat <- read.csv("~/Documents/projects/redundancy_and_diversity_across_elevation/stats/data/raw_data/data_posicion_parcelas.csv") %>%
    dplyr::select(plot,longitude,latitude)

# Function for downloading data  -----------------------------------------------

get_daily_precip <- function(data){

            dailyprecipNCEP(long = data$longitude,
                            lat = data$latitude,

                            reanalysis2 = TRUE,
                            tme = seq(ymd("19800101"),
                                      ymd("20111231"),
                                      by = "day"))
}

# Get precipitation data -------------------------------------------------------
plan("multisession")

daily_precip_1980_2011 <-

    parcelas_lon_lat %>%

                # Step done keeping track of the id
                mutate(plot_id = plot) %>%
                column_to_rownames(., var = "plot_id") %>%

                # Split by plot
                split(.$plot) %>%

                # Iterate
                furrr::future_map(.,get_daily_precip)

# Save data --------------------------------------------------------------------
#save(daily_precip_1980_2011, file = "~/Documents/projects/redundancy_and_diversity_across_elevation/stats/data/raw_data/microclimate/raw_daily_precip_1980_2011.RData")

