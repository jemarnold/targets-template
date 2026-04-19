# takes in a data frame and channel (column name)
# returns a one-row data frame with the mean value, identified by id and date
daily_mean_row <- function(id, file_paths, data, channel) {
    ## allows for 'non-standard evaluation' of column name without quotes
    col_name <- rlang::as_label(rlang::enquo(channel))

    # returns a one-row data frame with mean of the channel, named by the channel using data masking provided by {rlang} and {dplyr}
    tibble(
        id = id,
        date = str_extract(basename(file_paths), "\\d{4}-\\d{2}-\\d{2}"),
        !!col_name := mean(data[[col_name]], na.rm = TRUE)
    )
}
