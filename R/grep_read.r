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
        res <- data.table::data.table(file = files, count = 0)
      } else {
        count_data <- lapply(result, function(line) {
          parts <- strsplit(line, ":", fixed = TRUE)[[1]]
          if (length(parts) >= 2) {
            file_path <- paste(parts[1:(length(parts)-1)], collapse=":")
            count <- as.integer(parts[length(parts)])
            list(file = file_path, count = count)
          } else {
            list(file = files[1], count = as.integer(line))
          }
        })
        res <- data.table::rbindlist(count_data)
      }
    } else {
      # --- HEADER HANDLING FIX START ---
      # 1. Read the header and a shallow sample from the first file
      if (header && is.null(col.names)) {
        first_file_header <- safe_system_call(sprintf("head -n 1 %s", shQuote(files[1])))
        header_dt <- data.table::fread(text=first_file_header, header = TRUE)
        first_file_cols <- colnames(header_dt)
        if(length(first_file_cols) > 0) {
          col.names <- first_file_cols
        }
      }
      shallow <- tryCatch(data.table::fread(files[1], nrows = 2, header = TRUE), error = function(e) NULL)
      
      # 2. Check if the file has only a header (no data)
      file_lines <- tryCatch(readLines(files[1]), error = function(e) character(0))
      if (length(file_lines) <= 1) {
        if (!is.null(shallow)) {
          res <- shallow[0]
        } else if (!is.null(col.names)) {
          res <- data.table::as.data.table(setNames(lapply(col.names, function(x) vector()), col.names))
        } else {
          res <- data.table::data.table()
        }
        return(res)
      }
      
      # 3. Check if grep command returns any results
      raw_output <- safe_system_call(cmd)
      if (length(raw_output) == 0) {
        # No matches found, return empty data.table
        if (!is.null(col.names)) {
          res <- data.table::as.data.table(setNames(lapply(col.names, function(x) character(0)), col.names))
        } else {
          res <- data.table::data.table()
        }
        return(res)
      }
      
      # 4. Read the data via fread (no skip needed since we're using cmd)
      dt <- data.table::fread(cmd = cmd, header = FALSE, nrows = nrows, skip = skip, ...)
      
      # --- SIMPLIFIED COLUMN SPLITTING ---
      has_filename <- include_filename
      has_line_num <- show_line_numbers
      
      if (nrow(dt) > 0 && (has_filename || has_line_num)) {
        # DEBUG: Print the original data.table before splitting
        if (show_progress) {
          message("Original data.table before splitting:")
          print(head(dt, 3))
          message("Original column names:")
          print(names(dt))
        }
        
        # Get the first column which contains filename:line:data or line:data
        first_col <- dt[[1]]
        
        # DEBUG: Print the raw data structure
        if (show_progress) {
          message("Raw first column structure:")
          print(head(first_col, 3))
        }
        
        # Split the first column on colons
        split_parts <- data.table::tstrsplit(first_col, ":", fixed = TRUE)
        
        # Determine how many parts we have
        n_parts <- length(split_parts)
        
        if (show_progress) {
          message("Number of split parts: ", n_parts)
          message("Split parts structure:")
          print(lapply(split_parts, head, 3))
        }
        
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
          
          # Now add the data columns from the original data.table
          # The original data.table has the correct structure after fread
          # We just need to copy the data columns (V2, V3, etc.)
          original_cols <- names(dt)
          data_cols <- original_cols[-1]  # All columns except the first
          
          if (show_progress) {
            message("Original data columns: ", paste(data_cols, collapse = ", "))
            message("Data columns content:")
            for (col in data_cols) {
              message("  ", col, ": ", paste(head(dt[[col]], 3), collapse = ", "))
            }
          }
          
          # Copy the data columns to the new data.table
          for (col in data_cols) {
            new_dt[, (col) := dt[[col]]]
          }
          
          # Replace the original data.table with the new one
          dt <- new_dt
          
          # DEBUG: Print the data.table after splitting
          if (show_progress) {
            message("Data.table after splitting:")
            print(head(dt, 3))
            message("Column names after splitting: ", paste(names(dt), collapse = ", "))
          }
        }
      }
      
      # --- Set column names for data columns only ---
      print("DEBUG: About to check col.names")
      print(paste("col.names is NULL:", is.null(col.names)))
      if (!is.null(col.names)) {
        print(paste("col.names:", paste(col.names, collapse = ", ")))
        data_cols_indices <- which(!names(dt) %in% c("source_file", "line_number"))
        names_to_set <- col.names[1:min(length(col.names), length(data_cols_indices))]
        
        # DEBUG: Print column mapping
        if (show_progress) {
          message("Column mapping:")
          message("  Data column indices: ", paste(data_cols_indices, collapse = ", "))
          message("  Names to set: ", paste(names_to_set, collapse = ", "))
          message("  Current names: ", paste(names(dt), collapse = ", "))
        }
        
        # Simple debug print
        print("Before column name assignment:")
        print(paste("col.names:", paste(col.names, collapse = ", ")))
        print(paste("data_cols_indices:", paste(data_cols_indices, collapse = ", ")))
        print(paste("names_to_set:", paste(names_to_set, collapse = ", ")))
        print(paste("Current names:", paste(names(dt), collapse = ", ")))
        
        data.table::setnames(dt, data_cols_indices[1:length(names_to_set)], names_to_set)
        
        print("After column name assignment:")
        print(paste("Final names:", paste(names(dt), collapse = ", ")))
        
        # --- Header row removal using mentor's data.table approach ---
        if (nrow(dt) > 0) {
          # Remove header rows using data.table filters
          the_variables <- names_to_set
          header_identification <- paste(sprintf("%s == '%s'", the_variables, the_variables), collapse = " & ")
          header_row_idx <- dt[, which(eval(parse(text = header_identification)))]
          if (length(header_row_idx) > 0) {
            dt <- dt[-header_row_idx]
          }
          
          # Remove all-NA rows using data.table approach
          na_row_idx <- dt[, which(rowMeans(is.na(.SD)) < 1)]
          if (length(na_row_idx) > 0) {
            dt <- dt[na_row_idx]
          }
          
          # Convert empty strings to NA for better handling
          for (col in names_to_set) {
            if (col %in% names(dt)) {
              dt[dt[[col]] == "", (col) := NA_character_]
            }
          }
        }
        
        # --- Type restoration: only after header/NA row removal ---
        if (nrow(dt) > 0 && !is.null(shallow)) {
          col_types <- sapply(shallow, class)
          for (col in names_to_set) {
            if (col %in% names(dt) && col %in% names(col_types)) {
              col_class <- col_types[[col]][1]
              # Only restore type if not all NA and not header name
              if (!all(is.na(dt[[col]])) && !all(dt[[col]] == col)) {
                if (col_class == "numeric") {
                  dt[[col]] <- suppressWarnings(as.numeric(dt[[col]]))
                } else if (col_class == "integer") {
                  dt[[col]] <- suppressWarnings(as.integer(dt[[col]]))
                } else if (col_class == "logical") {
                  dt[[col]] <- suppressWarnings(as.logical(dt[[col]]))
                } else if (col_class == "factor") {
                  dt[[col]] <- suppressWarnings(factor(dt[[col]], levels = levels(shallow[[col]])))
                } else if (col_class == "Date") {
                  # More robust date parsing
                  dt[[col]] <- suppressWarnings(tryCatch(
                    as.Date(dt[[col]]), 
                    error = function(e) as.character(dt[[col]])
                  ))
                } else if (col_class == "POSIXct") {
                  # More robust datetime parsing
                  dt[[col]] <- suppressWarnings(tryCatch(
                    as.POSIXct(dt[[col]]), 
                    error = function(e) as.character(dt[[col]])
                  ))
                } else if (col_class == "complex") {
                  dt[[col]] <- suppressWarnings(as.complex(dt[[col]]))
                } else if (col_class == "list") {
                  dt[[col]] <- suppressWarnings(as.list(dt[[col]]))
  } else {
                  dt[[col]] <- as.character(dt[[col]])
                }
              }
            }
          }
        }
      }
      
      # Use 'line' as the column name if show_line_numbers is TRUE
      if (show_line_numbers && "line_number" %in% names(dt)) {
        data.table::setnames(dt, "line_number", "line")
      }
      res <- dt
      # --- HEADER HANDLING FIX END ---
    }
  }, error = function(e) {
    # Uniform error handling
    stop("grepreaper failed: ", e$message)
  }, warning = function(w) {
    # Uniform warning handling
    warning("grepreaper produced a warning: ", w$message)
  })
  
  return(res)
}

