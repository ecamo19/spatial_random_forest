# Load packages ----------------------------------------------------------------
library(BIEN)
library(purrr)
library(dplyr)
library(readr)

# Load species list ------------------------------------------------------------
# This data come from the file got it from the tnrs

species_list_tnrs <-
    read.csv("./raw_data/tnrs_names.csv") %>% 
        select(name_used) %>% 
        clean_names()


# Clean data -------------------------------------------------------------------

## Create columns genus and specie (this step should not be done, just for fun)

species_list_tnrs <- 
    species_list_tnrs %>% 
        separate(name_used, c("genus", "specie"),sep = "[ ]", remove = FALSE)

    
# Function for making the call to BIEN database --------------------------------

bien_traits <- function(genus,sp){
    
    # Format species name
    name <- paste0(str_to_title(genus), " ", sp)
    
    # Make the call to the database
    return(BIEN_trait_species(species = name))
}


# Iterate  ---------------------------------------------------------------------
data_from_bien_database <- map2_dfr(.x = species_list_tnrs$genus, 
                                    .y = species_list_tnrs$specie, 
                                    .f = bien_traits)

# Save data
readr::write_csv(data_from_bien_database, "./raw_data/data_from_bien_database_wet_forest.csv",
                col_names = TRUE)




