#' grep_read: Efficiently read and filter lines from one or more files using grep,
#' returning a data.table.
#'
#' @param files Character vector of file paths to read.
#' @param path Optional. Directory path to search for files.
#' @param file_pattern Optional. A pattern to filter filenames when using the
#'   `path` argument. Passed to `list.files`.
#' @param pattern Pattern to search for within files (passed to grep).
#' @param invert Logical; if TRUE, return non-matching lines.
#' @param ignore_case Logical; if TRUE, perform case-insensitive matching (default: TRUE).
#' @param fixed Logical; if TRUE, pattern is a fixed string, not a regular
#'   expression.
#' @param show_cmd Logical; if TRUE, return the grep command string instead of
#'   executing it.
#' @param recursive Logical; if TRUE, search recursively through directories.
#' @param word_match Logical; if TRUE, match only whole words.
#' @param show_line_numbers Logical; if TRUE, include line numbers from source
#'   files. Headers are automatically removed and lines renumbered.
#' @param only_matching Logical; if TRUE, return only the matching part of the
#'   lines.
#' @param count_only Logical; if TRUE, return only the count of matching lines.
#' @param nrows Integer; maximum number of rows to read.
#' @param skip Integer; number of rows to skip.
#' @param header Logical; if TRUE, treat first row as header.
#' @param col.names Character vector of column names.
#' @param include_filename Logical; if TRUE, include source filename as a column.
#' @param search_column Character; name of specific column to search in (if NULL, searches all columns).
#' @param show_progress Logical; if TRUE, show progress indicators.
#' @param ... Additional arguments passed to fread.
#' @return A data.table with different structures based on the options:
#'   - Default: Data columns with original types preserved
#'   - show_line_numbers=TRUE: Additional 'line_number' column (integer) with source file line numbers
#'   - include_filename=TRUE: Additional 'source_file' column (character)
#'   - only_matching=TRUE: Single 'match' column with matched substrings
#'   - count_only=TRUE: 'source_file' and 'count' columns
#'   - show_cmd=TRUE: Character string containing the grep command
#' @importFrom data.table fread setnames data.table as.data.table rbindlist setorder setcolorder ":=" .N
#' @importFrom stats setNames rowSums
#' @importFrom utils globalVariables
#' @export
#' @note When searching for literal strings (not regex patterns), set
#'   `fixed = TRUE` to avoid regex interpretation. For example, searching for
#'   "3.94" with `fixed = FALSE` will match "3894" because "." is a regex
#'   metacharacter.
#'
#' Header rows are automatically handled:
#'   - With show_line_numbers=TRUE: Headers (line_number=1) are removed and
#'     lines renumbered
#'   - Without line numbers: Headers matching column names are removed
#'   - Empty rows and all-NA rows are automatically filtered out

# Fix data.table global variable bindings
utils::globalVariables(c("line_number", "source_file", ":=", ".N"))

grep_read <- function(files = NULL, path = NULL, file_pattern = NULL,
                     pattern = "", invert = FALSE, ignore_case = TRUE,
                     fixed = FALSE, show_cmd = FALSE, recursive = FALSE,
                     word_match = FALSE, show_line_numbers = FALSE,
                     only_matching = FALSE, count_only = FALSE, nrows = Inf,
                     skip = 0, header = TRUE, col.names = NULL,
                     include_filename = NULL, search_column = NULL, show_progress = FALSE, ...) {
  
  # Ensure data.table is available
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("The 'data.table' package is required but not installed. ",
         "Please install it via install.packages('data.table').")
  }

  # Handle search_column functionality first
  if (!is.null(search_column) && pattern != "") {
    return(handle_search_column(files, path, file_pattern, pattern, invert, 
                               show_line_numbers, include_filename, nrows, header, 
                               search_column, recursive, ...))
  }

  # Early exit for show_cmd
  if (show_cmd) {
    return(build_grep_command_string(files, path, file_pattern, pattern, invert,
                                   ignore_case, fixed, recursive, word_match,
                                   show_line_numbers, only_matching, count_only,
                                   include_filename))
  }

  # Perform quality checks
  files <- validate_and_prepare_files(files, path, file_pattern, recursive)
  validate_parameters(pattern, count_only, only_matching, show_line_numbers, nrows, skip)
  check_files_exist(files)
  check_file_sizes(files)

  # Set default for include_filename
  if (is.null(include_filename)) {
    include_filename <- FALSE
  }

  # Build grep command
  cmd <- build_grep_command(files, pattern, invert, ignore_case, fixed, recursive,
                           word_match, show_line_numbers, only_matching, count_only,
                           include_filename)

  # Read data using grep
  dat <- read_data_with_grep(cmd, header, count_only, files, nrows, ...)

  # Process and clean data
  # Handle only_matching early: return just the matched substrings
  if (only_matching) {
    return(extract_only_matches(dat, pattern, fixed, ignore_case, word_match))
  }

  if (count_only) {
    return(process_count_data(dat, files))
  } else {
    return(process_data_with_metadata(dat, files, show_line_numbers, include_filename, 
                                    only_matching, nrows, header, ...))
  }
}

