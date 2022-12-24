# Objective --------------------------------------------------------------------
# This script takes all the raw files contaning the traits and creates a dataset
# called traits_db

here::i_am("data_analysis/scripts/script_trait_db_construction.R")

# Load Packages ----------------------------------------------------------------
library(janitor)
library(dplyr)
# For pivot function
library(tidyr)
# For read xls files
library(stringr)
# For adding columns
library(tibble)

# Species list updated ---------------------------------------------------------
species_list_updated_255 <-
        read.csv("./data/cleaned_data/species_list_updated.csv",
                header = TRUE) %>%
        select(-X)

# Get Reproductive traits ------------------------------------------------------
reproductive_traits_190 <-
        read.csv("./data/cleaned_data/reproductive_traits_190.csv",
                header = TRUE) %>%
        select(-c(X, source))

# Get Effect traits ------------------------------------------------------------
raw_effect_traits_255 <-
        read.csv("./data/raw_data/raw_effect_traits.csv", header = TRUE) %>%
        clean_names()

# Clean raw effect traits data
effect_traits_255 <-
        raw_effect_traits_255 %>%

                dplyr::select(4:10) %>%
                mutate(across(where(is.character), str_to_lower)) %>%

                # Remove species
                filter(!coespec %in% c("brospa", "hirtme", "ruptca", "quetoc",
                                                                "maytgu"))  %>%

                rename(spcode = coespec) %>%

                mutate(n_p_ratio = n_mgg_1/p_mgg_1) %>%

                rename(wood_density_gcm3_1 = dm_gcm3_1,
                        leaf_area_mm2 = af_mm2,
                        sla_mm2mg_1 = afe_mm2mg_1,
                        ldmc_mgg_1 = cfms_mgg_1)

## Add new codes and TNRS names to trait data ----------------------------------
effect_traits_255 <-
        inner_join(species_list_updated_255, effect_traits_255, by = "spcode")

# Trait DB ---------------------------------------------------------------------
traits_db_255 <-
        left_join(effect_traits_255, reproductive_traits_190,
                by = c("spcode", "spcode_4_3", "accepted_species"))


# Impute morpho species?
#data_test <-
#        traits_db_255  %>%
#        separate(name_submitted, c("genus", "specie"), sep = " ")
#
#colnames(data_test)
#
#data_test %>%
#        group_by(genus) %>%
#        fill(dispersal_syndrome_modified, pollination_syndrome_modified,
#                sexual_system_modified, .direction = "downup") %>%
#                View()


# Save db ----------------------------------------------------------------------
write.csv(traits_db_255, "./data/cleaned_data/traits_db_255.csv")
