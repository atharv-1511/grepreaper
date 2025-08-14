#' grep_read: Efficiently read and filter lines from one or more files using grep, returning a data.table.
#' 
#' @param files Character vector of file paths to read.
#' @param path Optional. Directory path to search for files.
#' @param file_pattern Optional. A pattern to filter filenames when using the `path` argument. Passed to `list.files`.
#' @param pattern Pattern to search for within files (passed to grep).
#' @param invert,ignore_case,fixed,recursive,word_match,show_line_numbers,only_matching,count_only Various grep options.
#' @param nrows,skip,header,col.names,include_filename,show_progress,... Additional options for reading and output.
#' @return A data.table with the filtered results, or the grep command if show_cmd=TRUE.
#' @importFrom data.table fread setnames
#' @export
#' @note When searching for literal strings (not regex patterns), set `fixed = TRUE` to avoid regex interpretation. 
#' For example, searching for "3.94" with `fixed = FALSE` will match "3894" because "." is a regex metacharacter.
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
          # Split the first column on colons
          split_parts <- data.table::tstrsplit(first_col, ":", fixed = TRUE)
          
          # Determine how many parts we have
          n_parts <- length(split_parts)
          
          if (n_parts >= 2) {
            # Create a new data.table to properly reconstruct the data
            new_dt <- data.table::data.table()
            
            # Add filename if requested
            if (has_filename && n_parts >= 3) {
              new_dt[, source_file := split_parts[[1]]]
              # Remove filename from split parts
              split_parts <- split_parts[-1]
              n_parts <- n_parts - 1
            }
            
            # Add line number if requested
            if (has_line_num && n_parts >= 1) {
              new_dt[, line_number := suppressWarnings(as.integer(split_parts[[1]]))]
              # Remove line number from split parts
              split_parts <- split_parts[-1]
              n_parts <- n_parts - 1
            }
            
            # The remaining split_parts contain the first data field
            # We need to combine this with the other columns from dt
            original_cols <- names(dt)
            data_cols <- original_cols[-1]  # All columns except the first
            
            # Add the first data field from split_parts
            if (n_parts > 0) {
              new_dt[, V1 := split_parts[[1]]]
            }
            
            # Copy the remaining data columns to the new data.table
            for (i in seq_along(data_cols)) {
              col_name <- data_cols[i]
              new_dt[, (paste0("V", i+1)) := dt[[col_name]]]
            }
            
            # Replace the original data.table with the new one
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
          # Simple header removal: remove first row if it contains column names
          if (nrow(dt) > 0) {
            first_row <- as.character(dt[1, ])
            # Only remove if the first row exactly matches the column names
            if (length(first_row) == length(names_to_set) && all(first_row == names_to_set)) {
              dt <- dt[-1]
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

