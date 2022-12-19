rule get_species_list:
        input:
                script = "scripts/script_get_species_list.R",
                data = "data/raw_data/data_effect_traits.csv"
        output:
                data = "data/cleaned_data/species_list.csv"
        shell:
                """
                Rscript {input.script} \
                        --data {input.data} \
                        --out {output.data}
                """