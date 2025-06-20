#' Read and filter data from one or more files using grep
#' 
#' This function reads data from one or more files after filtering it with grep.
#' It allows for flexible pattern matching and leverages data.table's fread for efficient data import.
#' 
#' @param files Character vector of file paths. If NULL, use the path parameter.
#' @param path Optional. Character string specifying a directory to search for files. If files is NULL, all files in this path will be used.
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
#' all_data <- grep_read(files = "data/sample_data.csv")
#' 
#' # Read all .csv files in a directory
#' all_data <- grep_read(path = "data", pattern = "", recursive = TRUE)
#' }
#' 
#' @importFrom data.table fread setnames
#' @export
grep_read <- function(files = NULL, path = NULL, pattern = '', invert = FALSE, ignore_case = FALSE, 
                      fixed = FALSE, show_cmd = FALSE, recursive = FALSE,
                      word_match = FALSE, show_line_numbers = FALSE,
                      count_only = FALSE, nrows = Inf, skip = 0, 
                      header = TRUE, col.names = NULL, include_filename = NULL,
                      show_progress = TRUE, ...) {
  # Ensure data.table is available
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("The 'data.table' package is required but not installed. Please install it via install.packages('data.table').")
  }

  # If files is NULL and path is provided, use list.files to get files
  if (is.null(files) && !is.null(path)) {
    files <- list.files(path = path, pattern = NULL, full.names = TRUE, recursive = recursive)
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
  options <- character()
  if (invert) options <- c(options, "-v")
  if (ignore_case) options <- c(options, "-i")
  if (fixed) options <- c(options, "-F")
  if (recursive) options <- c(options, "-r")
  if (word_match) options <- c(options, "-w")
  if (show_line_numbers) options <- c(options, "-n")
  if (count_only) options <- c(options, "-c")
  if (include_filename && !count_only) options <- c(options, "-H")
  options_str <- paste(options, collapse = " ")

  # Build the command (fix extra space issue)
  cmd <- sprintf("grep%s '%s' %s",
                 if (nchar(options_str) > 0) paste0(" ", options_str) else "",
                 gsub("'", "'\\''", pattern),
                 paste(shQuote(files), collapse = " "))

  res <- NULL

  # Return command if requested
  if (show_cmd) {
    res <- cmd
  } else {
    # Get column names from first file if header is TRUE
    if (header && !count_only) {
      tryCatch({
        first_file_cols <- names(data.table::fread(files[1], nrows = 1, header = TRUE))
        if (is.null(col.names)) {
          col.names <- first_file_cols
        }
      }, error = function(e) {
        warning("Could not read headers from first file: ", e$message)
      })
    }
    if (show_progress && !count_only) {
      message("Reading data from ", length(files), " file(s)...")
    }
    res <- tryCatch({
      if (count_only) {
        result <- safe_system_call(cmd)
        if (length(result) == 0) {
          data.table::data.table(file = files, count = 0)
        } else {
          count_data <- lapply(result, function(line) {
            parts <- strsplit(line, ":", fixed = TRUE)[[1]]
            if (length(parts) == 2) {
              return(list(file = parts[1], count = as.integer(parts[2])))
            } else {
              return(list(file = "unknown", count = as.integer(line)))
            }
          })
          data.table::data.table(
            file = sapply(count_data, function(x) x$file),
            count = sapply(count_data, function(x) x$count)
          )
        }
      } else {
        dt <- data.table::fread(cmd = cmd, header = FALSE, nrows = nrows, skip = skip, ...)
        if (nrow(dt) == 0 || ncol(dt) == 0) {
          dt
        } else {
          if (!is.null(col.names)) {
            n <- min(ncol(dt), length(col.names))
            if (n > 0) {
              data.table::setnames(dt, names(dt)[1:n], col.names[1:n])
            }
          }
          if (include_filename && any(grepl(":", dt[[1]], fixed = TRUE))) {
            split_cols <- data.table::tstrsplit(dt[[1]], ":", fixed = TRUE)
            if (length(split_cols) == 2) {
              dt[, source_file := split_cols[[1]]]
              dt[, (1) := split_cols[[2]]]
            }
          }
          if (show_line_numbers && any(grepl(":", dt[[1]], fixed = TRUE))) {
            split_cols <- data.table::tstrsplit(dt[[1]], ":", fixed = TRUE)
            if (length(split_cols) == 2) {
              dt[, line_number := as.integer(split_cols[[1]])]
              dt[, (1) := split_cols[[2]]]
            }
          }
          dt
        }
      }
    }, error = function(e) {
      stop("Error reading data: ", e$message)
    }, warning = function(w) {
      warning("Warning while reading data: ", w$message)
    })
  }
  return(res)
}