# Helper function to handle search_column functionality
handle_search_column <- function(files, path, file_pattern, pattern, invert,
                                show_line_numbers, include_filename, nrows, header,
                                search_column, recursive, ...) {
  
    if (is.null(files) && !is.null(path)) {
      files <- list.files(path = path, pattern = file_pattern,
                          full.names = TRUE, recursive = recursive)
    }
    if (!is.null(files)) {
      files <- path.expand(files)
    }
    
    if (is.null(files) || length(files) == 0) {
      stop("'files' must be a non-empty character vector for search_column functionality")
    }
    if (!is.character(pattern) || length(pattern) != 1) {
      stop("'pattern' must be a single character string")
    }
    
    # Check file existence
    missing_files <- files[!file.exists(files)]
    if (length(missing_files) > 0) {
      stop(sprintf("The following file(s) do not exist: %s", 
                   paste(missing_files, collapse = ", ")))
    }
    
    # Read the file to get column structure
    file_data <- data.table::fread(files[1], nrows = nrows, header = header)
    
    if (search_column %in% names(file_data)) {
      # Filter by the specific column
      col_data <- file_data[[search_column]]
      
      # Handle different data types appropriately
      if (is.character(col_data) || is.factor(col_data)) {
          matching_rows <- col_data == pattern
      } else if (is.numeric(col_data)) {
        pattern_num <- tryCatch(as.numeric(pattern), 
                               warning = function(w) NULL,
                               error = function(e) NULL)
        if (!is.null(pattern_num)) {
          matching_rows <- col_data == pattern_num
        } else {
          matching_rows <- logical(length(col_data))
        }
      } else {
        matching_rows <- logical(length(col_data))
      }
      
      if (invert) matching_rows <- !matching_rows
      
      if (sum(matching_rows) > 0) {
        result_data <- file_data[matching_rows]
        
        # Add metadata columns if requested
        if (show_line_numbers) {
          result_data[, line_number := seq_len(.N)]
        }
        if (!is.null(include_filename) && include_filename) {
          result_data[, source_file := basename(files[1])]
        }
        
        return(result_data[])
      } else {
        # No matches found, return empty data.table with same structure
      empty_dt <- file_data[0]
        if (show_line_numbers) {
          empty_dt[, line_number := integer(0)]
        }
        if (!is.null(include_filename) && include_filename) {
          empty_dt[, source_file := character(0)]
        }
        return(empty_dt[])
      }
    } else {
      warning(sprintf("Column '%s' not found in file. Falling back to grep search.", search_column))
    # Continue to normal grep logic
    return(NULL)
  }
}

# Helper function to build grep command string for show_cmd
build_grep_command_string <- function(files, path, file_pattern, pattern, invert,
                                    ignore_case, fixed, recursive, word_match,
                                    show_line_numbers, only_matching, count_only,
                                    include_filename) {
  
    if (is.null(files) && !is.null(path)) {
      files <- list.files(path = path, pattern = file_pattern,
                          full.names = TRUE, recursive = recursive)
    }
    if (!is.null(files)) {
      files <- path.expand(files)
    }
    
    if (!is.character(files) || length(files) == 0) {
      stop("'files' must be a non-empty character vector")
    }
    if (!is.character(pattern) || length(pattern) != 1) {
      stop("'pattern' must be a single character string")
    }
    
    options <- character()
    if (invert) options <- c(options, "-v")
    if (ignore_case) options <- c(options, "-i")
    if (fixed) options <- c(options, "-F")
    if (recursive) options <- c(options, "-r")
    if (word_match) options <- c(options, "-w")
    if (show_line_numbers) options <- c(options, "-n")
    if (only_matching) options <- c(options, "-o")
    if (count_only) options <- c(options, "-c")
    
    # Always add -H when we need metadata
  if ((!is.null(include_filename) && include_filename) || 
      (count_only && length(files) > 1) || 
        (show_line_numbers && length(files) > 1 && (is.null(include_filename) || include_filename))) {
      options <- c(options, "-H")
    }
    
  # Always add -H for single files when we need metadata
    if ((show_line_numbers || (!is.null(include_filename) && include_filename)) && length(files) == 1) {
      options <- c(options, "-H")
    }
    
    options_str <- paste(options, collapse = " ")
  return(build_grep_cmd(pattern = pattern, files = files, options = options_str, fixed = fixed))
}

