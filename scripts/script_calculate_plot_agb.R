# Objetive ---------------------------------------------------------------------
# Estimate the abovegorund biomass of each plot using the biomass R package

here::i_am("data_analysis/scripts/script_calculate_plot_agb.R")

# Load packages ----------------------------------------------------------------
library(dplyr)
library(janitor)
# For column to row function
library(tibble)
# For pivot
library(tidyr)
# For calculate Aboveground Biomass
library(BIOMASS)
# For reading .xlsx file
library(readxl)

# Load data -------------------------------------------------------------------

# Tree basal area
basal_area_wide <-
    read_excel("./data/raw_data/raw_species_basal_area.xlsx", sheet = 2)  %>%

        # Remove last row, for some reason read_excel imports a row filled with
        # NAs
        slice(1:127) %>%
        clean_names() %>%

        # Remove species
        select(-c("brospa", "hirtme", "ruptca", "quetoc", "maytgu"))

# Plot locations
plot_lat_long <- read.csv("./data/raw_data/lat_long_plots.csv", header = T)

# Traits for obtaining wood density
traits_db <-
    read.csv("./data/cleaned_data/traits_db_255.csv", head = T)

# Wood density
wood_density <-
    traits_db %>%
        select(spcode, wood_density_gcm3_1)


## Read species list ----------------------------------------------------------
species_list_255 <-
    read.csv("./data/cleaned_data/species_list_updated.csv", header = TRUE) %>%
        select(-X)

# Clean data -------------------------------------------------------------------
basal_area_dbh_long <-
    basal_area_wide %>%

        # Change to long format
        pivot_longer(!parcela, names_to = "spcode",
                        values_to = "basal_area_m2_ha") %>%

        # Get DBH from Basal area
        # Basal area m2_ha = (pi * (DBH/2)^2)/10000
        # DBH cm = 2 * sqrt(BA*10000/pi)
        mutate(dbh_cm = 2 * sqrt(10000 * basal_area_m2_ha / pi)) %>%
        rename(plot = parcela)


# Join DBH data with plot latitude and longitude -------------------------------
dbh_species_per_plot <-

    # add plot lat-lon to dbh data
    inner_join(plot_lat_long, basal_area_dbh_long, by = "plot") %>%
        select(-c(CRTM_90_Y, CRTM_90_X, forest_type, basal_area_m2_ha)) %>%

        # Remove species that are not present within the plot
        na.omit()

# Join DBH data with wood density data -----------------------------------------
dbh_wd_per_plot <-
    inner_join(wood_density, dbh_species_per_plot, by = "spcode") %>%
    select(plot, longitude, latitude, spcode, everything()) %>%
    mutate(plot = factor(plot))  %>%
    arrange(., plot)

# Estimate AGB -----------------------------------------------------------------

plot_agb <- summaryByPlot(computeAGB(D = dbh_wd_per_plot$dbh_cm,
                                    WD = dbh_wd_per_plot$wood_density_gcm3_1,
                                    coord = dbh_wd_per_plot[, c("longitude",
                                                                "latitude")]),
                            dbh_wd_per_plot$plot)

# Save db ----------------------------------------------------------------------
write.csv(plot_agb, "./data/cleaned_data/plot_agb.csv")