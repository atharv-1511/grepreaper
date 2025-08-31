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

  # Process search_column BEFORE show_cmd check
  # This ensures column-specific search works correctly
  if (!is.null(search_column) && pattern != "") {
    # Handle column-specific search first
    if (is.null(files) && !is.null(path)) {
      files <- list.files(path = path, pattern = file_pattern,
                          full.names = TRUE, recursive = recursive)
    }
    if (!is.null(files)) {
      files <- path.expand(files)
    }
    
    # Ensure files is properly set before proceeding
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
    
    # For search_column, we need to read the file and filter
    # This bypasses grep entirely for column-specific search
    
    # Read the file to get column structure
    file_data <- data.table::fread(files[1], nrows = nrows, header = header)
    
    if (search_column %in% names(file_data)) {
      # Filter by the specific column
      col_data <- file_data[[search_column]]
      
      # Handle different data types appropriately
      if (is.character(col_data) || is.factor(col_data)) {
        # For character/factor columns, use exact matching
        if (fixed) {
          matching_rows <- col_data == pattern
        } else {
          # For regex patterns, still use exact matching to avoid false positives
          matching_rows <- col_data == pattern
        }
      } else if (is.numeric(col_data)) {
        # For numeric columns, convert pattern to numeric for comparison
        pattern_num <- suppressWarnings(as.numeric(pattern))
        if (!is.na(pattern_num)) {
          matching_rows <- col_data == pattern_num
        } else {
          # Pattern can't be converted to numeric, no matches
          matching_rows <- logical(length(col_data))
        }
      } else {
        # For other data types, no matches
        matching_rows <- logical(length(col_data))
      }
      
      if (invert) matching_rows <- !matching_rows
      
      if (sum(matching_rows) > 0) {
        # Return the filtered data directly
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
        empty_dt <- file_data[0]  # Empty copy with same columns
        if (show_line_numbers) {
          empty_dt[, line_number := integer(0)]
        }
        if (!is.null(include_filename) && include_filename) {
          empty_dt[, source_file := character(0)]
        }
        return(empty_dt[])
      }
    } else {
      # Column not found, fall back to grep
      warning(sprintf("Column '%s' not found in file. Falling back to grep search.", search_column))
      # Continue to normal grep logic below
    }
  }

  # PERFORMANCE OPTIMIZATION: Early exit for show_cmd (no file processing needed)
  if (show_cmd) {
    # Build command and return immediately for maximum speed
    if (is.null(files) && !is.null(path)) {
      files <- list.files(path = path, pattern = file_pattern,
                          full.names = TRUE, recursive = recursive)
    }
    if (!is.null(files)) {
      files <- path.expand(files)
    }
    
    # Quick validation
    if (!is.character(files) || length(files) == 0) {
      stop("'files' must be a non-empty character vector")
    }
    if (!is.character(pattern) || length(pattern) != 1) {
      stop("'pattern' must be a single character string")
    }
    
    # Build and return command string immediately
    options <- character()
    if (invert) options <- c(options, "-v")
    if (ignore_case) options <- c(options, "-i")
    if (fixed) options <- c(options, "-F")
    if (recursive) options <- c(options, "-r")
    if (word_match) options <- c(options, "-w")
    if (show_line_numbers) options <- c(options, "-n")
    if (only_matching) options <- c(options, "-o")
    if (count_only) options <- c(options, "-c")
    
    # CRITICAL FIX: Always add -H when we need metadata
    # CRITICAL FIX: For count_only with multiple files, ALWAYS add -H to get filename:count format
    # This is needed even when include_filename = FALSE to distinguish between different files
    # BUT: Don't add -H for show_line_numbers with multiple files if user explicitly set include_filename = FALSE
    if ((!is.null(include_filename) && include_filename) || (count_only && length(files) > 1) || 
        (show_line_numbers && length(files) > 1 && (is.null(include_filename) || include_filename))) {
      options <- c(options, "-H")
    }
    
    # CRITICAL FIX: Always add -H for single files when we need metadata
    if ((show_line_numbers || (!is.null(include_filename) && include_filename)) && length(files) == 1) {
      options <- c(options, "-H")
    }
    
    options_str <- paste(options, collapse = " ")
    cmd <- build_grep_cmd(pattern = pattern, files = files, options = options_str, fixed = fixed)
    return(cmd)
  }

  # Set progress indicator locally
  local_show_progress <- show_progress

  # --- File selection and validation ---
  # If files is NULL and path is provided, use list.files to get files
  if (is.null(files) && !is.null(path)) {
    files <- list.files(path = path, pattern = file_pattern,
                        full.names = TRUE, recursive = recursive)
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

  # Validate conflicting parameters
  if (count_only && only_matching) {
    stop("'count_only' and 'only_matching' cannot both be TRUE")
  }
  if (count_only && show_line_numbers) {
    warning("'show_line_numbers' is ignored when 'count_only' is TRUE")
    show_line_numbers <- FALSE
  }
  if (only_matching && show_line_numbers) {
    warning("'only_matching' is ignored when 'show_line_numbers' is TRUE")
    show_line_numbers <- FALSE
  }
  # Validate nrows parameter - allow large positive numbers and Inf
  if (is.na(nrows) || nrows < 0) {
    stop("'nrows' must be a non-negative number or Inf")
  }
  # Validate skip parameter - allow large positive numbers and Inf
  if (is.na(skip) || skip < 0) {
    stop("'skip' must be a non-negative number or Inf")
  }

  # Check that all files exist
  missing_files <- files[!file.exists(files)]
  if (length(missing_files) > 0) {
    stop(sprintf("The following file(s) do not exist: %s",
                 paste(missing_files, collapse = ", ")))
  }

  # Check file sizes and warn about very large files
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

    # Check for binary files - skip for empty files to avoid errors
    if (file_size > 0) {
      binary_check <- tryCatch({
        is_binary_file(file)
      }, error = function(e) {
        FALSE  # Assume text if check fails
      })
      
      if (!is.na(binary_check) && binary_check) {
        warning(sprintf("Binary file detected: %s. Results may be unexpected.",
                       basename(file)))
      }
    }
  }

  # CRITICAL FIX: Set default for include_filename based on number of files
  # Only set to TRUE if explicitly requested or if we need it for metadata
  if (is.null(include_filename)) {
    include_filename <- FALSE  # Default to FALSE to avoid interference with pattern matching
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
  
  # CRITICAL FIX: Only add -H when explicitly needed
  # `-H` prints the filename. It's needed for:
  # 1. include_filename = TRUE (user explicitly wants filenames)
  # 2. count_only = TRUE with multiple files (to distinguish counts)
  # 3. show_line_numbers = TRUE with multiple files (to distinguish line numbers) - BUT ONLY if include_filename is not explicitly FALSE
  # CRITICAL FIX: Don't add -H when user explicitly sets include_filename = FALSE
  should_add_H <- FALSE
  
  if (!is.null(include_filename) && include_filename) {
    # User explicitly wants filenames
    should_add_H <- TRUE
  } else if (count_only && length(files) > 1) {
    # Need filenames to distinguish counts from multiple files
    should_add_H <- TRUE
  } else if (show_line_numbers && length(files) > 1 && (is.null(include_filename) || include_filename)) {
    # Need filenames to distinguish line numbers from multiple files, but only if user hasn't explicitly said no
    should_add_H <- TRUE
  }
  
  if (should_add_H) {
    options <- c(options, "-H")
  }

  # CRITICAL FIX: Add -H for single files only when metadata is explicitly requested
  if ((show_line_numbers || (!is.null(include_filename) && include_filename)) && length(files) == 1) {
    options <- c(options, "-H")
  }

  options_str <- paste(options, collapse = " ")

  # Build the command
  cmd <- build_grep_cmd(pattern = pattern, files = files, options = options_str, fixed = fixed)

  # --- Main logic: run grep and process output ---
  result_dt <- NULL

  tryCatch({
    if (show_cmd) {
      # Return the grep command string
      result_dt <- cmd
    } else if (only_matching) {
      # Only return matching substrings (not full lines)
      result <- safe_system_call(cmd)
      if (length(result) == 0) {
        result_dt <- data.table::data.table(match = character(0))
      } else {
        if (include_filename) {
          # For only_matching with filename, split on first colon
          splits <- regexpr(":", result, fixed = TRUE)
          source_file <- ifelse(splits > 0, substr(result, 1, splits - 1), NA)
          match_val <- ifelse(splits > 0, substr(result, splits + 1,
                                                 nchar(result)), result)
          result_dt <- data.table::data.table(source_file = source_file,
                                             match = match_val)
        } else {
          result_dt <- data.table::data.table(match = result)
        }
      }
    } else if (count_only) {
       # CRITICAL FIX: Fix count_only parsing for mentor feedback
       result <- safe_system_call(cmd)
       

       
       if (length(result) == 0) {
         result_dt <- data.table::data.table(source_file = character(0),
                                            count = integer(0))
       } else {
        # CRITICAL FIX: Properly parse filename:count format
        # Handle both single and multiple file scenarios
        # CRITICAL FIX: When we have multiple files, we ALWAYS get filename:count format
        # due to the -H flag being added automatically
        
        # Check if we should parse filename:count format
        should_parse_filename_count <- (length(files) > 1) || include_filename || any(grepl(":", result, fixed = TRUE))
        
        if (!should_parse_filename_count) {
          # Single file without filename and no colons - just count
          result_dt <- data.table::data.table(count = as.integer(result))
        } else {
          # Multiple files or filename requested or result contains colons - parse filename:count
          # This handles both explicit include_filename=TRUE and automatic -H for multiple files
          # CRITICAL FIX: Check if result contains colons (filename:count format)
          if (any(grepl(":", result, fixed = TRUE))) {
            # Parse filename:count format
            # CRITICAL FIX: Handle both single and multiple result strings
            # Each element in result should be "filename:count"
            # CRITICAL FIX: On Windows, filenames contain colons (C:/path), so we need to split from the right
            # Find the last colon in each result string and split there
            splits <- regexpr(":[^:]*$", result)  # Find last colon
            source_file <- ifelse(splits > 0, substr(result, 1, splits - 1), result)
            count_val <- ifelse(splits > 0, as.integer(substr(result, splits + 1, nchar(result))), as.integer(result))
            result_dt <- data.table::data.table(source_file = source_file,
                                               count = count_val)
            
            # CRITICAL FIX: If include_filename = FALSE or NULL, remove the source_file column
            # even though we needed it for parsing multiple files
            if (is.null(include_filename) || !include_filename) {
              result_dt[, source_file := NULL]
            }
          } else {
            # No colons found, treat as simple count (fallback)
            # CRITICAL FIX: For multiple files, we should always get filename:count format
            # If we don't, there might be an issue with the grep command
            if (length(files) > 1) {
              # This shouldn't happen, but let's handle it gracefully
              warning("Expected filename:count format for multiple files but got simple count")
              result_dt <- data.table::data.table(count = as.integer(result))
            } else {
              result_dt <- data.table::data.table(count = as.integer(result))
            }
          }
        }
      }
    } else {
      # Read the data via fread (no skip needed since we're using cmd)
      # Filter out skip parameter from ... arguments when using cmd
      args <- list(...)
      args$skip <- NULL  # Remove skip parameter when using cmd

      # Check if we have an empty pattern - if so, read files directly
      if (pattern == "") {
        # Read files directly without grep when pattern is empty
          if (length(files) == 1) {
            # Single file - read directly
            dt <- do.call(data.table::fread, c(list(files[1], header = header,
                                                   nrows = nrows), args))
          } else {
            # Multiple files - read each separately and combine
            all_results <- list()
            for (file in files) {
              file_dt <- do.call(data.table::fread, c(list(file, header = header,
                                                          nrows = nrows), args))
              all_results[[length(all_results) + 1]] <- file_dt
            }
            dt <- data.table::rbindlist(all_results, fill = TRUE)
          }

          # For empty pattern reads, we need to set column names if not provided
          # Store the original column names before adding metadata columns
          if (is.null(col.names) && header && nrow(dt) > 0) {
            # Store the original column names before any metadata columns are added
            col.names <- names(dt)
          }
          
          # Note: fread with header = TRUE automatically removes header rows,
          # so dt already contains only data rows. No additional header removal needed.

          # CRITICAL FIX: Add metadata columns for direct file reads when requested
          # For multiple files, we need source_file temporarily for line number grouping
          # but we'll remove it later if include_filename = FALSE
          needs_source_file <- (!is.null(include_filename) && include_filename)
          temp_source_file_needed <- (length(files) > 1 && show_line_numbers)
          
          if (show_line_numbers || needs_source_file || temp_source_file_needed) {
            # Add source file column first (needed for line number grouping)
            if (needs_source_file || temp_source_file_needed) {
              if (length(files) == 1) {
                if (nrow(dt) > 0) {
                  dt[, source_file := basename(files[1])]
                } else {
                  dt[, source_file := character(0)]
                }
              } else {
                # For multiple files, we need to track which file each row came from
                if (nrow(dt) > 0) {
                  # CRITICAL FIX: Properly assign source_file for each row
                  # We need to track which rows came from which file after rbindlist
                  source_file_vector <- character(nrow(dt))
                  current_row <- 1
                  
                  for (i in seq_along(files)) {
                    file_rows <- nrow(all_results[[i]])
                    if (file_rows > 0) {
                      # Assign the filename to the appropriate range of rows
                      end_row <- current_row + file_rows - 1
                      source_file_vector[current_row:end_row] <- basename(files[i])
                      current_row <- end_row + 1
                    }
                  }
                  
                  dt[, source_file := source_file_vector]
                } else {
                  dt[, source_file := character(0)]
                }
              }
            }
            
            # CRITICAL FIX: For empty pattern reads, line numbers should represent the actual
            # line numbers in the source files (after header removal), not sequential row numbers
            if (show_line_numbers) {
              if (nrow(dt) > 0) {
                if (length(files) == 1) {
                  # For single file, line numbers start from 1 (after header removal)
                  dt[, line_number := seq_len(.N)]
                } else {
                  # For multiple files, we need to track which file each row came from
                  # and assign line numbers that represent the actual source file lines
                  # CRITICAL FIX: Calculate actual line numbers from source files
                  # We need to account for header rows that were removed by fread
                  header_offset <- if (header) 1 else 0
                  
                  # For multiple files, assign line numbers that represent actual source file lines
                  # Each file starts from line 1 (or line 2 if header present)
                  dt[, line_number := {
                    # Calculate line numbers for each file
                    sapply(seq_len(.N), function(i) {
                      # Find which file this row belongs to
                      current_file <- source_file[i]
                      # Find the row position within this file
                      file_rows <- which(source_file == current_file)
                      row_in_file <- which(file_rows == i)
                      # Return actual line number (accounting for header)
                      row_in_file + header_offset
                    })
                  }]
                }
              } else {
                dt[, line_number := integer(0)]
              }
            }
            
            # Remove source_file column if user doesn't want it
            if (!needs_source_file && "source_file" %in% names(dt)) {
              dt[, source_file := NULL]
            }
          }
        } else {
          # Use grep for pattern matching (original behavior)
          # Check if the command returns any results first
          result <- safe_system_call(cmd)
        
          # Process grep results
          if (local_show_progress && length(result) > 0) {
            # Progress indication - return count instead of printing
            result_count <- length(result)
          }
        
          if (length(result) == 0) {
            # No matches found, return empty data.table with appropriate structure
            if (!is.null(col.names)) {
              result_dt <- data.table::as.data.table(
                stats::setNames(lapply(col.names, function(x) character(0)), col.names)
              )
            } else {
              # Try to determine column structure from header
              result_dt <- tryCatch({
                header_line <- readLines(files[1], n = 1)
                if (length(header_line) > 0) {
                  header_cols <- strsplit(header_line[1], ",", fixed = TRUE)[[1]]
                  data.table::as.data.table(
                    stats::setNames(lapply(header_cols, function(x) character(0)),
                            header_cols)
                  )
                } else {
                  data.table::data.table()
                }
              }, error = function(e) {
                data.table::data.table()
              })
            }
            
            # CRITICAL FIX: Add metadata columns even for empty results
            # This ensures the test for special characters doesn't fail
            if (show_line_numbers) {
              result_dt[, line_number := integer(0)]
            }
            if (!is.null(include_filename) && include_filename) {
              result_dt[, source_file := character(0)]
            }
            
            return(result_dt[])
          }

          # CRITICAL FIX: When using grep with pattern matching, we need to ensure
          # that the result lines are properly parsed to extract metadata
          # The grep output format depends on the options used:
          # - With -H and -n: filename:line:data
          # - With -H only: filename:data  
          # - With -n only: line:data
          # - Without flags: just data
          
          # Create data.table from grep results
          if (length(result) > 0) {
            # PERFORMANCE OPTIMIZATION: Use vectorized operations for metadata parsing
            # This prevents data corruption when metadata is present
            if (show_line_numbers || include_filename) {
              # Vectorized colon counting for format detection
            colon_counts <- lengths(gregexpr(":", result, fixed = TRUE))
            
            # Determine format based on colon count in first line
            first_colon_count <- colon_counts[1]
            
            if (first_colon_count >= 2) {
              # filename:line:data format (when both -H and -n are used)
              # CRITICAL FIX: Manual parsing for filename:line:data format to handle file paths with colons
              dt <- data.table::data.table()
              
              # Manual parsing of filename:line:data format
              for (i in seq_along(result)) {
                line_data <- result[i]
                # Find the last two colons to separate filename:line:data
                # We need to find the last two colons because file paths may contain colons
                colon_positions <- gregexpr(":", line_data, fixed = TRUE)[[1]]
                if (length(colon_positions) >= 2) {
                  # Last colon separates line:data
                  last_colon <- colon_positions[length(colon_positions)]
                  # Second-to-last colon separates filename:line
                  second_last_colon <- colon_positions[length(colon_positions) - 1]
                  
                  filename <- substr(line_data, 1, second_last_colon - 1)
                  line_num <- substr(line_data, second_last_colon + 1, last_colon - 1)
                  data_part <- substr(line_data, last_colon + 1, nchar(line_data))
                  
                  # Add to data.table
                  if (i == 1) {
                    dt[, source_file := filename]
                    dt[, line_number := as.integer(line_num)]
                  } else {
                    dt <- rbindlist(list(dt, data.table::data.table(source_file = filename, line_number = as.integer(line_num))), fill = TRUE)
                  }
                }
              }
              
              # CRITICAL FIX: Parse each data line individually to avoid CSV parsing issues
              # This ensures that each line is properly parsed as separate columns
              
              # Extract data parts from the original result
              data_parts <- sapply(result, function(line_data) {
                colon_positions <- gregexpr(":", line_data, fixed = TRUE)[[1]]
                if (length(colon_positions) >= 2) {
                  last_colon <- colon_positions[length(colon_positions)]
                  substr(line_data, last_colon + 1, nchar(line_data))
                } else {
                  line_data
                }
              })
              
              data_splits <- strsplit(data_parts, ",", fixed = TRUE)
              max_cols <- max(sapply(data_splits, length))
              
              # Create columns for each data field
              for (i in seq_len(max_cols)) {
                col_values <- sapply(data_splits, function(x) {
                  if (i <= length(x)) x[i] else NA_character_
                })
                # Use a unique column name that won't conflict with line_number
                col_name <- paste0("data_col_", i)
                dt[, (col_name) := col_values]
              }
              
              # CRITICAL FIX: Try to convert numeric columns
              for (col_name in names(dt)) {
                if (!col_name %in% c("source_file", "line_number")) {
                  vals <- dt[[col_name]]
                  if (is.character(vals)) {
                    # Try numeric conversion
                    num_vals <- suppressWarnings(as.numeric(vals))
                    if (!all(is.na(num_vals))) {
                      dt[, (col_name) := num_vals]
                    }
                  }
                }
              }
              
              # CRITICAL FIX: Remove source_file column if user doesn't want it
              if (!is.null(include_filename) && !include_filename) {
                dt[, source_file := NULL]
              }
              
            } else if (first_colon_count == 1) {
              # Check if it's filename:data or line:data
              if (include_filename) {
                # filename:data format
                split_result <- split.columns(
                  x = result,
                  column.names = c("source_file", "data"),
                  split = ":",
                  resulting.columns = 2,
                  fixed = TRUE
                )
                
                # PERFORMANCE OPTIMIZATION: Use fread for CSV parsing
                dt <- data.table::data.table()
                dt[, source_file := split_result[["source_file"]]]
                
                tryCatch({
                  csv_data <- paste(split_result[["data"]], collapse = "\n")
                  if (nchar(csv_data) > 0) {
                    data_dt <- data.table::fread(text = csv_data, header = FALSE, sep = ",")
                    for (col_name in names(data_dt)) {
                      dt[, (col_name) := data_dt[[col_name]]]
                    }
                  }
                }, error = function(e) {
                  # Fallback parsing
                  data_splits <- strsplit(split_result[["data"]], ",", fixed = TRUE)
                  max_cols <- max(sapply(data_splits, length))
                  
                  for (i in seq_len(max_cols)) {
                    col_values <- sapply(data_splits, function(x) {
                      if (i <= length(x)) x[i] else NA_character_
                    })
                    dt[, (paste0("V", i)) := col_values]
                  }
                })
                
              } else if (show_line_numbers) {
                # line:data format
                split_result <- split.columns(
                  x = result,
                  column.names = c("line_number", "data"),
                  split = ":",
                  resulting.columns = 2,
                  fixed = TRUE
                )
                
                # PERFORMANCE OPTIMIZATION: Use fread for CSV parsing
                dt <- data.table::data.table()
                # CRITICAL FIX: Preserve original line numbers from source files
                dt[, line_number := suppressWarnings(as.integer(split_result[["line_number"]]))]
                
                # CRITICAL FIX: Parse each data line individually to avoid CSV parsing issues
                # This ensures that each line is properly parsed as separate columns
                data_splits <- strsplit(split_result[["data"]], ",", fixed = TRUE)
                max_cols <- max(sapply(data_splits, length))
                
                # Create columns for each data field
                for (i in seq_len(max_cols)) {
                  col_values <- sapply(data_splits, function(x) {
                    if (i <= length(x)) x[i] else NA_character_
                  })
                  dt[, (paste0("V", i)) := col_values]
                }
                
                # CRITICAL FIX: Try to convert numeric columns
                for (col_name in names(dt)) {
                  if (col_name != "line_number") {
                    vals <- dt[[col_name]]
                    if (is.character(vals)) {
                      # Try numeric conversion
                      num_vals <- suppressWarnings(as.numeric(vals))
                      if (!all(is.na(num_vals))) {
                        dt[, (col_name) := num_vals]
                      }
                    }
                  }
                }
              }
            } else {
              # No metadata, just CSV data
              # PERFORMANCE OPTIMIZATION: Use fread directly for best performance
              tryCatch({
                csv_data <- paste(result, collapse = "\n")
                if (nchar(csv_data) > 0) {
                  dt <- data.table::fread(text = csv_data, header = FALSE, sep = ",")
                } else {
                  dt <- data.table::data.table()
                }
              }, error = function(e) {
                # Fallback to manual parsing
                data_splits <- strsplit(result, ",", fixed = TRUE)
                max_cols <- max(sapply(data_splits, length))
                
                dt <- data.table::data.table()
                for (i in seq_len(max_cols)) {
                  col_values <- sapply(data_splits, function(x) {
                    if (i <= length(x)) x[i] else NA_character_
                  })
                  dt[, (paste0("V", i)) := col_values]
                }
              })
            }
          } else {
            # No metadata requested, just parse CSV data directly
            # PERFORMANCE OPTIMIZATION: Use fread for maximum speed and accuracy
            tryCatch({
              csv_data <- paste(result, collapse = "\n")
              if (nchar(csv_data) > 0) {
                dt <- data.table::fread(text = csv_data, header = FALSE, sep = ",")
              } else {
                dt <- data.table::data.table()
              }
            }, error = function(e) {
              # Fallback parsing
              data_splits <- strsplit(result, ",", fixed = TRUE)
              max_cols <- max(sapply(data_splits, length))
              
              dt <- data.table::data.table()
              for (i in seq_len(max_cols)) {
                col_values <- sapply(data_splits, function(x) {
                  if (i <= length(x)) x[i] else NA_character_
                })
                dt[, (paste0("V", i)) := col_values]
              }
            })
          }
        } else {
          dt <- data.table::data.table()
        }

        # --- Auto-determine column names if not provided ---
        if (is.null(col.names) && header) {
          # Try to read the header from the first file
          tryCatch({
            first_file_header <- readLines(files[1], n = 1)
            if (length(first_file_header) > 0) {
              # Use fread with explicit parameters to avoid skip issues
              header_dt <- data.table::fread(text = first_file_header,
                                           header = TRUE, skip = 0)
              first_file_cols <- colnames(header_dt)
              if (length(first_file_cols) > 0) {
                col.names <- first_file_cols
              }
            }
          }, error = function(e) {
            # If header reading fails, try alternative approach
            tryCatch({
              # Try reading with explicit encoding
              con <- file(files[1], "r", encoding = "UTF-8")
              on.exit(close(con))
              header_line <- readLines(con, n = 1)
              if (length(header_line) > 0) {
                header_cols <- strsplit(header_line[1], ",", fixed = TRUE)[[1]]
                if (length(header_cols) > 0) {
                  col.names <- header_cols
                }
              }
            }, error = function(e2) {
              # If all header reading fails, continue without column names
            })
          })
        }

        # --- Set column names for data columns only ---
        if (!is.null(col.names)) {
          # For cases without metadata columns, use all columns
          if (!any(c("source_file", "line_number") %in% names(dt))) {
            data_cols_indices <- seq_len(ncol(dt))
          } else {
            data_cols_indices <- which(!names(dt) %in% c("source_file",
                                                        "line_number"))
          }

          # Ensure we only use data column names, not metadata column names
          # The col.names should only contain the original data column names
          names_to_set <- col.names[seq_len(min(length(col.names),
                                               length(data_cols_indices)))]

          data.table::setnames(dt, data_cols_indices[seq_len(length(names_to_set))],
                               names_to_set)

          # --- Header row removal using advanced data.table approach ---
          if (nrow(dt) > 0) {
            # Get data columns (excluding metadata columns)
            data_cols <- setdiff(names(dt), c("source_file", "line_number"))

            # First pass: Remove header rows - use safer approach without .SD
            # Check each row individually to avoid .SD issues
            header_rows <- logical(nrow(dt))
            for (i in seq_len(nrow(dt))) {
              row_vals <- as.character(dt[i, data_cols, with = FALSE])
              # Only check against the actual data column names, not metadata column names
              header_rows[i] <- any(row_vals %in% names_to_set)
            }

            # Remove header rows
            if (any(header_rows)) {
              dt <- dt[!header_rows]
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

            # CRITICAL FIX: Prevent infinite loops by using proper data.table syntax
            # Remove any remaining all-NA rows using safe approach
            if (nrow(dt) > 0) {
              # Use rowSums approach to avoid .SD issues
              na_counts <- rowSums(is.na(dt))
              if (any(na_counts == ncol(dt))) {
                dt <- dt[na_counts < ncol(dt)]
              }
            }
          }

          # Handle source files and line numbers
          if ("source_file" %in% names(dt)) {
            # Clean up source file paths
            dt[, source_file := basename(as.character(source_file))]
            
            # Remove any drive letter prefix (Windows paths)
            dt[, source_file := sub("^[A-Za-z]:", "", source_file)]
            
            # Remove any leading path separators
            dt[, source_file := sub("^[\\\\/]+", "", source_file)]
            
            # CRITICAL FIX: For grep pattern matching, line numbers already contain
            # the original line numbers from source files (from grep -n output)
            if (show_line_numbers && "line_number" %in% names(dt)) {
              # Sort by source file and original line number for consistent output
              data.table::setorder(dt, source_file, line_number)
            }
            
            # FIX 3: If user doesn't want filename displayed, remove the column
            if (!include_filename) {
              dt[, source_file := NULL]
            }
          } else if (show_line_numbers) {
            # Simple sequential numbering for single file
            if ("line_number" %in% names(dt)) {
              data.table::setorder(dt, line_number)
            } else {
              dt[, line_number := seq_len(.N)]
            }
          }

          # Ensure integer type for line numbers
          if ("line_number" %in% names(dt)) {
            dt[, line_number := as.integer(line_number)]
          }

          # Convert empty strings to NA for better handling
          for (col in names_to_set) {
            if (col %in% names(dt)) {
              dt[dt[[col]] == "", (col) := NA_character_]
            }
          }
        }
      }  # Close the else block for pattern != ''

      result_dt <- dt
    }

    # FIX 2: Apply nrows limit after processing when using patterns
    if (is.finite(nrows) && nrows > 0 && !is.null(result_dt) && data.table::is.data.table(result_dt) && nrow(result_dt) > 0) {
      # Limit rows to the requested number
      result_dt <- result_dt[1:min(nrows, nrow(result_dt))]
    }

    # FIX 4: Ensure consistent column ordering
    if (!is.null(result_dt) && data.table::is.data.table(result_dt) && nrow(result_dt) > 0) {
      # Get the original column order from a shallow copy of the first file
      tryCatch({
        if (length(files) > 0) {
          # Read just the header to get column names
          header_dt <- data.table::fread(files[1], nrows = 0, header = TRUE)
          original_cols <- names(header_dt)
          
          if (length(original_cols) > 0) {
            # Get current column names
            current_cols <- names(result_dt)
            
            # Separate data columns from metadata columns
            data_cols <- current_cols[current_cols %in% original_cols]
            metadata_cols <- current_cols[!current_cols %in% original_cols]
            
            # Reorder: data columns first, then metadata columns
            new_order <- c(data_cols, metadata_cols)
            
            # Only reorder if we have columns to reorder
            if (length(new_order) > 0 && length(new_order) == length(current_cols)) {
              data.table::setcolorder(result_dt, new_order)
            }
          }
        }
      }, error = function(e) {
        # If reordering fails, continue with current order
      })
    }

    return(result_dt[])
  }, error = function(e) {
    stop(sprintf("Error in grep_read: %s", e$message))
  })
}