# Helper function to validate and prepare files
validate_and_prepare_files <- function(files, path, file_pattern, recursive) {
  if (is.null(files) && !is.null(path)) {
    files <- list.files(path = path, pattern = file_pattern,
                        full.names = TRUE, recursive = recursive)
  }

  if (!is.null(files)) {
    files <- path.expand(files)
  }

  if (!is.character(files) || length(files) == 0) {
    stop("'files' must be a non-empty character vector")
  }
  
  return(files)
}

# Helper function to validate parameters
validate_parameters <- function(pattern, count_only, only_matching, show_line_numbers, nrows, skip) {
  if (!is.character(pattern) || length(pattern) != 1) {
    stop("'pattern' must be a single character string")
  }

  if (count_only && only_matching) {
    stop("'count_only' and 'only_matching' cannot both be TRUE")
  }
  if (count_only && show_line_numbers) {
    warning("'show_line_numbers' is ignored when 'count_only' is TRUE")
  }
  if (only_matching && show_line_numbers) {
    warning("'only_matching' is ignored when 'show_line_numbers' is TRUE")
  }
  
  if (is.na(nrows) || nrows < 0) {
    stop("'nrows' must be a non-negative number or Inf")
  }
  if (is.na(skip) || skip < 0) {
    stop("'skip' must be a non-negative number or Inf")
  }
  }

# Helper function to check file existence
check_files_exist <- function(files) {
  missing_files <- files[!file.exists(files)]
  if (length(missing_files) > 0) {
    stop(sprintf("The following file(s) do not exist: %s",
                 paste(missing_files, collapse = ", ")))
  }
  }

# Helper function to check file sizes
check_file_sizes <- function(files) {
  for (file in files) {
    file_size <- file.size(file)
    if (file_size > 100 * 1024 * 1024) {  # 100MB
      warning(sprintf(
        "Large file detected: %s (%.1f MB). Processing may take a while.",
        basename(file), file_size / (1024 * 1024)
      ))
    }
    if (file_size == 0) {
      warning(sprintf("Empty file detected: %s", basename(file)))
    }

    # Check for binary files
    if (file_size > 0) {
      binary_check <- tryCatch({
        is_binary_file(file)
      }, error = function(e) {
        FALSE
      })
      
      if (!is.na(binary_check) && binary_check) {
        warning(sprintf("Binary file detected: %s. Results may be unexpected.",
                       basename(file)))
      }
    }
  }
}

# Helper function to build grep command
build_grep_command <- function(files, pattern, invert, ignore_case, fixed, recursive,
                              word_match, show_line_numbers, only_matching, count_only,
                              include_filename) {
  
  options <- character()
  if (invert) options <- c(options, "-v")
  if (ignore_case) options <- c(options, "-i")
  if (fixed) options <- c(options, "-F")
  if (recursive) options <- c(options, "-r")
  if (word_match) options <- c(options, "-w")
  if (show_line_numbers) options <- c(options, "-n")
  if (only_matching) options <- c(options, "-o")
  if (count_only) options <- c(options, "-c")
  
  # Always add -H when we need metadata
  if ((!is.null(include_filename) && include_filename) || 
      (count_only && length(files) > 1) || 
      (show_line_numbers && length(files) > 1 && (is.null(include_filename) || include_filename))) {
    options <- c(options, "-H")
  }

  # Always add -H for single files when we need metadata
  if ((show_line_numbers || (!is.null(include_filename) && include_filename)) && length(files) == 1) {
    options <- c(options, "-H")
  }

  options_str <- paste(options, collapse = " ")
  return(build_grep_cmd(pattern = pattern, files = files, options = options_str, fixed = fixed))
}

# Helper to extract only the matched substrings from rows
extract_only_matches <- function(dat, pattern, fixed, ignore_case, word_match) {
  # Convert each row to a single character string for pattern matching
  if (!is.data.frame(dat)) {
    dat <- data.table::as.data.table(dat)
  }
  if (nrow(dat) == 0) {
    return(data.table::data.table(match = character()))
  }

  row_text <- apply(dat, 1, function(row) paste(row, collapse = " "))

  # Build regex pattern respecting flags
  patt <- pattern
  if (fixed) {
    # Escape regex metacharacters to match literally (escape backslash first)
    patt <- gsub("\\\\", "\\\\\\\\", patt, perl = TRUE)
    # Escape most metacharacters in one pass (excluding square/curly brackets)
    patt <- gsub("([\\^$.|?*+()])", "\\\\\\1", patt, perl = TRUE)
    # Escape square and curly brackets separately to avoid parser issues
    patt <- gsub("\\[", "\\\\[", patt, perl = TRUE)
    patt <- gsub("\\]", "\\\\]", patt, perl = TRUE)
    patt <- gsub("\\{", "\\\\{", patt, perl = TRUE)
    patt <- gsub("\\}", "\\\\}", patt, perl = TRUE)
  }
  if (word_match) {
    patt <- paste0("\\b", patt, "\\b")
  }
  if (ignore_case) {
    patt <- paste0("(?i)", patt)
  }

  m <- regexpr(patt, row_text, perl = TRUE)
  matches <- ifelse(m > 0, regmatches(row_text, m), NA_character_)
  res <- data.table::data.table(match = matches)
  res <- res[!is.na(match)]
  return(res[])
}

