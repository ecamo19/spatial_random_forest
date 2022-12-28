# Objetive ----------------------------------------------------------------------
# Estimate the functional redundancy and diversity of each plot

# Load packages -----------------------------------------------------------------

library(FD)
library(gtools)
library(gawdis)
library(dplyr)
library(janitor)
library(tibble)
library(tidyr)
# For Box-Cox transformation
library(caret)

# Load function for calculating rendundancy -------------------------------------
source("./R/function_redundancy_ricotta_2016_original.R")

# Load data ---------------------------------------------------------------------

# Species abundance
species_abundance <- read.csv("./data/cleaned_data/species_abundance_data.csv",
                                header = TRUE) %>%
                select(-X) %>%
                column_to_rownames("parcela")

# Species traits
traits_db <- read.csv("./data/cleaned_data/traits_db_255.csv", header = TRUE) %>%
            select(-X)

# Select species traits to be used in the analisys ------------------------------
traits_selected_255 <-
    traits_db %>%
    select(spcode, sla_mm2mg_1, n_mgg_1, p_mgg_1, wood_density_gcm3_1,
            dispersal_syndrome_modified, sexual_system_modified)

# Trait dissimilarity matrix ----------------------------------------------------

## Problems with the Gower distance. Use gawdis instead

# It should be noticed that combining quantitative and qualitative traits can
# pose several problems, which are often not recognized in the literature.
#
# If we compute the dissimilarity for each trait and them combine these two
# dissimilarities with a simple average (or even with Euclidean distance,i.e
# geometric mean), the resulting dissimilarity will be affected much more by
# the binary trait than by the quantitative. In other words, the contribution of
# the binary trait to the overall dissimilarity will be disproportional.

# Check trait distributions -----------------------------------------------------

#par(mfrow = c(2, 3))
#traits_selected_255 %>%
#    dplyr::select(is.numeric) %>%
#    purrr::map2(colnames(.), ~hist(.x, main = .y))

# Box-cox transformation --------------------------------------------------------

#λ =  1.00: no transformation needed; produces results identical to original data
#λ =  0.50: square root transformation
#λ =  0.00: natural log transformation
#λ = -0.50: reciprocal square root transformation
#λ = -1.00: reciprocal (inverse) transformation

#traits_selected_255 %>%
#    dplyr::select(is.numeric) %>%
#    purrr::map(., BoxCoxTrans)

# sla_mm2mg_1 = 0 = log
# n_mgg_1 = 1.3 = no transformation
# p_mgg_1 = -0.1 = log
# wood_density_gcm3_1 = 1.6 =  ^2

# par(mfrow = c(3, 3))
# traits_selected_255 %>%
#     dplyr::select(is.numeric) %>%
#     mutate(wood_density_power_2 = wood_density_gcm3_1^2,
#             p_mgg_1_log = log(p_mgg_1),
#             sla_mm2mg_1_log = log(sla_mm2mg_1)) %>%
#     purrr::map2(colnames(.), ~hist(.x, main = .y))


# Tranform traits for improving normality ---------------------------------------
traits_selected_255_transformed <-
    traits_selected_255 %>%

        # Transform traits
        mutate(wood_density_power_2 = wood_density_gcm3_1^2,
                p_mgg_1_log = log(p_mgg_1),
                sla_mm2mg_1_log = log(sla_mm2mg_1)) %>%

        # Remove traits
        select(-c(sla_mm2mg_1, wood_density_gcm3_1, p_mgg_1)) %>%

        # Arrange cols
        select(1, 2, 6, 7, 5, everything()) %>%
        arrange(spcode)  %>%

        column_to_rownames("spcode") %>%

        # Transform characters to factors
        mutate(across(where(is.character), as.factor))

# Create trait matrix distance --------------------------------------------------
distance_matrix_groups <- gawdis(traits_selected_255_transformed,
                                w.type = "optimized",
                                opti.maxiter = 1000,
                                groups.weight = TRUE,

                                # Group leaf traits
                                groups = c(1, 1, 1, 2, 3, 4))

attr(distance_matrix_groups, "weights")
corr_gaw_groups <- attr(distance_matrix_groups, "correls")
corr_gaw_groups[7] <- attr(distance_matrix_groups, "group.correls")[1]
names(corr_gaw_groups)[7] <- "n_mgg_1-p_mgg_1_log-sla_mm2mg_1_log"
corr_gaw_groups


# dbFD weighted -----------------------------------------------------------------
dbfd_weight_df <-
    dbFD(distance_matrix_groups,
            species_abundance,
            corr = "cailliez",
            calc.FDiv = FALSE,
            calc.FRic = FALSE,
            calc.CWM = FALSE,
            calc.FGR = FALSE,
            w.abun = TRUE) %>%
    as.data.frame(.) %>%
    clean_names() %>%
    select(f_dis, f_eve, rao_q) %>%
    rownames_to_column("plot")

# dbFD unweighted ---------------------------------------------------------------
dbfd_df <-
    dbFD(distance_matrix_groups,
            species_abundance,
            corr = "cailliez",
            calc.FDiv = FALSE,
            calc.FRic = FALSE,
            calc.CWM = FALSE,
            calc.FGR = FALSE,
            w.abun = FALSE) %>%
    as.data.frame(.) %>%
    clean_names() %>%
    select(f_dis, f_eve, rao_q) %>%
    rownames_to_column("plot")

# Functional Redundancy ---------------------------------------------------------
# quadratic diversity: Q
# community-level functional uniqueness: U
# Species number per plot: N
# Simpson Index: D

redundancy_and_functional_diversity <-
                uniqueness(species_abundance, distance_matrix_groups,
                        abundance = FALSE)$red  %>%

                # Calculate redundancy
                mutate(redundancy = (D - Q)/ D) %>%
                rownames_to_column("plot") %>%

                # Join Diversity and redundancy dataframes
                inner_join(., dbfd_df, by = "plot") %>%
                clean_names()

# Save data ---------------------------------------------------------------------
write.csv(redundancy_and_functional_diversity,
                "./data/cleaned_data/redundancy_and_functional_diversity.csv")

# Clean env at the end ----------------------------------------------------------
rm(list = ls())