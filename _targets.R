#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

## Setup ======================================
# Load packages required to define the pipeline:
suppressPackageStartupMessages({
    library(targets)
    library(tarchetypes)
    library(tidyverse)
})

# Set target options:
tar_option_set(
    packages = c("tidyverse", "epl")
    # Set other options as needed.
)

# source all scripts in the R/ folder with your custom functions:
tar_source()
# tar_source("other_functions.R") # Source other scripts as needed.

# extract id from folder names
ids <- list.dirs("raw data", recursive = FALSE, full.names = FALSE)

## processing ========================================================
## static branch over ids
processing <- tar_map(
    values = list(id = ids),
    names = id,

    ## monitor folder if files are modified/added/removed
    tar_target(
        name = folder,
        command = file.path("raw data", id),
        format = "file"
    ),

    ## plain list of files per id
    tar_target(
        name = file_paths,
        command = list.files(folder, full.names = TRUE)
    ),

    ## dynamic branch: map over file_paths per id
    tar_target(
        name = parvo_data,
        command = epl::read_parvo(file_paths)$data,
        pattern = map(file_paths),
        iteration = "list"
    ),

    ## summarise mean data per date per id
    tar_target(
        name = vo2_summary_row,
        ## this function is sourced from `R/1_processing.R`
        command = daily_mean_row(id, file_paths, parvo_data, VO2),
        pattern = map(file_paths, parvo_data)
    )
)

## aggregate summary data across all dates in participants
results <- list(
    tar_combine(
        name = vo2_summary,
        processing[["vo2_summary_row"]], ## intake "summary" objects from `processing` pipe
        command = {
            ## binds together each "summary" row into a single data frame
            combined_data <- dplyr::bind_rows(!!!.x)
            ## define file path
            file_path <- file.path("processed data", "vo2_summary.xlsx")
            ## save combined data to file path
            writexl::write_xlsx(combined_data, path = file_path)
            ## return the file path that you saved to
            ## and `format = "file"` to tell `tar_combine` to monitor this file
            return(file_path)
        },
        format = "file"
    )
)

## execute ========================================================
list(
    processing,
    results
)