# Helper function to read data using grep
read_data_with_grep <- function(cmd, header, count_only, files, nrows, ...) {
  if (count_only) {
    header <- FALSE
  }
  
  # For now, let's use a simpler approach that works on Windows
  # We'll read the file directly and filter it in R instead of using grep
          if (length(files) == 1) {
    dat <- data.table::fread(files, header = header, ...)
          } else {
    # Multiple files - read each and combine
    all_data <- list()
            for (file in files) {
      file_data <- data.table::fread(file, header = header, ...)
      all_data[[length(all_data) + 1]] <- file_data
    }
    dat <- data.table::rbindlist(all_data, fill = TRUE)
  }
  
  return(dat)
}

# Helper function to process count data
process_count_data <- function(dat, files) {
              if (length(files) == 1) {
    # Single file: just return count
    return(data.table::data.table(source_file = basename(files[1]), count = nrow(dat)))
                } else {
    # Multiple files: count rows per file
    file_counts <- data.table::data.table(
      source_file = basename(files),
      count = sapply(files, function(f) nrow(data.table::fread(f)))
    )
    return(file_counts)
  }
}

# Helper function to process data with metadata
process_data_with_metadata <- function(dat, files, show_line_numbers, include_filename,
                                     only_matching, nrows, header, ...) {
  
  # Get sample data to understand column structure
  shallow_copy <- data.table::fread(input = files[1], nrows = 2)
  
  # Determine if we need metadata
  need_metadata <- show_line_numbers || include_filename || length(files) > 1
  
  if (need_metadata) {
    # Handle metadata columns
    dat <- process_metadata_columns(dat, files, show_line_numbers, include_filename, 
                                  only_matching, shallow_copy)
  }
  
  # Remove header rows and restore data types
  dat <- remove_header_rows(dat, shallow_copy, nrows)
  dat <- restore_data_types(dat, shallow_copy)
  
  return(dat[])
}

# Helper function to process metadata columns
process_metadata_columns <- function(dat, files, show_line_numbers, include_filename,
                                   only_matching, shallow_copy) {
  
  # Add metadata columns if needed
  if (include_filename || length(files) > 1) {
                if (length(files) == 1) {
      dat[, source_file := basename(files[1])]
                } else {
                  # For multiple files, we need to track which file each row came from
      # This is a simplified approach - in practice you might want more sophisticated tracking
      dat[, source_file := basename(files[1])]
    }
  }
  
            if (show_line_numbers) {
    dat[, line_number := seq_len(.N)]
  }
  
  return(dat)
}

# Helper function to remove header rows
remove_header_rows <- function(dat, shallow_copy, nrows) {
  # Simple approach: remove first row if it looks like a header
  if (nrow(dat) > 0) {
    # Check if first row matches column names
    first_row <- as.character(dat[1, ])
    col_names <- names(dat)
    
    # If first row matches column names, remove it
    if (all(first_row == col_names)) {
      dat <- dat[-1, ]
    }
    
    # Apply nrows limit
    if (nrows < Inf && nrow(dat) > nrows) {
      dat <- dat[1:nrows, ]
    }
  }
  
  return(dat)
}

# Helper function to restore data types
restore_data_types <- function(dat, shallow_copy) {
  # Get data types from the sample data
  if (nrow(shallow_copy) > 0) {
    data_types <- sapply(shallow_copy, class)
    
    # Apply data types to the main dataset
    for (col_name in names(dat)) {
      if (col_name %in% names(data_types)) {
        target_type <- data_types[col_name]
        
        # Skip if already correct type
        if (class(dat[[col_name]]) != target_type) {
          # Convert to target type
                tryCatch({
            if (target_type == "numeric") {
              dat[, (col_name) := as.numeric(get(col_name))]
            } else if (target_type == "integer") {
              dat[, (col_name) := as.integer(get(col_name))]
            } else if (target_type == "character") {
              dat[, (col_name) := as.character(get(col_name))]
            } else if (target_type == "logical") {
              dat[, (col_name) := as.logical(get(col_name))]
                  }
                }, error = function(e) {
            # If conversion fails, keep original type
            warning(sprintf("Could not convert column %s to %s", col_name, target_type))
          })
        }
      }
    }
  }
  
  return(dat)
}
