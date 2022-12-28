# Objective --------------------------------------------------------------------
# This script takes all the raw files contaning reproductive traits and
# creates a dataset called reproductive_traits

here::i_am("data_analysis/scripts/script_get_reproductive_traits.R")

# Load packages ----------------------------------------------------------------
library(janitor)
library(dplyr)
# For pivot function
library(tidyr)
# For reading html files
library(rvest)
# For pluck function
library(purrr)
# For read xls files
library(readxl)
# For working with names
library(stringr)
# For converting pdf to data
library(tabulizer)
# For adding columns
library(tibble)

# Species list updated ---------------------------------------------------------
species_list_updated <-
                        read.csv("./data/cleaned_data/species_list_updated.csv",
                                header = TRUE) %>%
                        select(-X)

species_list_updated_190 <-
    species_list_updated %>%

        # Get genus and species
        separate(name_submitted, c("genus", "specie"), sep = " ", remove = FALSE) %>%

        # Remove morphospecies
        filter(!(str_detect(specie, "^sp") & (str_length(specie) <= 4))) %>%

        # Remove genus and species
        select(-c(genus, specie))


# Get Reproductive traits ------------------------------------------------------

## Species with traits in Salgado dataset --------------------------------------

## Load data
raw_salgado_traits <-
                read_xls("./data/raw_data/raw_salgado_original.xls") %>%
                clean_names()

## Search
# This dataset contains the original trait name and the modified one

data_salgado_traits <-
    raw_salgado_traits %>%
        select(-c(familia, autoridad)) %>%
        unite("name_submitted", genero, especie, sep = " ", remove = FALSE)  %>%

        # Species with traits in Salgado dataset. Should be 132
        inner_join(species_list_updated_190, ., by = "name_submitted")  %>%
        select(accepted_species, everything(),
               -c(estrato, tasacrecimiento, rep_vegetativa)) %>%

        # Rename columns
        rename(dispersal_syndrome = "diseminacion",
               sexual_system = "sist_sexual",
               pollination_syndrome = "polinizacion")  %>%

        # Remove reference numbers, parentheses and comas
        mutate(across(where(is.character), str_replace_all,
                                        pattern = "[:digit:]|[(,)]",
                                        replacement = ""))   %>%

        # Rename levels in dispersion column
        mutate(dispersal_syndrome_modified = case_when(
            # Wind
            dispersal_syndrome == "W"  ~ "dwin",
            # Hidrocoria
            dispersal_syndrome == "H"  ~ "dhid",
            # Convert Flying animals Non-flying animals to just animals
            dispersal_syndrome == "V" | dispersal_syndrome == "NV"  ~ "dani",
            # Autocoria
            dispersal_syndrome == "A" ~ "daut",
            str_detect(dispersal_syndrome, "-")  ~ "dvar",
            TRUE ~ dispersal_syndrome)) %>%

        # Rename levels in sexual_system column
        mutate(sexual_system_modified = case_when(
            # Dioecious
            sexual_system == "D"  ~ "ssdio",
            # Monoecious
            sexual_system == "M"  ~ "ssmon",
            # Hermaphroditic
            sexual_system == "H" ~ "ssher",
            TRUE ~ sexual_system)) %>%

        # Rename levels in pollination column
        mutate(pollination_syndrome_modified = case_when(
            # Wind
            pollination_syndrome == "W"  ~ "pwin",
            # Insects
            pollination_syndrome == "I"  ~ "pins",
            # Birds
            pollination_syndrome == "A" ~ "pbir",
            # Mammals
            pollination_syndrome == "MA" ~ "pmam",
            # Various
            str_detect(pollination_syndrome, "-")  ~ "pvar",
            TRUE ~ pollination_syndrome))  %>%

        # Add author
        add_column(source = "bsalgado dataset") %>%

        # Sort columns
        select(sort(current_vars())) %>%
        select(spcode, spcode_4_3, accepted_species, name_submitted,
               genero, especie, everything()) %>%
        arrange(genero, especie)


