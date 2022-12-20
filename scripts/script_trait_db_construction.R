# Objective --------------------------------------------------------------------
# This script takes all the raw files contaning the traits and creates a dataset
# called traits_db
here::i_am("data_analysis/scripts/script_trait_db_construction.R")


# Load Packages ----------------------------------------------------------------
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


# Species list -----------------------------------------------------------------
species_list <- read.csv("./data/cleaned_data/species_list.csv", header = TRUE) %>%
                select(-X)

# Taxonomic name resolution service --------------------------------------------
tnrs_species_list <- read.csv("./data/cleaned_data/tnrs_names.csv", header = TRUE) %>%
                        clean_names()

# Full species list -----------------------------------------------------------

# Create spcode with the first 4 characters from the genus and the first 3
# letters from species

species_list_new_spcodes <-
    species_list %>%

        # Step done if mophospecies name == sp get it,
        # elif mophospecies name == sp{:digit:} get the 4 characters i.e sp01

        # First get the first 4 letters from the genus
        mutate(gen4 = str_extract(genero, "^.{4}"),

                # get the first 3 letters from the species
                sp3 = if_else(str_length(especie) == 2,
                                        str_extract(especie, "^.{2}"), # nolint

                                        if_else((str_length(especie) > 2) & (str_length(especie) <= 4) & (str_detect(especie, "^sp")), # nolint

                                     # Extract
                                     str_extract(especie, "^.{4}"),

                                     # ELSE
                                     str_extract(especie, "^.{3}")))) %>%

        unite(spcode_4_3, c("gen4", "sp3"), sep = "") %>%
        arrange(spcode)

# Get only the spcodes and names -----------------------------------------------
names_spcodes <-
    species_list_new_spcodes %>%
        mutate(genero = str_to_title(genero)) %>%

        # Create name_submitted column
        unite(name_submitted, c(genero, especie), sep = " ", remove = FALSE) %>%

        # Remove morphospecies
        filter(!(str_detect(especie, "^sp") & (str_length(especie) <= 4))) %>%

        select(-c(genero, especie, familia))

# Add spcodes 4-3 to the TNRS file ---------------------------------------------
tnrs_species_list <-
    tnrs_species_list %>%
        select(-id) %>%
        inner_join(., names_spcodes, by = "name_submitted") %>%
        select(spcode, spcode_4_3, everything())

# Full species list with new spcodes -------------------------------------------
# This list only shows the accepted name and the old name
species_list_updated <-
    tnrs_species_list %>%

        # Species' name manually changed
        mutate(accepted_species = case_when(
            name_submitted == "Billia colombiana" ~ "Putzeysia rosea",
            name_submitted == "Hyeronima oblonga" ~ "Stilaginella oblonga",
            TRUE ~ accepted_species))  %>%

        select(spcode, spcode_4_3, name_submitted, taxonomic_status,
               accepted_species) %>%
        arrange(name_submitted) %>%

        # In this list Brosimum panamense is treat as a different species
        # and is not. Removed
        filter(!name_submitted == "Brosimum panamense",
               !name_submitted == "Hirtella media") %>%

        select(-taxonomic_status)

# Get Reproductive traits ------------------------------------------------------
# In this section I got the reproductive traits for the species in the list and
# I joined them into a single dataset


## Species with traits in Salgado dataset --------------------------------------

## Load data

raw_salgado_traits <-
                read_xls("./data/raw_data/raw_salgado_original.xls") %>%
                clean_names()

## Search
data_salgado_traits <-
    raw_salgado_traits %>%
        select(-c(familia, autoridad)) %>%
        unite("name_submitted", genero, especie, sep = " ", remove = FALSE)  %>%

        # Species with traits in Salgado dataset. Should be 132
        inner_join(species_list_updated, ., by = "name_submitted")  %>%
        select(accepted_species, everything(),
               -c(estrato,tasacrecimiento,rep_vegetativa)) %>%

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

## List the species with traits in Salgado data
data_salgado_traits %>%
        select(-c(spcode, spcode_4_3, genero,especie, source, name_submitted)) %>%
        unite(dispersal_syndrome, c(2:3), sep = "/")  %>%
        unite(pollination_syndrome, c(3:4), sep = "/") %>%
        unite(sexual_system, c(4:5), sep = "/")

