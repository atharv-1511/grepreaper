#' grep_read: Efficiently read and filter lines from one or more files using grep, returning a data.table.
#' 
#' @param files Character vector of file paths to read.
#' @param path Optional. Directory path to search for files.
#' @param file_pattern Optional. A pattern to filter filenames when using the `path` argument. Passed to `list.files`.
#' @param pattern Pattern to search for within files (passed to grep).
#' @param invert Logical; if TRUE, return non-matching lines.
#' @param ignore_case Logical; if TRUE, perform case-insensitive matching.
#' @param fixed Logical; if TRUE, pattern is a fixed string, not a regular expression.
#' @param show_cmd Logical; if TRUE, return the grep command string instead of executing it.
#' @param recursive Logical; if TRUE, search recursively through directories.
#' @param word_match Logical; if TRUE, match only whole words.
#' @param show_line_numbers Logical; if TRUE, include line numbers from source files. Headers are automatically removed and lines renumbered.
#' @param only_matching Logical; if TRUE, return only the matching part of the lines.
#' @param count_only Logical; if TRUE, return only the count of matching lines.
#' @param nrows Integer; maximum number of rows to read.
#' @param skip Integer; number of rows to skip.
#' @param header Logical; if TRUE, treat first row as header.
#' @param col.names Character vector of column names.
#' @param include_filename Logical; if TRUE, include source filename as a column.
#' @param show_progress Logical; if TRUE, show progress indicators.
#' @param ... Additional arguments passed to fread.
#' @return A data.table with different structures based on the options:
#'   - Default: Data columns with original types preserved
#'   - show_line_numbers=TRUE: Additional 'line_number' column (integer)
#'   - include_filename=TRUE: Additional 'source_file' column (character)
#'   - only_matching=TRUE: Single 'match' column with matched substrings
#'   - count_only=TRUE: 'source_file' and 'count' columns
#'   - show_cmd=TRUE: Character string containing the grep command
#' @importFrom data.table fread setnames
#' @export
#' @note When searching for literal strings (not regex patterns), set `fixed = TRUE` to avoid regex interpretation. 
#' For example, searching for "3.94" with `fixed = FALSE` will match "3894" because "." is a regex metacharacter.
#' 
#' Header rows are automatically handled:
#'   - With show_line_numbers=TRUE: Headers (line_number=1) are removed and lines renumbered
#'   - Without line numbers: Headers matching column names are removed
#'   - Empty rows and all-NA rows are automatically filtered out
grep_read <- function(files = NULL, path = NULL, file_pattern = NULL, pattern = '', invert = FALSE, ignore_case = FALSE, 
                      fixed = FALSE, show_cmd = FALSE, recursive = FALSE,
                      word_match = FALSE, show_line_numbers = FALSE, only_matching = FALSE,
                      count_only = FALSE, nrows = Inf, skip = 0, 
                      header = TRUE, col.names = NULL, include_filename = NULL,
                      show_progress = FALSE, ...) {
  # Ensure data.table is available
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("The 'data.table' package is required but not installed. Please install it via install.packages('data.table').")
  }

  # --- File selection and validation ---
  # If files is NULL and path is provided, use list.files to get files
  if (is.null(files) && !is.null(path)) {
    files <- list.files(path = path, pattern = file_pattern, full.names = TRUE, recursive = recursive)
  }

  # Expand ~ in file paths
  if (!is.null(files)) {
    files <- path.expand(files)
  }
  
  # Input validation
  if (!is.character(files) || length(files) == 0) {
    stop("'files' must be a non-empty character vector")
  }
  if (!is.character(pattern) || length(pattern) != 1) {
    stop("'pattern' must be a single character string")
  }
  # Check that all files exist
  missing_files <- files[!file.exists(files)]
  if (length(missing_files) > 0) {
    stop(sprintf("The following file(s) do not exist: %s", paste(missing_files, collapse = ", ")))
  }
  
  # Set default for include_filename based on number of files
  if (is.null(include_filename)) {
    include_filename <- length(files) > 1 && !recursive
  }
  
  # --- Build grep command options ---
  options <- character()
  if (invert) options <- c(options, "-v")
  if (ignore_case) options <- c(options, "-i")
  if (fixed) options <- c(options, "-F")
  if (recursive) options <- c(options, "-r")
  if (word_match) options <- c(options, "-w")
  if (show_line_numbers) options <- c(options, "-n")
  if (only_matching) options <- c(options, "-o")
  if (count_only) options <- c(options, "-c")
  # `-H` prints the filename. It's needed for include_filename, but also for count_only
  # when multiple files are provided, to distinguish counts.
  if (include_filename || (count_only && length(files) > 1)) {
    options <- c(options, "-H")
  }
  
  options_str <- paste(options, collapse = " ")
  
  # Build the command
  cmd <- build_grep_cmd(pattern = pattern, files = files, options = options_str)

  # --- Main logic: run grep and process output ---
  res <- NULL
  
  tryCatch({
  if (show_cmd) {
      # Return the grep command string
      res <- cmd
    } else if (only_matching) {
      # Only return matching substrings (not full lines)
      result <- safe_system_call(cmd)
      if (length(result) == 0) {
        res <- data.table::data.table(match = character(0))
      } else {
        if (include_filename) {
          # For only_matching with filename, split on first colon
          splits <- regexpr(":", result, fixed = TRUE)
          source_file <- ifelse(splits > 0, substr(result, 1, splits - 1), NA)
          match_val <- ifelse(splits > 0, substr(result, splits + 1, nchar(result)), result)
          res <- data.table::data.table(source_file = source_file, match = match_val)
        } else {
          res <- data.table::data.table(match = result)
        }
      }
    } else if (count_only) {
      # Only return counts of matches per file
  result <- safe_system_call(cmd)
  if (length(result) == 0) {
        res <- data.table::data.table(file = character(0), count = integer(0))
      } else {
        if (include_filename) {
          # Parse filename:count format
          splits <- strsplit(result, ":", fixed = TRUE)
          source_file <- sapply(splits, function(x) x[1])
          count_val <- sapply(splits, function(x) as.integer(x[2]))
          res <- data.table::data.table(source_file = source_file, count = count_val)
        } else {
          res <- data.table::data.table(count = as.integer(result))
        }
      }
    } else {
      # Read the data via fread (no skip needed since we're using cmd)
      # Filter out skip parameter from ... arguments when using cmd
      args <- list(...)
      args$skip <- NULL  # Remove skip parameter when using cmd
      
      # Check if the command returns any results first
      result <- safe_system_call(cmd)
      if (length(result) == 0) {
        # No matches found, return empty data.table
        if (!is.null(col.names)) {
          res <- data.table::as.data.table(setNames(lapply(col.names, function(x) character(0)), col.names))
        } else {
          res <- data.table::data.table()
        }
        return(res)
      }
      
      # Use fread with the command, ensuring no skip parameters
      dt <- do.call(data.table::fread, c(list(cmd = cmd, header = FALSE, nrows = nrows), args))
      
      # --- Auto-determine column names if not provided ---
      if (is.null(col.names) && header) {
        # Try to read the header from the first file
        tryCatch({
          first_file_header <- safe_system_call(sprintf("head -n 1 %s", shQuote(files[1])))
          if (length(first_file_header) > 0) {
            # Use fread with explicit parameters to avoid skip issues
            header_dt <- data.table::fread(text = first_file_header, header = TRUE, skip = 0)
            first_file_cols <- colnames(header_dt)
            if (length(first_file_cols) > 0) {
              col.names <- first_file_cols
            }
          }
        }, error = function(e) {
          # If header reading fails, continue without column names
        })
      }
      
      # --- FIXED COLUMN SPLITTING LOGIC ---
      has_filename <- include_filename
      has_line_num <- show_line_numbers
      
      if (nrow(dt) > 0 && (has_filename || has_line_num)) {
        # Get the first column which contains filename:line:data or line:data
        first_col <- dt[[1]]
        
        # Check if the first column contains colons (indicating metadata)
        if (grepl(":", first_col[1], fixed = TRUE)) {
          # Split the first column on colons, but only for metadata
          colon_count <- stringi::stri_count_fixed(first_col[1], ":")
          expected_colons <- as.integer(has_filename) + as.integer(has_line_num)
          
          if (colon_count >= expected_colons) {
            # Create a new data.table
            new_dt <- data.table::data.table()
            
            # Handle metadata first
            if (has_filename || has_line_num) {
              # Split the first column into metadata and data parts
              split_result <- lapply(first_col, function(x) {
                parts <- strsplit(x, ":", fixed = TRUE)[[1]]
                if (length(parts) > expected_colons) {
                  # Keep metadata parts and combine remaining as data
                  metadata <- parts[1:expected_colons]
                  data <- paste(parts[(expected_colons + 1):length(parts)], collapse = ":")
                  c(metadata, data)
                } else {
                  parts
                }
              })
              
              # Convert to data.table
              metadata_parts <- data.table::as.data.table(do.call(rbind, split_result))
              
              current_part <- 1
              
              # Add filename if requested
              if (has_filename) {
                new_dt[, source_file := metadata_parts[[1]]]
                current_part <- 2
              } else {
                current_part <- 1
              }
              
              # Add line number if requested
              if (has_line_num) {
                new_dt[, line_number := suppressWarnings(as.integer(metadata_parts[[current_part]]))]
                current_part <- current_part + 1
              }
              
              # Remaining parts form the data
              if (ncol(metadata_parts) >= current_part) {
                new_dt[, V1 := metadata_parts[[current_part]]]
              }
            } else {
              # No metadata, just copy the data
              new_dt[, V1 := first_col]
            }
            
            # Copy remaining columns
            data_cols <- names(dt)[-1]
            for (i in seq_along(data_cols)) {
              new_dt[, (paste0("V", i+1)) := dt[[data_cols[i]]]]
            }
            
            # Replace original data.table
            dt <- new_dt
          }
        }
      }
      
      # --- Set column names for data columns only ---
      if (!is.null(col.names)) {
        # For cases without metadata columns, use all columns
        if (!any(c("source_file", "line_number") %in% names(dt))) {
          data_cols_indices <- 1:ncol(dt)
        } else {
          data_cols_indices <- which(!names(dt) %in% c("source_file", "line_number"))
        }
        
        names_to_set <- col.names[1:min(length(col.names), length(data_cols_indices))]
        
        data.table::setnames(dt, data_cols_indices[1:length(names_to_set)], names_to_set)
        
        # --- Header row removal using mentor's data.table approach ---
        if (nrow(dt) > 0) {
          # Remove header rows and handle data types
          if (nrow(dt) > 0) {
            # Get data columns (excluding metadata columns)
            data_cols <- setdiff(names(dt), c("source_file", "line_number"))
            
            # Remove header rows and handle data types
            if (nrow(dt) > 0) {
              # First pass: Remove header rows
              header_rows <- dt[, {
                row_vals <- as.character(.SD)
                # Check if row matches column names exactly
                any(sapply(row_vals, function(x) x %in% names_to_set))
              }, by = 1:nrow(dt), .SDcols = data_cols]
              
              # Remove header rows
              if (any(header_rows$V1)) {
                dt <- dt[!header_rows$V1]
              }
              
              # Second pass: Convert data types
              for (col in data_cols) {
                vals <- dt[[col]]
                if (is.character(vals)) {
                  # Try numeric conversion
                  num_vals <- suppressWarnings(as.numeric(vals))
                  if (!all(is.na(num_vals))) {
                    dt[, (col) := num_vals]
                  }
                }
              }
              
              # Remove any remaining all-NA rows
              dt <- dt[!dt[, all(is.na(.SD)), .SDcols = data_cols]]
            }
            
            # Handle source files and line numbers
            if ("source_file" %in% names(dt)) {
              # Clean up source file paths
              dt[, source_file := basename(as.character(source_file))]
              
              # Remove any drive letter prefix (Windows paths)
              dt[, source_file := sub("^[A-Za-z]:", "", source_file)]
              
              # Remove any leading path separators
              dt[, source_file := sub("^[\\\\/]+", "", source_file)]
              
              # Group by source file for line numbers
              if (show_line_numbers) {
                # First sort by source file and original line number
                if ("line_number" %in% names(dt)) {
                  setorder(dt, source_file, line_number)
                }
                # Then renumber within each file
                dt[, line_number := seq_len(.N), by = source_file]
              }
            } else if (show_line_numbers) {
              # Simple sequential numbering for single file
              if ("line_number" %in% names(dt)) {
                setorder(dt, line_number)
              }
              dt[, line_number := seq_len(.N)]
            }
            
            # Ensure integer type for line numbers
            if ("line_number" %in% names(dt)) {
              dt[, line_number := as.integer(line_number)]
            }
          }
          
          # Remove all-NA rows using data.table approach
          if (nrow(dt) > 0) {
            na_row_idx <- dt[, which(rowMeans(is.na(.SD)) < 1)]
            if (length(na_row_idx) > 0) {
              dt <- dt[na_row_idx]
            }
          }
          
          # Convert empty strings to NA for better handling
          for (col in names_to_set) {
            if (col %in% names(dt)) {
              dt[dt[[col]] == "", (col) := NA_character_]
            }
          }
        }
        
        # --- Type restoration: only after header/NA row removal ---
        if (nrow(dt) > 0) {
          # Create a shallow copy of the first file to determine column types
          shallow <- NULL
          tryCatch({
            # Remove skip parameter from shallow read to avoid issues
            shallow_args <- list(...)
            shallow_args$skip <- NULL
            shallow <- do.call(data.table::fread, c(list(files[1], nrows = 5, header = header, col.names = col.names), shallow_args))
          }, error = function(e) {
            # If shallow read fails, skip type restoration
          })
          
          if (!is.null(shallow) && nrow(shallow) > 0) {
            col_types <- sapply(shallow, class)
            for (col in names_to_set) {
              if (col %in% names(dt) && col %in% names(col_types)) {
                col_class <- col_types[[col]][1]
                # Only restore type if not all NA and not header name
                if (col_class == "numeric" || col_class == "integer") {
                  dt[[col]] <- suppressWarnings(as.numeric(dt[[col]]))
                } else if (col_class == "logical") {
                  dt[[col]] <- suppressWarnings(as.logical(dt[[col]]))
                } else if (col_class == "Date") {
                  dt[[col]] <- suppressWarnings(as.Date(dt[[col]]))
                } else if (col_class == "POSIXct") {
                  dt[[col]] <- suppressWarnings(as.POSIXct(dt[[col]]))
  } else {
                  # For all other types (including factor), convert to character to preserve data
                  dt[[col]] <- as.character(dt[[col]])
                }
              }
            }
          }
        }
      }
      
      res <- dt
    }
  }, error = function(e) {
    stop(sprintf("Error in grep_read: %s", e$message))
  })
  
  return(res)
}

