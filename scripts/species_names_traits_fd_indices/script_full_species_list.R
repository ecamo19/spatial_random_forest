
# Metadata ---------------------------------------------------------------------

# Results of https://tnrs.biendata.org/

# Code Archive -----------------------------------------------------------------

# # Read .xlsx raw file
# raw_data_species_names <- 
#     read_excel(file_name,
#            # Specify the rows to read 
#            range = cell_rows(c(19, 902)))  
# 

# 
# 
# # Clean raw data
# data_cleaned_species_list <-
#     raw_data_species_names  %>%      
#         clean_names() %>% 
#         as_tibble(.) %>% 
#         
#         # Replace all spaces and dots with _ 
#         mutate(across(where(is.character), str_replace_all, 
#                       pattern = "[ ,.,  ,;,__]",
#                       replacement = "_")) %>%
#         
#         # Set levels to lower case
#         mutate(across(where(is.character), str_to_lower)) %>%
#     
#         # Sort variables and remove columns 
#         dplyr::select(accepted_family,franklin_et_al_notes,name_submitted,
#                       accepted_name,name_matched) %>% 
#         
#         # Replace NA notes with none, this makes filter work
#         replace_na(list(franklin_et_al_notes = "none")) %>% 
#         
#         # All rows that are not trees according to notes were deleted
#         filter(!str_detect(franklin_et_al_notes, "not_a|a_sh|vine")) %>% 
#         
#         # Change names according to franklin_et_al_notes
#         # Accepted_name was used unless Notes indicate another name.
#         mutate(accepted_name = recode(accepted_name, 
#                                        acacia = "vachellia_choriophylla",
#                                        bursera_fagaroides = "bursera_inaguensis",
#                                        coriaria = "nectandra_coriacea",
#                                        zanthoxylum_nannophyllum ="zanthoxylum_nashii"))  %>%
#         
#         mutate(franklin_et_al_notes = recode(franklin_et_al_notes,
#                                              retain_inaguensis = "bursera_inaguensis"))
#         
# # Following what it is said in the metadata 
# data_species_names <- 
#     data_cleaned_species_list %>% 
#     
#      # If no accepted_name (NA), Name_matched was used. 
#     mutate(species_names_cleaned = ifelse(is.na(accepted_name), name_matched,
#                                           accepted_name)) %>% 
#     dplyr::select(accepted_family,species_names_cleaned,name_submitted)
#     
# # Remove duplicates 
# data_species_names_no_duplicates <- 
#     data_species_names %>% 
#     group_by(species_names_cleaned) %>% 
#     summarise(n = n()) 
#     
# # show difference between name_summited and species_names_cleaned 
# 
# # data_species_names %>%
# #     dplyr::select(name_submitted,species_names_cleaned) %>% 
# #     mutate(difference = if_else(.$name_submitted == .$species_names_cleaned, 
# #                                  0, 1)) 

# Load packages ----------------------------------------------------------------
library(dplyr)
library(janitor)
# For read excel files
library(readxl) 
# For separate function
library(tidyr)
# For strings
library(stringr)

# Full species list ------------------------------------------------------------

## Read data -------------------------------------------------------------------
raw_data_species_list <-
 
    read.csv("./data/raw_data/traits/effect_traits/data_effect_traits.csv", header = T) %>%
    
    # clean column names
    clean_names()

## Full species list -----------------------------------------------------------

data_species_full_list <- 
    
    # Convert 
    as_tibble(raw_data_species_list) %>% 
    mutate(spcode = coespec) %>% 
    select(familia, genero, especie, spcode) %>% 
    
    # Replace all spaces and dots with _ 
    mutate(across(where(is.character), str_replace_all, pattern = "[/]",
                       replacement = "_")) %>%
    
    # Remove points
    mutate(across(where(is.character), str_replace_all, pattern = "[.]",
                  replacement = "")) %>% 
    
    # Set levels to lower case
    mutate(across(where(is.character), str_to_lower))
    
## Number of species -----------------------------------------------------------

print(paste0("The total number of species (species and morpho-species) is: ",
             dim(data_species_full_list)[1]))

# Remove files except the one that is useful -----------------------------------
rm(raw_data_species_list)
    