## Species with no traits in Salgado dataset
species_with_no_traits_58 <-
    raw_salgado_traits %>%
        select(-c(familia, autoridad)) %>%
        unite("name_submitted", genero, especie, sep = " ") %>%

        # Species with NO traits in Salgado dataset
        anti_join(species_list_updated, ., by = "name_submitted") %>%
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

        # Step for removing authority
        separate(species, c("genero", "especie"))    %>%

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

        arrange(genero, especie) %>%

        # Join columns for get full name use TNRS accepted species
        # Remove morphospecies
        filter(!(str_detect(especie, "^sp") & (str_length(especie) <= 4))) %>%
        unite("species_name", genero, especie, sep = " ", remove = F) %>%

        # Rename species names that are wrong
        mutate(species_name = case_when(
            species_name == "Cespedesia spathulata"  ~ "Cespedesia macrophylla",
            species_name == "Cojoba catenatum"  ~ "Cojoba catenata",
            species_name == "Inga thiboudiana" ~ "Inga thibaudiana",
            TRUE ~ species_name))  %>%

        # Species with traits in Chazdon et al
        inner_join(species_with_no_traits_58, .,
                                by = c("name_submitted" = "species_name" )) %>%

        add_column(source = "https://doi.org/10.6084/m9.figshare.c.3309012.v1")  %>%

        # Sort columns
        select(sort(current_vars())) %>%
        select(spcode, spcode_4_3, accepted_species, name_submitted,
               genero, especie, everything()) %>%
        arrange(genero, especie)

## Species with no traits in Chazdon
species_with_no_traits_46 <-
     data_chazdon_traits %>%
         anti_join(species_with_no_traits_58, .,
                        by = c("accepted_species" = "accepted_species")) %>%
         arrange(accepted_species)

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

# Bisexual: each flower of each individual has both male and female structures
# hermaphroditism, the condition of having both male and female reproductive
# organs. bisexual == herma


## Species with no traits
species_with_no_traits_13 <-
    data_zamora_traits %>%

    # Join columns for get full name
    unite("name_submitted", genero, especie, sep = " ") %>%

    # Species with traits identyfied by Nelson Zamora
    anti_join(species_with_no_traits_46, ., by = "name_submitted")

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
        clean_names()   %>%

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

        # Select the species that I need
        inner_join(species_with_no_traits_13, .,
                   by = c("name_submitted" = "name"))  %>%

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
                  TRUE ~ poli_viento))  %>%

        # Create new colums
        unite(dispersal_syndrome_modified, 8:12, sep = "_")  %>%
        unite(pollination_syndrome_modified, 9:12, sep = "_")  %>%

        # Delete special characters
        mutate(across(8:ncol(.), str_replace_all,
                      pattern = "__|[*]|[?]",replacement = "")) %>%

        # Add category dvar for species with more than 1
        mutate(dispersal_syndrome_modified = case_when(
            str_detect(dispersal_syndrome_modified, "_")  ~ "dvar",
            TRUE ~ dispersal_syndrome_modified)) %>%

        # Remove underscore from pins
         mutate(across(9, str_replace_all, pattern = "_", replacement = "")) %>%

        # Remove columns
        select(-c(familia))  %>%

        # Rename sexual system
        mutate(sexual_system_modified = case_when(
            sexual_system == "B"  ~ "ssher")) %>%

        add_column(source = "https://sura.ots.ac.cr/florula4/docs/lista_arboles_sindromes_OVR05.pdf")  %>%
        arrange(genero, especie)

## Get morpho-species ----------------------------------------------------------
morpho_species <-
        species_list %>%

        # Get morphospecies
        filter((str_detect(especie, "^sp") & (str_length(especie) <= 4)))  %>%

        # Set first letter to uppercase
        mutate(genero = str_to_title(genero)) %>%

        select(-c(familia))  %>%
        group_by(genero) %>%

        # Name morpho-species in a sequential manner
        mutate(especie = paste0("sp", row_number())) %>%

        unite("accepted_species", c(genero, especie), sep = " ",
                                                        remove = FALSE) %>%

        arrange(accepted_species)

## Manual input ----------------------------------------------------------------
manual_input  <-
    tribble(~spcode, ~spcode_4_3, ~accepted_species, ~genero, ~especie, ~dispersal_syndrome_modified, ~pollination_syndrome_modified, ~sexual_system_modified, ~source,
        "cecrpe", "cecrpel", "Cecropia peltata", "Cecropia", "peltata","dani","dwin","ssdio",
        "http://www.ecofog.gf/img/pdf/bibliographic_synthesis_ruth_tchana_thomas_monjoin_master_2_bioget_cecropia.pdf",
        "tabral", "tabealb", "Tabernaemontana alba", "Tabernaemontana","alba","","","","",
        "pescar","tabearb", "Tabernaemontana arborea", "Tabernaemontana","arborea","","","","")