## Species with no traits in Salgado dataset
species_with_no_traits_58 <-
    raw_salgado_traits %>%
        select(-c(familia, autoridad)) %>%
        unite("name_submitted", genero, especie, sep = " ") %>%

        # Species with NO traits in Salgado dataset
        anti_join(species_list_updated_190, ., by = "name_submitted") %>%
        select(spcode, spcode_4_3, accepted_species, everything())

## Species with traits in Chazdon et al ----------------------------------------

## Load html original file
raw_chazdon_traits <-
    read_html("./data/raw_data/raw_chazdon_2003.html") %>% # nolint
        html_table(header = TRUE) %>%
        purrr::pluck(1)  %>%
        clean_names()

## Search
## nrow should be 12
data_chazdon_traits <-
    raw_chazdon_traits %>%

        # Remove column
        select(-c(life_form, family)) %>%

        # Remove \n\t and dots from strings
        mutate(across(2:4, str_replace_all,
                                pattern = "[\n\t]|[:digit:]|[(,)]|[.]|[ ]",
                                replacement = ""))  %>%

        # removing authority
        separate(species, c("genero", "especie")) %>%

        # Rename levels in dispersion column
        mutate(dispersal_syndrome_modified = case_when(
            # Wind
            dispersal_syndrome == "W"  ~ "dwin",
            # Animals
            dispersal_syndrome == "A" ~ "dani",
            # Autocoria
            dispersal_syndrome == "E" | dispersal_syndrome == "G"  ~ "daut",
            # Unknown
            dispersal_syndrome == "UN" ~ "NA",
            TRUE ~ dispersal_syndrome)) %>%

        # Rename levels in sexual_system column
        mutate(sexual_system_modified = case_when(
            # Dioecious
            sexual_system == "D"  ~ "ssdio",
            # Monoecious
            sexual_system == "M"  ~ "ssmon",
            # Hermaphroditic
            sexual_system == "H" ~ "ssher",
            # Unknown
            sexual_system == "UN" ~ "NA",
            TRUE ~ sexual_system)) %>%

        # Rename levels in pollination column
        mutate(pollination_syndrome_modified = case_when(
            # Wind
            pollination_syndrome == "W"  ~ "pwin",
            # Insects
            pollination_syndrome == "I"  ~ "pins",
            # Birds
            pollination_syndrome == "HB" ~ "pbir",
            # Mammals
            pollination_syndrome == "MA" ~ "pmam",
            # Unknown
            pollination_syndrome == "UN" ~ "NA",
            TRUE ~ pollination_syndrome)) %>%

        arrange(genero, especie)  %>%

        # Remove species identified at the genus level from the original dataset
        filter(!(str_detect(especie, "^sp") & (str_length(especie) <= 4))) %>%

        # Join columns for get full name use TNRS accepted species
        unite("species_name", genero, especie, sep = " ", remove = FALSE) %>%

        # Rename species names that are wrong
        mutate(species_name = case_when(
            species_name == "Cespedesia spathulata"  ~ "Cespedesia macrophylla",
            species_name == "Cojoba catenatum"  ~ "Cojoba catenata",
            species_name == "Inga thiboudiana" ~ "Inga thibaudiana",
            TRUE ~ species_name)) %>%

        # Get species with traits in Chazdon et al. Only 12 species found
        inner_join(species_with_no_traits_58, .,
                                by = c("name_submitted" = "species_name")) %>%

        add_column(source = "https://doi.org/10.6084/m9.figshare.c.3309012.v1")  %>%

        # Sort columns
        select(sort(current_vars())) %>%
        select(spcode, spcode_4_3, accepted_species, name_submitted,
               genero, especie, everything()) %>%
        arrange(genero, especie)

## Species with no traits
species_with_no_traits_46 <-
     data_chazdon_traits %>%
         anti_join(species_with_no_traits_58, .,
                        by = c("accepted_species" = "accepted_species")) %>%
         arrange(accepted_species)

