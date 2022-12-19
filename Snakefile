rule get_species_list
        input:
                "./data/raw_data/data_effect_traits.csv"
        output:
                "data_cleaned/species_list.csv'
        parms:
        shell: