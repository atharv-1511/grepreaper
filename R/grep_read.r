#' Read and filter data from one or more files using grep
#' 
#' This function reads data from one or more files after filtering it with grep.
#' It allows for flexible pattern matching and leverages data.table's fread for efficient data import.
#' 
#' @param files Character vector of file paths.
#' @param pattern Pattern to search for.
#' @param invert Logical; if TRUE, return non-matching lines.
#' @param ignore_case Logical; if TRUE, perform case-insensitive matching.
#' @param fixed Logical; if TRUE, pattern is a fixed string, not a regular expression.
#' @param show_cmd Logical; if TRUE, print the grep command used.
#' @param recursive Logical; if TRUE, search recursively through directories.
#' @param word_match Logical; if TRUE, match only whole words.
#' @param nrows Integer; maximum number of rows to read, passed to fread.
#' @param skip Integer; number of rows to skip, passed to fread.
#' @param header Logical; indicates if the data has a header row, passed to fread.
#' @param col.names Character vector of column names, passed to fread.
#' @param ... Additional arguments passed to fread.
#' 
#' @return A data.table containing the matched data (or command string if show_cmd=TRUE).
#' 
#' @examples
#' \dontrun{
#' # Read lines containing "IT" from sample_data.csv
#' it_employees <- grep_read("data/sample_data.csv", "IT")
#' 
#' # Read lines not containing "IT"
#' non_it_employees <- grep_read("data/sample_data.csv", "IT", invert = TRUE)
#' 
#' # Read from multiple files with the same structure
#' all_data <- grep_read(c("data/file1.csv", "data/file2.csv"), "pattern")
#' 
#' # Read only specific lines with header control
#' top_rows <- grep_read("data/sample_data.csv", "pattern", nrows = 10, header = TRUE)
#' }
#' 
#' @importFrom data.table fread
#' @export
grep_read <- function(files, pattern, invert = FALSE, ignore_case = FALSE, 
                      fixed = FALSE, show_cmd = FALSE, recursive = FALSE,
                      word_match = FALSE, nrows = Inf, skip = 0, 
                      header = TRUE, col.names = NULL, ...) {
  
  # Input validation
  if (!is.character(files) || length(files) == 0) {
    stop("'files' must be a non-empty character vector")
  }
  if (!is.character(pattern) || length(pattern) != 1) {
    stop("'pattern' must be a single character string")
  }
  
  # Build grep options
  options <- ""
  if (invert) options <- paste(options, "-v")
  if (ignore_case) options <- paste(options, "-i")
  if (fixed) options <- paste(options, "-F")
  if (recursive) options <- paste(options, "-r")
  if (word_match) options <- paste(options, "-w")
  
  # For multiple files, ensure we know which file each row came from
  if (length(files) > 1 && !recursive) {
    options <- paste(options, "-H") # Include filename in the output
  }
  
  # Build the command
  cmd <- build_grep_cmd(pattern, files, options)
  
  # Return command if requested
  if (show_cmd) {
    return(cmd)
  }
  
  # Execute grep command
  result <- safe_system_call(cmd)
  
  # If no results, return empty data.table with appropriate structure
  if (length(result) == 0) {
    return(data.table::data.table())
  }
  
  # For multiple files, create a combined data frame with a source column
  if (length(files) > 1 && !recursive && any(grepl(":", result, fixed = TRUE))) {
    # Results will be in format "filename:content"
    # Split the results and create a data table with source information
    split_results <- lapply(result, function(line) {
      # Find the first colon that separates filename from content
      colon_pos <- regexpr(":", line, fixed = TRUE)
      if (colon_pos > 0) {
        filename <- substr(line, 1, colon_pos - 1)
        content <- substr(line, colon_pos + 1, nchar(line))
        return(list(filename = filename, content = content))
      } else {
        return(list(filename = "unknown", content = line))
      }
    })
    
    # Extract filenames and contents
    filenames <- sapply(split_results, function(x) x$filename)
    contents <- sapply(split_results, function(x) x$content)
    
    # Read the data with fread
    combined_text <- paste(contents, collapse = "\n")
    dt <- data.table::fread(text = combined_text, header = header, 
                           nrows = nrows, skip = skip, col.names = col.names, ...)
    
    # Add the source column if we have actual filenames
    if (length(unique(filenames)) > 1 || unique(filenames)[1] != "unknown") {
      dt[, source_file := filenames]
    }
    
    return(dt)
  } else {
    # Single file or recursive case - direct read
    dt <- data.table::fread(text = paste(result, collapse = "\n"), 
                           header = header, nrows = nrows, 
                           skip = skip, col.names = col.names, ...)
    return(dt)
  }
}
