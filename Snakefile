rule targets:
        input:
                "data/cleaned_data/species_list.csv",
                "data/cleaned_data/tnrs_names.csv"
                #"data/raw_data/raw_salgado_original.xls",
                #"data/raw_data/raw_chazdon_2003.html",
                #"data/raw_data/raw_nzamora_original.xlsx",
                #"data/raw_data/raw_data_vargas.RData",
                #"data/cleaned_data/db_traits_190.csv"

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

#rule create_traits_db:
#        input:
#                script = "scripts/script_trait_db_construction.R",
#                "data/cleaned_data/species_list.csv",
#                "data/cleaned_data/tnrs_names.csv",
#                "data/raw_data/raw_salgado_original.xls",
#                "data/raw_data/raw_chazdon_2003.html",
#                "data/raw_data/raw_nzamora_original.xlsx",
#                "data/raw_data/raw_data_vargas.RData"
#
#        output:
#                "data/cleaned_data/db_traits_190.csv"
#        shell:
#                """
#                Rscript {input.script} \
#                        --data {input} \
#                        --out {output}
#                """
