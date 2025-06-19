#' Read and filter data from one or more files using grep
#' 
#' This function reads data from one or more files after filtering it with grep.
#' It allows for flexible pattern matching and leverages data.table's fread for efficient data import.
#' 
#' @param files Character vector of file paths.
#' @param pattern Pattern to search for. Default is empty string (''), which reads all lines.
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
#' @param show_progress Logical; if TRUE, show progress indicators for large files.
#' @param ... Additional arguments passed to fread.
#' 
#' @return A data.table containing the matched data (or command string if show_cmd=TRUE).
#'         If count_only=TRUE, returns a data.table with file names and their match counts.
#' 
#' @examples
#' \dontrun{
#' # Read all lines from sample_data.csv
#' all_data <- grep_read("data/sample_data.csv")
#' 
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
#' @importFrom data.table fread setnames
#' @export
grep_read <- function(files, pattern = '', invert = FALSE, ignore_case = FALSE, 
                      fixed = FALSE, show_cmd = FALSE, recursive = FALSE,
                      word_match = FALSE, show_line_numbers = FALSE,
                      count_only = FALSE, nrows = Inf, skip = 0, 
                      header = TRUE, col.names = NULL, include_filename = NULL,
                      show_progress = TRUE, ...) {
  
  # Ensure data.table is available
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("The 'data.table' package is required but not installed. Please install it via install.packages('data.table').")
  }
  
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
  
  # Get column names from first file if header is TRUE
  if (header && !count_only) {
    tryCatch({
      # Read first row of first file to get column names
      first_file_cols <- names(data.table::fread(files[1], nrows = 1, header = TRUE))
      if (is.null(col.names)) {
        col.names <- first_file_cols
      }
    }, error = function(e) {
      warning("Could not read headers from first file: ", e$message)
    })
  }
  
  # Show progress message for large files
  if (show_progress && !count_only) {
    message("Reading data from ", length(files), " file(s)...")
  }
  
  # Execute grep command and read data
  tryCatch({
    if (count_only) {
      # Handle count-only results
      result <- safe_system_call(cmd)
      
      if (length(result) == 0) {
        return(data.table::data.table(file = files, count = 0))
      }
      
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
    } else {
      # Read data directly using fread with cmd parameter
      dt <- data.table::fread(cmd = cmd, header = FALSE, nrows = nrows, skip = skip, ...)
      
      # Handle empty or malformed results gracefully
      if (nrow(dt) == 0 || ncol(dt) == 0) {
        return(dt)
      }
      
      # If we have column names, apply them robustly
      if (!is.null(col.names)) {
        n <- min(ncol(dt), length(col.names))
        if (n > 0) {
          data.table::setnames(dt, names(dt)[1:n], col.names[1:n])
        }
      }
      
      # Handle filename column if needed
      if (include_filename && any(grepl(":", dt[[1]], fixed = TRUE))) {
        # Split filename and content
        split_cols <- data.table::tstrsplit(dt[[1]], ":", fixed = TRUE)
        if (length(split_cols) == 2) {
          dt[, source_file := split_cols[[1]]]
          dt[, (1) := split_cols[[2]]]
        }
      }
      
      # Handle line numbers if requested
      if (show_line_numbers && any(grepl(":", dt[[1]], fixed = TRUE))) {
        # Split line number and content
        split_cols <- data.table::tstrsplit(dt[[1]], ":", fixed = TRUE)
        if (length(split_cols) == 2) {
          dt[, line_number := as.integer(split_cols[[1]])]
          dt[, (1) := split_cols[[2]]]
        }
      }
      
      return(dt)
    }
  }, error = function(e) {
    stop("Error reading data: ", e$message)
  }, warning = function(w) {
    warning("Warning while reading data: ", w$message)
  })
}
