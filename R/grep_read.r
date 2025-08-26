#' grep_read: Efficiently read and filter lines from one or more files using grep,
#' returning a data.table.
#'
#' @param files Character vector of file paths to read.
#' @param path Optional. Directory path to search for files.
#' @param file_pattern Optional. A pattern to filter filenames when using the
#'   `path` argument. Passed to `list.files`.
#' @param pattern Pattern to search for within files (passed to grep).
#' @param invert Logical; if TRUE, return non-matching lines.
#' @param ignore_case Logical; if TRUE, perform case-insensitive matching.
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
#' @param show_progress Logical; if TRUE, show progress indicators.
#' @param ... Additional arguments passed to fread.
#' @return A data.table with different structures based on the options:
#'   - Default: Data columns with original types preserved
#'   - show_line_numbers=TRUE: Additional 'line_number' column (integer)
#'   - include_filename=TRUE: Additional 'source_file' column (character)
#'   - only_matching=TRUE: Single 'match' column with matched substrings
#'   - count_only=TRUE: 'source_file' and 'count' columns
#'   - show_cmd=TRUE: Character string containing the grep command
#' @importFrom data.table fread setnames data.table as.data.table rbindlist setorder ":=" .N
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
                     pattern = "", invert = FALSE, ignore_case = FALSE,
                     fixed = FALSE, show_cmd = FALSE, recursive = FALSE,
                     word_match = FALSE, show_line_numbers = FALSE,
                     only_matching = FALSE, count_only = FALSE, nrows = Inf,
                     skip = 0, header = TRUE, col.names = NULL,
                     include_filename = NULL, show_progress = FALSE, ...) {
  # Ensure data.table is available
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("The 'data.table' package is required but not installed. ",
         "Please install it via install.packages('data.table').")
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
    
    if (include_filename || (count_only && length(files) > 1) || 
        (show_line_numbers && length(files) > 1)) {
      options <- c(options, "-H")
    }
    if ((show_line_numbers || include_filename) && length(files) == 1) {
      options <- c(options, "-H")
    }
    
    options_str <- paste(options, collapse = " ")
    cmd <- build_grep_cmd(pattern = pattern, files = files, options = options_str)
    return(cmd)
  }

  # Set progress option
  if (show_progress) {
    options(grepreaper.show_progress = TRUE)
  }

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
  
  # CRITICAL FIX: Always add -H when we need metadata
  # `-H` prints the filename. It's needed for include_filename, but also for
  # count_only when multiple files are provided, to distinguish counts.
  # Also, when we have multiple files and want line numbers, we need -H to get
  # filename:line:data format
  if (include_filename || (count_only && length(files) > 1) || 
      (show_line_numbers && length(files) > 1)) {
    options <- c(options, "-H")
  }

  # CRITICAL FIX: Always add -H for single files when we need metadata
  # This ensures consistent behavior for line numbers and filename inclusion
  if ((show_line_numbers || include_filename) && length(files) == 1) {
    options <- c(options, "-H")
  }

  options_str <- paste(options, collapse = " ")

  # Build the command
  cmd <- build_grep_cmd(pattern = pattern, files = files, options = options_str)

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
      # Only return counts of matches per file
      result <- safe_system_call(cmd)
      if (length(result) == 0) {
        result_dt <- data.table::data.table(file = character(0),
                                           count = integer(0))
      } else {
        if (include_filename) {
          # Parse filename:count format
          splits <- strsplit(result, ":", fixed = TRUE)
          source_file <- sapply(splits, function(x) x[1])
          count_val <- sapply(splits, function(x) as.integer(x[2]))
          result_dt <- data.table::data.table(source_file = source_file,
                                             count = count_val)
        } else {
          result_dt <- data.table::data.table(count = as.integer(result))
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
        if (is.null(col.names) && header && nrow(dt) > 0) {
          col.names <- names(dt)
        }
        
                # CRITICAL FIX: Add metadata columns for direct file reads when requested
        # For multiple files, we always need source_file for proper line number grouping
        needs_source_file <- (!is.null(include_filename) && include_filename) || 
                           (length(files) > 1 && show_line_numbers)
        
        if (show_line_numbers || needs_source_file) {
          # Add source file column first (needed for line number grouping)
          if (needs_source_file) {
            if (length(files) == 1) {
              if (nrow(dt) > 0) {
                dt[, source_file := basename(files[1])]
              } else {
                dt[, source_file := character(0)]
              }
            } else {
              # For multiple files, we need to track which file each row came from
              if (nrow(dt) > 0) {
                file_indices <- rep(seq_along(files), sapply(all_results, nrow))
                dt[, source_file := basename(files[file_indices])]
              } else {
                dt[, source_file := character(0)]
              }
            }
          }
          
          # Add line numbers after source_file is available
          if (show_line_numbers) {
            if (nrow(dt) > 0) {
              if (length(files) == 1) {
                dt[, line_number := seq_len(.N)]
              } else {
                # For multiple files, restart line numbers from 1 for each file
                # Create sequential line numbers that restart for each file
                dt[, line_number := rep(seq_len(max(sapply(all_results, nrow))), length(files))]
              }
            } else {
              dt[, line_number := integer(0)]
            }
          }
        }
      } else {
        # Use grep for pattern matching
        # Check if the command returns any results first
        result <- safe_system_call(cmd)
        
        # Show progress information if requested
        if (show_progress) {
          cat("Grep command:", cmd, "\n")
          cat("Grep returned", length(result), "lines\n")
          if (length(result) > 0) {
            cat("First few lines from grep:\n")
            for (i in seq_len(min(3, length(result)))) {
              cat("  ", i, ":", result[i], "\n")
            }
          }
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
          if (show_line_numbers || include_filename) {
            # Create empty metadata columns
            if (show_line_numbers) {
              result_dt[, line_number := integer(0)]
            }
            if (include_filename) {
              result_dt[, source_file := character(0)]
            }
          }
          
          return(result_dt)
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
              # PERFORMANCE OPTIMIZATION: Use vectorized split.columns
              split_result <- split.columns(
                x = result,
                column.names = c("source_file", "line_number", "data"),
                split = ":",
                resulting.columns = 3,
                fixed = TRUE
              )
              
              # ACCURACY IMPROVEMENT: Use data.table's fread for CSV parsing
              # This is much more reliable than manual strsplit
              dt <- data.table::data.table()
              dt[, source_file := split_result$source_file]
              dt[, line_number := suppressWarnings(as.integer(split_result$line_number))]
              
              # PERFORMANCE OPTIMIZATION: Use fread for CSV parsing instead of manual loops
              tryCatch({
                # Parse CSV data using fread for accuracy and speed
                csv_data <- paste(split_result$data, collapse = "\n")
                if (nchar(csv_data) > 0) {
                  data_dt <- data.table::fread(text = csv_data, header = FALSE, sep = ",")
                  # Add data columns efficiently
                  for (col_name in names(data_dt)) {
                    dt[, (col_name) := data_dt[[col_name]]]
                  }
                }
              }, error = function(e) {
                # Fallback to manual parsing if fread fails
                data_splits <- strsplit(split_result$data, ",", fixed = TRUE)
                max_cols <- max(sapply(data_splits, length))
                
                for (i in seq_len(max_cols)) {
                  col_values <- sapply(data_splits, function(x) {
                    if (i <= length(x)) x[i] else NA_character_
                  })
                  dt[, (paste0("V", i)) := col_values]
                }
              })
              
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
                dt[, source_file := split_result$source_file]
                
                tryCatch({
                  csv_data <- paste(split_result$data, collapse = "\n")
                  if (nchar(csv_data) > 0) {
                    data_dt <- data.table::fread(text = csv_data, header = FALSE, sep = ",")
                    for (col_name in names(data_dt)) {
                      dt[, (col_name) := data_dt[[col_name]]]
                    }
                  }
                }, error = function(e) {
                  # Fallback parsing
                  data_splits <- strsplit(split_result$data, ",", fixed = TRUE)
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
                dt[, line_number := suppressWarnings(as.integer(split_result$line_number))]
                
                tryCatch({
                  csv_data <- paste(split_result$data, collapse = "\n")
                  if (nchar(csv_data) > 0) {
                    data_dt <- data.table::fread(text = csv_data, header = FALSE, sep = ",")
                    for (col_name in names(data_dt)) {
                      dt[, (col_name) := data_dt[[col_name]]]
                    }
                  }
                }, error = function(e) {
                  # Fallback parsing
                  data_splits <- strsplit(split_result$data, ",", fixed = TRUE)
                  max_cols <- max(sapply(data_splits, length))
                  
                  for (i in seq_len(max_cols)) {
                    col_values <- sapply(data_splits, function(x) {
                      if (i <= length(x)) x[i] else NA_character_
                    })
                    dt[, (paste0("V", i)) := col_values]
                  }
                })
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
              header_rows[i] <- any(row_vals %in% names_to_set)
            }

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

            # Group by source file for line numbers
            if (show_line_numbers) {
              # First sort by source file and original line number
              if ("line_number" %in% names(dt)) {
                data.table::setorder(dt, source_file, line_number)
              }
              # Then renumber within each file
              dt[, line_number := seq_len(.N), by = source_file]
            }

            # If user doesn't want filename displayed, remove the column
            if (!include_filename) {
              dt[, source_file := NULL]
            }
          } else if (show_line_numbers) {
            # Simple sequential numbering for single file
            if ("line_number" %in% names(dt)) {
              data.table::setorder(dt, line_number)
            }
            dt[, line_number := seq_len(.N)]
          }

          # Ensure integer type for line numbers
          if ("line_number" %in% names(dt)) {
            dt[, line_number := as.integer(line_number)]
          }

          # Remove all-NA rows using safe data.table approach
          if (nrow(dt) > 0) {
            # Use rowSums for better performance and safety
            na_counts <- rowSums(is.na(dt))
            if (any(na_counts == ncol(dt))) {
              dt <- dt[na_counts < ncol(dt)]
            }
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

    return(result_dt)
  }, error = function(e) {
    stop(sprintf("Error in grep_read: %s", e$message))
  })
}