## Join data sets --------------------------------------------------------------
reproductive_traits_255 <-

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
                        "sexual_system_modified", "source","spcode",
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
                                                        especie,
                                                        sexual_system)),
                by = c("accepted_species", "dispersal_syndrome_modified",
                                        "pollination_syndrome_modified",
                                        "sexual_system_modified", "source",
                                        "spcode", "spcode_4_3")) %>%

        # Add morpho species
        # Here column genero is generated
        full_join(., morpho_species %>% select(-c(genero, especie)),
                by = c("accepted_species", "spcode"))  %>%

        # Manual input
        full_join(., manual_input %>% select(-c(genero, especie)),
                by = c("accepted_species", "dispersal_syndrome_modified",
                     "pollination_syndrome_modified", "sexual_system_modified",
                     "source", "spcode", "spcode_4_3")) %>%

        # Replace empty values with NA
        mutate_all(na_if, "") %>%

        # Change D-P H-D value
        mutate(sexual_system_modified = case_when(
                sexual_system_modified == "D-P" | sexual_system_modified == "H-D" ~ "ssdio",
                TRUE ~ sexual_system_modified)) %>%

        arrange(accepted_species)  %>%
        select(accepted_species, spcode, spcode_4_3, everything(), -c(genero, source))

# Get Wood density -------------------------------------------------------------

## Separate accepted name into genus and species
#wood_density_sp_list <-
#        morpho_species %>%
#
#        # Create column for joining the datasets
#        unite(accepted_species, genero, especie, sep = " ") %>%
#
#
#        # Join morpho-species with species with a full name n = 256
#        full_join(., species_list_updated, by = c("accepted_species", "spcode")) %>%
#
#        # Get column the accepted_species with morpho species n = 256
#        select(accepted_species) %>%
#
#        # Create columns for the function getWoodDensity
#        separate(accepted_species, c("genus", "specie"), sep = " ",
#                                        remove = FALSE)
#
### Get wood density values
#wood_density_255 <-
#        getWoodDensity(genus = wood_density_sp_list$genus,
#                species = wood_density_sp_list$specie,
#                region = c("CentralAmericaTrop", "SouthAmericaTrop"))  %>%
#
#        group_by(genus, species) %>%
#
#        # Name morpho-species in a sequential manner
#        mutate(species = if_else(species == "NA", paste0("sp", row_number()),
#                                                                species))  %>%
#
#        # Arrange columns and clean names
#        select(1:3, levelWD, everything())  %>%
#        clean_names() %>%
#        arrange(genus, species) %>%
#        unite(accepted_species, c("genus", "species"), sep = " ") %>%
#        select(-family) %>%
#        arrange(accepted_species)
#
### Exclude morpho-species
#wood_density_190 <-
#        wood_density_255 %>%
#                inner_join(., species_list_updated, by = "accepted_species") %>%
#                select(name_submitted, accepted_species,spcode, spcode_4_3, mean_wd)

# Get leaf P and N traits ------------------------------------------------------

## Load raw data
raw_traits_effect_data <-
    read.csv("./data/raw_data/raw_effect_traits.csv", header = TRUE) %>%

        clean_names() %>%
        dplyr::select(4:10) %>%
        mutate(across(where(is.character), str_to_lower)) %>%

        # Remove species
        filter(!coespec %in% c("brospa", "hirtme", "ruptca","quetoc", "maytgu"))

## Read trait data to get new spcodes ------------------------------------------
effect_traits_190 <-
        names_spcodes %>%
        inner_join(., raw_traits_effect_data, by = c("spcode" = "coespec")) %>%
        inner_join(., species_list_updated, by = c("name_submitted", "spcode",
                                                                "spcode_4_3")) %>%
        select(name_submitted, accepted_species, everything())

# Trait DB ---------------------------------------------------------------------
traits_db_190 <-

        inner_join(effect_traits_190, reproductive_traits_255, by = c("spcode",
                                                                    "spcode_4_3",
                                                        "accepted_species")) %>%

        mutate(n_p_ratio = n_mgg_1/p_mgg_1) %>%

        rename(wood_density_gcm3_1 = dm_gcm3_1,
                leaf_area_mm2 = af_mm2,
                sla_mm2mg_1 = afe_mm2mg_1,
                ldmc_mgg_1 = cfms_mgg_1)

# Save db ----------------------------------------------------------------------
write.csv(traits_db_190, "./data/cleaned_data/db_traits_190.csv")
