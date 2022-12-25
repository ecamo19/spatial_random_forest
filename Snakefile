rule targets:
        input:
                "data/cleaned_data/original_species_list.csv",
                "data/cleaned_data/tnrs_names.csv",
                "data/cleaned_data/species_list_updated.csv",
                "data/raw_data/raw_salgado_original.xls",
                "data/raw_data/raw_chazdon_2003.html",
                "data/raw_data/raw_nzamora_original.xlsx",
                "data/raw_data/raw_data_vargas.RData",
                "data/raw_data/raw_effect_traits.csv",
                "data/cleaned_data/traits_db_255.csv",
                "data/cleaned_data/env_data.csv",
                "data/raw_data/raw_species_basal_area.xlsx",
                "data/raw_data/lat_long_plots.csv",
                "data/cleaned_data/plot_agb.csv"

rule get_original_species_list:
        input:
                script = "scripts/script_get_original_species_list.R",
                data = "data/raw_data/raw_effect_traits.csv"
        output:
                data = "data/cleaned_data/original_species_list.csv"
        shell:
                """
                Rscript {input.script} \
                        --data {input.data} \
                        --out {output.data}
                """

rule get_tnrs_and_species_list_updated:
        input:
                script = "scripts/script_get_tnrs_and_species_list_updated.R",
                data = "data/cleaned_data/original_species_list.csv"
        output:
                data_1 = "data/cleaned_data/tnrs_names.csv",
                data_2 = "data/cleaned_data/species_list_updated.csv"

        shell:
                """
                Rscript {input.script} \
                        --data {input.data} \
                        --out {output.data_1} \
                        --out {output.data_2}
                """
rule get_reproductive_traits:
        input:
                script = "scripts/script_get_reproductive_traits.R",
                data_1 = "data/cleaned_data/species_list_updated.csv",
                data_2 = "data/raw_data/raw_salgado_original.xls",
                data_3 = "data/raw_data/raw_chazdon_2003.html",
                data_4 = "data/raw_data/raw_nzamora_original.xlsx",
                data_5 = "data/raw_data/raw_data_vargas.RData"
        output:
                data = "data/cleaned_data/reproductive_traits_190.csv"
        shell:
                """
                Rscript {input.script} \
                        --data {input.data_1} \
                        --data {input.data_2} \
                        --data {input.data_3} \
                        --data {input.data_4} \
                        --data {input.data_5} \
                        --out {output.data}
                """

rule create_traits_db:
        input:
                script = "scripts/script_trait_db_construction.R",
                data_1 = "data/cleaned_data/species_list_updated.csv",
                data_2 = "data/cleaned_data/reproductive_traits_190.csv",
                data_3 = "data/raw_data/raw_effect_traits.csv"

        output:
                data = "data/cleaned_data/traits_db_255.csv"
        shell:
                """
                Rscript {input.script} \
                        --data {input.data_1} \
                        --data {input.data_2} \
                        --data {input.data_3} \
                        --out {output.data}
                """

rule create_env_data:
        input:
                script = "scripts/script_create_env_data.R",
                data = "data/raw_data/raw_plot_enviroment.xlsx"
        output:
                data = "data/cleaned_data/env_data.csv"
        shell:
                """
                Rscript {input.script} \
                        --data {input.data} \
                        --out {output.data}
                """

rule calculate_plot_agb:
        input:
                script = "scripts/script_calculate_plot_agb.R",
                data_1 = "data/raw_data/raw_species_basal_area.xlsx",
                data_2 = "data/raw_data/lat_long_plots.csv",
                data_3 = "data/cleaned_data/traits_db_255.csv"
        output:
                data = "data/cleaned_data/plot_agb.csv"
        shell:
                """
                Rscript {input.script} \
                        --data {input.data_1} \
                        --data {input.data_2} \
                        --data {input.data_3} \
                        --out {output.data}
                """

#rule create_species_abundance_data:
#Remember to remove sps

#rule create_functional_diversity_data:

#rule create_data_set_for_stats:
