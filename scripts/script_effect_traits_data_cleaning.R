# Objetive ---------------------------------------------------------------------

# Load packages ----------------------------------------------------------------
library(dplyr)
library(janitor)
# For column to row function
library(tibble)
# For pivot
library(tidyr)
# For datasets differences
library(diffdf)
library(stringr)

# Load raw data ----------------------------------------------------------------

## AGB data --------------------------------------------------------------------
raw_traits_effect_data <-
    read.csv("./data/raw_data/traits/effect_traits/data_effect_traits.csv") %>%

        clean_names() %>%
        dplyr::select(4:10) %>%
        mutate(across(where(is.character), str_to_lower)) %>%

        # Remove species
        filter(!coespec %in% c("brospa", "hirtme", "ruptca","quetoc", "maytgu"))

## Read trait data to get new spcodes ------------------------------------------
response_traits <-
    read.csv("./data/raw_data/traits/response_traits/refrence_response_traits.csv", header = T) %>%
    dplyr::select(-X)


### Get spcodes from trait dataset ---------------------------------------------
spcodes_traits_only <-
    response_traits %>%
        dplyr::select(1:3) %>%
        arrange(spcode)


# Test -------------------------------------------------------------------------
raw_traits_effect_data %>%
    inner_join(.,spcodes_traits_only, by = c("coespec" = "spcode"))

## Double check spcodes --------------------------------------------------------
raw_traits_effect_data %>%
    distinct(coespec)  %>%
    cbind(., spcodes_traits_only) %>%
    arrange(coespec) %>%
    rename(sp1 = "spcode") %>%
    mutate(same = if_else(sp1 == coespec, TRUE, FALSE)) %>%
    filter(if_any("same", ~ . == FALSE))

# Join datasets ----------------------------------------------------------------

data_effect_traits <-
    inner_join(spcodes_traits_only, raw_traits_effect_data,
               by = c("spcode" = "coespec")) %>%
    arrange(spcode_4_3)


# delete other object ----------------------------------------------------------
rm(raw_traits_effect_data,response_traits, spcodes_traits_only)
