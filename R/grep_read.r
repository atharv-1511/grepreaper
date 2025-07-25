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
          # Robustly split only on the first colon, rest is the match (in case match contains colons)
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
      # 2. If the file has only a header, return an empty data.table with correct types
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
      # 3. Read the data via fread and assign column names
      fread_skip <- skip
      if (header) {
        fread_skip <- skip + 1
      }
      dt <- data.table::fread(cmd = cmd, header = FALSE, nrows = nrows, skip = fread_skip, ...)
      # --- Robustly split columns as early as possible ---
      has_filename <- include_filename
      has_line_num <- show_line_numbers
      # Helper: robustly split first column if it contains colons, else treat as data
      split_first_col <- function(dt, n_data_cols, has_filename, has_line_num) {
        if (nrow(dt) == 0) return(dt)
        col1 <- dt[[1]]
        # Count colons in first row
        n_colon <- lengths(regmatches(col1[1], gregexpr(":", col1[1], fixed=TRUE)))
        expected_colon <- (has_filename & has_line_num) * 2 + (has_filename | has_line_num)
        # If not enough colons, treat as data only
        if (n_colon < expected_colon) return(dt)
        # Split
        split_cols <- data.table::tstrsplit(col1, ":", fixed = TRUE)
        # If not enough columns, treat as data only
        if (length(split_cols) < (expected_colon + 1)) return(dt)
        idx <- 1
        if (has_filename) {
          dt[, source_file := split_cols[[idx]]]
          idx <- idx + 1
        }
        if (has_line_num) {
          dt[, line_number := suppressWarnings(as.integer(split_cols[[idx]]))]
          idx <- idx + 1
        }
        # Remainder is data
        dt[, (1) := do.call(paste, c(split_cols[idx:length(split_cols)], sep=":"))]
        return(dt)
      }
      # Apply robust split
      n_data_cols <- if (!is.null(col.names)) length(col.names) else 1
      dt_split <- split_first_col(dt, n_data_cols, has_filename, has_line_num)
      # Check if splitting produced all NA in data columns; if so, revert to original dt
      data_cols_indices <- which(!names(dt_split) %in% c("source_file", "line_number"))
      if (length(data_cols_indices) > 0 && all(sapply(dt_split[, ..data_cols_indices], function(col) all(is.na(col))))) {
        # Splitting failed, revert to original dt (treat as data only)
        # Remove any added columns
        dt_split <- dt[, 1, drop=FALSE]
        if (has_filename) dt_split[, source_file := NA_character_]
        if (has_line_num) dt_split[, line_number := NA_integer_]
      }
      dt <- dt_split
      # Remove helper columns if not requested
      if (!show_line_numbers && "line_number" %in% names(dt)) {
        dt[, line_number := NULL]
      }
      if (!include_filename && "source_file" %in% names(dt)) {
        dt[, source_file := NULL]
      }
      # --- Set column names for data columns only ---
      if (!is.null(col.names)) {
        data_cols_indices <- which(!names(dt) %in% c("source_file", "line_number"))
        names_to_set <- col.names[1:min(length(col.names), length(data_cols_indices))]
        data.table::setnames(dt, data_cols_indices[1:length(names_to_set)], names_to_set)
        # --- Header row removal: only for data columns ---
        if (nrow(dt) > 0) {
          # Remove header rows: rows where all data columns match their names and are not NA
          header_row_idx <- which(apply(dt[, ..names_to_set], 1, function(x) all(!is.na(x)) && all(x == names_to_set)))
          if (length(header_row_idx) > 0) dt <- dt[-header_row_idx]
          # Remove all-NA rows (only if all data columns are NA)
          na_row_idx <- which(apply(dt[, ..names_to_set], 1, function(x) all(is.na(x))))
          if (length(na_row_idx) > 0) dt <- dt[-na_row_idx]
        }
        # --- Type restoration: only after header/NA row removal, and only if data is not all NA or header ---
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
                  if (!is.factor(dt[[col]])) class(dt[[col]]) <- "factor"
                } else if (col_class == "Date") {
                  dt[[col]] <- suppressWarnings(as.Date(dt[[col]], format = "%Y-%m-%d"))
                  if (!inherits(dt[[col]], "Date")) class(dt[[col]]) <- "Date"
                } else if (col_class == "POSIXct") {
                  dt[[col]] <- suppressWarnings(as.POSIXct(dt[[col]], format = "%Y-%m-%d %H:%M:%S"))
                  if (!inherits(dt[[col]], "POSIXct")) class(dt[[col]]) <- class(shallow[[col]])
                } else if (col_class == "complex") {
                  dt[[col]] <- suppressWarnings(as.complex(dt[[col]]))
                  if (typeof(dt[[col]]) != "complex") storage.mode(dt[[col]]) <- "complex"
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