# Total of 46 species with no traits

## Species identified by Nelson Zamora -----------------------------------------

## Load data
raw_zamora_traits <-
    read_xlsx("./data/raw_data/raw_nzamora_original.xlsx") %>%
    clean_names() %>%
    select(-familia)

## Search
data_zamora_traits <-
    raw_zamora_traits %>%

        # Join columns for get full name
        unite("name_submitted", genero, especie, sep = " ", remove = F) %>%

        select(-tipo_de_dispersion_original) %>%

        # Rename columns
        rename(dispersal_syndrome = "tipo_de_dispersion",
               sexual_system = "sistema_sexual",
               pollination_syndrome = "agente_polinizador")  %>%

        # Rename levels in dispersion column
        mutate(dispersal_syndrome_modified = case_when(
            # Wind
            dispersal_syndrome == "W"  ~ "dwin",
            # Hidrocoria
            dispersal_syndrome == "H"  ~ "dhid",
            # Animals
            dispersal_syndrome == "A" | dispersal_syndrome == "NW" | dispersal_syndrome == "AN"  ~ "dani",
            # Autocoria
            dispersal_syndrome == "E" ~ "daut",
            str_detect(dispersal_syndrome, ",")  ~ "dvar",
            TRUE ~ dispersal_syndrome)) %>%

        # Rename levels in sexual_system column
        mutate(sexual_system_modified = case_when(
            # Dioecious
            sexual_system == "D"  ~ "ssdio",
            # Monoecious
            sexual_system == "M"  ~ "ssmon",
            # Hermaphroditic
            str_detect(sexual_system, pattern = "[bisexual]|[H]") ~ "ssher",
            TRUE ~ sexual_system)) %>%

        # Rename levels in pollination column
        mutate(pollination_syndrome_modified = case_when(
            # Wind
            pollination_syndrome == "W"  ~ "pwin",
            # Mammals
            str_detect(pollination_syndrome, pattern = "murc") ~ "pmam",
            # Insects
            str_detect(pollination_syndrome, pattern = "[bee]|[insec]|[I]")  ~ "pins",
            # Birds
            pollination_syndrome == "HB" ~ "pbir",
            TRUE ~ pollination_syndrome))  %>%

        arrange(name_submitted) %>%
        inner_join(species_with_no_traits_46 ,. , by = "name_submitted") %>%

        add_column(source = "Nelson Zamora, personal communication") %>%

        # Sort columns
        select(sort(current_vars())) %>%
        select(spcode, spcode_4_3, accepted_species, name_submitted,
               genero, especie, everything(),
               # Remove columns
               -c(info)) %>%
        arrange(genero, especie)

# 33 species identified by NZamora

# Bisexual: each flower of each individual has both male and female structures
# hermaphroditism, the condition of having both male and female reproductive
# organs. bisexual == herma ssher

## Species with no traits
species_with_no_traits_13 <-
    data_zamora_traits %>%

    # Join columns for get full name
    unite("name_submitted", genero, especie, sep = " ") %>%

    # Species with traits identyfied by Nelson Zamora
    anti_join(species_with_no_traits_46, ., by = "name_submitted")

# 13 species with no traits at this point

## Species identified by Orlando Vargas ----------------------------------------
#raw_data_vargas <-
#     extract_tables("./data/raw_data/lista_arboles_sindromes_OVR05.pdf",
#
#                                    # Read this pages
#                                    pages = c(1:14),
#                                    method = "lattice")
#
# save(raw_data_vargas,
#        file = "./data/raw_data/response_traits/raw_data_vargas.RData")
load("./data/raw_data/raw_data_vargas.RData")

## Search
data_vargas_traits <-
    map_dfr(raw_data_vargas, as_tibble) %>%
        row_to_names(row_number = 1) %>%
        clean_names() %>%

        # Column poli-viento not included
        # only three species Weinmannia pinnata,Eschweilera costaricensis
        # Sorocea pubivena poli by wind
        rename(dis_mamifero = "x",
                dis_aves     = "x_2",
                dis_viento   = "x_3",
                dis_agua     = "x_4",
                gravedad_explosion = "x_5",
                comentarios_1 = "x_6",
                poli_aves = "x_7",
                poli_mamiferos = "x_8",
                poli_insectos = "x_9",
                poli_viento = "x_10",
                comentarios_2 = "x_11",
                sexual_system = "sistema_sexual_bisexual_monoica_dioica_unisexual_poligama_poligama_dioica") %>%
        select(-c(autores, nombre_comun, comentarios_1, comentarios_2))  %>%

        unite("name", genero, especie, sep = " ", remove = FALSE) %>%
        # Rename species names that are wrong
        mutate(name = case_when(
            name == "Tabebuia chrysantha??"  ~ "Tabebuia chrysantha",
            TRUE ~ name)) %>%

        # Select the species that I need, 10 species with traits
        inner_join(species_with_no_traits_13, .,
                   by = c("name_submitted" = "name"))   %>%

        # Rename levels in dispersal columns
        mutate(
            # Animals
            dis_mamifero = case_when(
                dis_mamifero == 1 ~ "dani",
                TRUE ~ dis_mamifero),

            dis_aves = case_when(
                dis_aves == 1 ~ "dani",
                TRUE ~ dis_aves),
            # Wind
            dis_viento = case_when(
                dis_viento == 1 ~ "dwin",
                TRUE ~ dis_viento),
            # Hidrocoria
            dis_agua = case_when(
                dis_agua == 1 ~ "dhid",
                TRUE ~ dis_agua),
            # Autocoria
            gravedad_explosion = case_when(
                gravedad_explosion == 1 ~ "daut",
                TRUE ~ gravedad_explosion)) %>%

            # Rename levels in dispersal columns
            mutate(
              # Birds
              poli_aves = case_when(
                  poli_aves == 1 ~ "pbir",
                  TRUE ~ poli_aves),
              # Mammals
              poli_mamiferos = case_when(
                  poli_mamiferos == 1 ~ "pmam",
                  TRUE ~ poli_mamiferos),
              # Insects
              poli_insectos = case_when(
                  poli_insectos == 1 ~ "pins",
                  TRUE ~ poli_insectos),
              # Wind
              poli_viento = case_when(
                  poli_viento == 1 ~ "pwin",
                  TRUE ~ poli_viento))   %>%

        # Create new colums
        unite(dispersal_syndrome_modified, 8:12, sep = "_")  %>%
        unite(pollination_syndrome_modified, 9:12, sep = "_")  %>%

        # Delete special characters
        mutate(across(8:ncol(.), str_replace_all,
                      pattern = "__|[*]|[?]",replacement = ""))  %>%

        # Add category dvar for species with more than 1
        mutate(dispersal_syndrome_modified = case_when(
            str_detect(dispersal_syndrome_modified, "_")  ~ "dvar",
            TRUE ~ dispersal_syndrome_modified)) %>%

        # Remove underscore from pins
         mutate(across(9, str_replace_all, pattern = "_", replacement = "")) %>%

        # Rename sexual system
        mutate(sexual_system_modified = case_when(
            sexual_system == "B"  ~ "ssher"))  %>%

         # Remove columns
        select(-c(familia, sexual_system))  %>%

        add_column(source = "https://sura.ots.ac.cr/florula4/docs/lista_arboles_sindromes_OVR05.pdf")


