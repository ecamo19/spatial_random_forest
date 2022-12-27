# Objective ---------------------------------------------------------------------
# Transform crtm05 coordinates to wgs84

# Tutorial
# https://www.nceas.ucsb.edu/sites/default/files/2020-04/OverviewCoordinateReferenceSystems.pdf

# Info
# http://50.57.85.98/crs_5367/CR05-CRTM05.html
# https://epsg.io/5367-5376

# Load packages -----------------------------------------------------------------
library(sp)
library(sf)
library(rgdal)
library(dplyr)

# Load data ---------------------------------------------------------------------
raw_plots_lat_lon <- read.csv("./data/raw_data/raw_plots_lat_lon_crtm05.csv") %>%
                        select(-X)

crtm05_long_lat <- raw_plots_lat_lon

# Search codes ------------------------------------------------------------------
EPSG <- make_EPSG()

# CRTM05
EPSG[grep("5367", EPSG$code), ]

# WSG84
EPSG[grep("4326", EPSG$code), ]

# To assign a known CRS to spatial data -----------------------------------------

coordinates(crtm05_long_lat)  <- ~crtm_90_x + crtm_90_y
proj4string(crtm05_long_lat) <- CRS("+init=epsg:5367")

# Check info --------------------------------------------------------------------
st_crs(crtm05_long_lat)

# Transform ---------------------------------------------------------------------
wgs84_long_lat <- spTransform(crtm05_long_lat, CRS("+init=epsg:4326"))

# Data frame with both CRTM05 and WGS84 -----------------------------------------
plots_wgs84 <-
    as.data.frame(wgs84_long_lat)  %>%
        rename(x_wgs84 = crtm_90_y, y_wgs84 = crtm_90_x)  %>%
        select(plot, x_wgs84, y_wgs84) %>%
        inner_join(., raw_plots_lat_lon, by = "plot")

# Save data ---------------------------------------------------------------------
write.csv(plots_wgs84, "./data/cleaned_data/plots_long_lat_wgs84.csv")
