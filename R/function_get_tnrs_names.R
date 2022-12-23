get_tnrs_names <- function(genus, sp){

    # Format species name
    name <- paste0(str_to_title(genus), " ", sp)

    # Make the call to the database
    return(TNRS::TNRS(taxonomic_names = name))
}

