rule targets:
        input:
                "data/cleaned_data/species_list.csv",
                "data/cleaned_data/tnrs_names.csv",
                "data/raw_data/raw_salgado_original.xls",
                "data/raw_data/raw_chazdon_2003.html",
                "data/raw_data/raw_nzamora_original.xlsx",
                "data/raw_data/raw_data_vargas.RData",
                "data/cleaned_data/db_traits_190.csv",
                "data/cleaned_data/env_data.csv"

rule get_species_list:
        input:
                script = "scripts/script_get_species_list.R",
                data = "data/raw_data/raw_effect_traits.csv"
        output:
                data = "data/cleaned_data/species_list.csv"
        shell:
                """
                Rscript {input.script} \
                        --data {input.data} \
                        --out {output.data}
                """

rule get_tnrs_names:
        input:
                script = "scripts/script_get_tnrs_names.R",
                data = "data/cleaned_data/species_list.csv"
        output:
                data = "data/cleaned_data/tnrs_names.csv"
        shell:
                """
                Rscript {input.script} \
                        --data {input.data} \
                        --out {output.data}
                """

rule create_traits_db:
        input:
                script = "scripts/script_trait_db_construction.R",
                data_1 = "data/cleaned_data/species_list.csv",
                data_2 = "data/cleaned_data/tnrs_names.csv",
                data_3 = "data/raw_data/raw_salgado_original.xls",
                data_4 = "data/raw_data/raw_chazdon_2003.html",
                data_5 = "data/raw_data/raw_nzamora_original.xlsx",
                data_6 = "data/raw_data/raw_data_vargas.RData"
        output:
                data = "data/cleaned_data/db_traits_190.csv"
        shell:
                """
                Rscript {input.script} \
                        --data {input.data_1} \
                        --data {input.data_2} \
                        --data {input.data_3} \
                        --data {input.data_4} \
                        --data {input.data_5} \
                        --data {input.data_6} \
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
#rule create_species_abundance_data_cleaned:

#rule create_plot_agb_data_cleaned:

#rule create_functional_diversity_data_cleaned:

#rule create_data_set_for_stats_cleaned:
