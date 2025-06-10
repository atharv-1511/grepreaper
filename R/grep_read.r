#' Read and filter data from one or more files using grep
#' 
#' This function reads data from one or more files after filtering it with grep.
#' It allows for flexible pattern matching and leverages data.table's fread for efficient data import.
#' 
#' @param files Character vector of file paths.
#' @param pattern Pattern to search for.
#' @param invert Logical; if TRUE, return non-matching lines (using grep -v).
#' @param ignore_case Logical; if TRUE, perform case-insensitive matching.
#' @param fixed Logical; if TRUE, pattern is a fixed string, not a regular expression.
#' @param show_cmd Logical; if TRUE, print the grep command used.
#' @param recursive Logical; if TRUE, search recursively through directories.
#' @param word_match Logical; if TRUE, match only whole words.
#' @param show_line_numbers Logical; if TRUE, include line numbers from source files.
#' @param count_only Logical; if TRUE, return only the count of matching lines.
#' @param nrows Integer; maximum number of rows to read, passed to fread.
#' @param skip Integer; number of rows to skip, passed to fread.
#' @param header Logical; if TRUE, treat first row as header. If FALSE, no header is used.
#' @param col.names Character vector of column names, passed to fread.
#' @param include_filename Logical; if TRUE, include source filename as a column (default: TRUE for multiple files).
#' @param ... Additional arguments passed to fread.
#' 
#' @return A data.table containing the matched data (or command string if show_cmd=TRUE).
#'         If count_only=TRUE, returns a data.table with file names and their match counts.
#' 
#' @examples
#' \dontrun{
#' # Read lines containing "IT" from sample_data.csv
#' it_employees <- grep_read("data/sample_data.csv", "IT")
#' 
#' # Read lines not containing "IT" (inverted search)
#' non_it_employees <- grep_read("data/sample_data.csv", "IT", invert = TRUE)
#' 
#' # Read from multiple files with the same structure
#' all_data <- grep_read(c("data/file1.csv", "data/file2.csv"), "pattern")
#' 
#' # Read only specific lines with header control
#' top_rows <- grep_read("data/sample_data.csv", "pattern", nrows = 10, header = TRUE)
#' 
#' # Count matching lines
#' match_counts <- grep_read("data/sample_data.csv", "IT", count_only = TRUE)
#' }
#' 
#' @importFrom data.table fread
#' @export
grep_read <- function(files, pattern, invert = FALSE, ignore_case = FALSE, 
                      fixed = FALSE, show_cmd = FALSE, recursive = FALSE,
                      word_match = FALSE, show_line_numbers = FALSE,
                      count_only = FALSE, nrows = Inf, skip = 0, 
                      header = TRUE, col.names = NULL, include_filename = NULL, ...) {
  
  # Input validation
  if (!is.character(files) || length(files) == 0) {
    stop("'files' must be a non-empty character vector")
  }
  if (!is.character(pattern) || length(pattern) != 1) {
    stop("'pattern' must be a single character string")
  }
  
  # Set default for include_filename based on number of files
  if (is.null(include_filename)) {
    include_filename <- length(files) > 1 && !recursive
  }
  
  # Build grep options
  options <- ""
  if (invert) options <- paste(options, "-v")
  if (ignore_case) options <- paste(options, "-i")
  if (fixed) options <- paste(options, "-F")
  if (recursive) options <- paste(options, "-r")
  if (word_match) options <- paste(options, "-w")
  if (show_line_numbers) options <- paste(options, "-n")
  if (count_only) options <- paste(options, "-c")
  
  # For multiple files, ensure we know which file each row came from
  if (include_filename && !count_only) {
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
    if (count_only) {
      return(data.table::data.table(file = files, count = 0))
    }
    return(data.table::data.table())
  }
  
  # Handle count-only results
  if (count_only) {
    # Parse the count results
    count_data <- lapply(result, function(line) {
      parts <- strsplit(line, ":", fixed = TRUE)[[1]]
      if (length(parts) == 2) {
        return(list(file = parts[1], count = as.integer(parts[2])))
      } else {
        return(list(file = "unknown", count = as.integer(line)))
      }
    })
    
    # Create a data.table with the counts
    counts <- data.table::data.table(
      file = sapply(count_data, function(x) x$file),
      count = sapply(count_data, function(x) x$count)
    )
    return(counts)
  }
  
  # For multiple files or when include_filename is TRUE, create a combined data frame with a source column
  if (include_filename && any(grepl(":", result, fixed = TRUE))) {
    # Results will be in format "filename:content" or "filename:line_number:content"
    # Split the results and create a data table with source information
    split_results <- lapply(result, function(line) {
      # Find the first colon that separates filename from content
      colon_pos <- regexpr(":", line, fixed = TRUE)
      if (colon_pos > 0) {
        filename <- substr(line, 1, colon_pos - 1)
        remaining <- substr(line, colon_pos + 1, nchar(line))
        
        # Handle line numbers if present
        if (show_line_numbers) {
          second_colon <- regexpr(":", remaining, fixed = TRUE)
          if (second_colon > 0) {
            line_number <- substr(remaining, 1, second_colon - 1)
            content <- substr(remaining, second_colon + 1, nchar(remaining))
            return(list(filename = filename, line_number = as.integer(line_number), content = content))
          }
        }
        return(list(filename = filename, content = remaining))
      } else {
        return(list(filename = "unknown", content = line))
      }
    })
    
    # Extract components
    filenames <- sapply(split_results, function(x) x$filename)
    contents <- sapply(split_results, function(x) x$content)
    
    # Create a temporary file to store the content
    temp_file <- tempfile(fileext = ".csv")
    writeLines(contents, temp_file)
    
    # Read the data with fread
    dt <- data.table::fread(temp_file, header = header, 
                           nrows = nrows, skip = skip, col.names = col.names, ...)
    
    # Add the source column
    dt[, source_file := filenames]
    
    # Add line numbers if requested
    if (show_line_numbers) {
      line_numbers <- sapply(split_results, function(x) x$line_number)
      dt[, line_number := line_numbers]
    }
    
    # Clean up temporary file
    unlink(temp_file)
    
    return(dt)
  } else {
    # Single file or recursive case - direct read
    dt <- data.table::fread(text = paste(result, collapse = "\n"), 
                           header = header, nrows = nrows, 
                           skip = skip, col.names = col.names, ...)
    return(dt)
  }
}