## Get morpho-species ----------------------------------------------------------
#morpho_species <-
#        original_species_list %>%
#
#        # Get morphospecies
#        filter((str_detect(especie, "^sp") & (str_length(especie) <= 4)))  %>%
#
#        arrange(genero)  %>%
#
#        # Set first letter to uppercase
#        mutate(genero = str_to_title(genero))  %>%
#
#        group_by(genero)  %>%
#
#        # Name morpho-species in a sequential manner
#        mutate(especie = paste0("sp", row_number()))  %>%
#
#        unite("accepted_species", c(genero, especie), sep = " ",
#                                                        remove = TRUE)
#        ungroup() %>%
#        select(-c(familia, X)) %>%
#        arrange(spcode) %>%
#        View()
#
## Manual input ----------------------------------------------------------------
manual_input  <-
    tribble(~spcode, ~spcode_4_3, ~accepted_species, ~genero, ~especie, ~dispersal_syndrome_modified, ~pollination_syndrome_modified, ~sexual_system_modified, ~source,
        "cecrpe", "cecrpel", "Cecropia peltata", "Cecropia", "peltata","dani","dwin","ssdio",
        "http://www.ecofog.gf/img/pdf/bibliographic_synthesis_ruth_tchana_thomas_monjoin_master_2_bioget_cecropia.pdf",
        "tabral", "tabealb", "Tabernaemontana alba", "Tabernaemontana","alba","","","","",
        "pescar","tabearb", "Tabernaemontana arborea", "Tabernaemontana","arborea","","","","")


## Join data sets --------------------------------------------------------------
reproductive_traits_190 <-

        # Salgado data
        full_join(data_salgado_traits %>% select(-c(name_submitted, genero,
                                                especie,dispersal_syndrome,
                                                pollination_syndrome,
                                                sexual_system)),
         #Chazdon Data
                data_chazdon_traits %>% select(-c(name_submitted, genero,
                                                especie, dispersal_syndrome,
                                                pollination_syndrome,
                                                sexual_system)),
                by = c("accepted_species", "dispersal_syndrome_modified",
                        "pollination_syndrome_modified",
                        "sexual_system_modified", "source", "spcode",
                        "spcode_4_3")) %>%

        # Zamora data
        full_join(., data_zamora_traits %>% select(-c(name_submitted, genero,
                                                especie, dispersal_syndrome,
                                                pollination_syndrome,
                                                sexual_system)),
                by = c("accepted_species", "dispersal_syndrome_modified",
                        "pollination_syndrome_modified",
                        "sexual_system_modified", "source", "spcode",
                        "spcode_4_3")) %>%

        # Vargas data
        full_join(., data_vargas_traits %>% select(-c(name_submitted, genero,
                                                    especie)),
                by = c("accepted_species", "dispersal_syndrome_modified",
                                        "pollination_syndrome_modified",
                                        "sexual_system_modified", "source",
                                        "spcode", "spcode_4_3")) %>%


         # Change D-P H-D value
        mutate(sexual_system_modified = case_when(
                sexual_system_modified == "D-P" | sexual_system_modified == "H-D" ~ "ssdio",
                TRUE ~ sexual_system_modified)) %>%


        # Add morpho species
        # Here column genero is generated
        #full_join(., morpho_species,
        #        by = c("accepted_species", "spcode")) %>%

        # Manual input
        full_join(., manual_input %>% select(-c(genero, especie)),
                by = c("accepted_species", "dispersal_syndrome_modified",
                     "pollination_syndrome_modified", "sexual_system_modified",
                     "source", "spcode", "spcode_4_3")) %>%

        # Replace empty values with NA
        mutate_all(na_if, "") %>%


        arrange(accepted_species) %>%
        select(accepted_species, spcode, spcode_4_3, everything())


# Check species with NAs
#reproductive_traits_190[!complete.cases(reproductive_traits_190),]

# Manual edits, this info comes from Rolando Perez dataset
reproductive_traits_190[169, c(4, 5, 6, 7)] <- c("dani", NA, "ssher", "RPerez")

# Replace "NA" with <NA>
reproductive_traits_190[30, 5] <- NA

# Save db ----------------------------------------------------------------------
write.csv(reproductive_traits_190, "./data/cleaned_data/reproductive_traits_190.csv")

# Clean env at the end ----------------------------------------------------------
rm(list = ls())