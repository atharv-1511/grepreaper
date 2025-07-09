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
      # Always read the header row from the first file if header=TRUE
      if (header && is.null(col.names)) {
        first_file_header <- safe_system_call(sprintf("head -n 1 %s", shQuote(files[1])))
        header_dt <- data.table::fread(text=first_file_header, header = TRUE)
        first_file_cols <- colnames(header_dt)
        if(length(first_file_cols) > 0) {
          col.names <- first_file_cols
        }
      }
      if (show_progress) {
        message("Reading data from ", length(files), " file(s)...")
      }
      # If header=TRUE, skip the first row (header) in the data
      fread_skip <- skip
      if (header) {
        fread_skip <- skip + 1
      }
      dt <- data.table::fread(cmd = cmd, header = FALSE, nrows = nrows, skip = fread_skip, ...)
      # Remove duplicate header rows (for multiple files) -- REMOVE OLD LOGIC
      # (old block deleted)
      # If the grep result is empty, return an empty data.table with correct columns
      if (nrow(dt) == 0 || ncol(dt) == 0) {
        if (!is.null(col.names)) {
          res <- data.table::as.data.table(setNames(lapply(col.names, function(x) character(0)), col.names))
        } else {
          res <- data.table::data.table()
        }
      } else {
        # --- COLUMN ASSIGNMENT AND PREPEND HANDLING ---
        # Determine what prepends the data (filename, line_number, both, or neither)
        has_filename <- include_filename
        has_line_num <- show_line_numbers
        # Robustly handle prepended columns
        if(has_filename && has_line_num){
            split_cols <- data.table::tstrsplit(dt[[1]], ":", fixed = TRUE)
            if(length(split_cols) >= 3){
               dt[, source_file := split_cols[[1]]]
               dt[, line_number := as.integer(split_cols[[2]])]
               dt[, (1) := do.call(paste, c(split_cols[-(1:2)], sep=":"))]
            }
        } else if (has_filename) {
            split_cols <- data.table::tstrsplit(dt[[1]], ":", fixed = TRUE)
            if (length(split_cols) >= 2) {
                dt[, source_file := split_cols[[1]]]
                dt[, (1) := do.call(paste, c(split_cols[-1], sep=":"))]
            }
        } else if(has_line_num){
            split_cols <- data.table::tstrsplit(dt[[1]], ":", fixed = TRUE)
            if (length(split_cols) >= 2) {
                dt[, line_number := as.integer(split_cols[[1]])]
                dt[, (1) := do.call(paste, c(split_cols[-1], sep=":"))]
            }
        }
        # Remove line_number column if show_line_numbers is FALSE
        if (!show_line_numbers && "line_number" %in% names(dt)) {
          dt[, line_number := NULL]
        }
        # Remove source_file column if include_filename is FALSE
        if (!include_filename && "source_file" %in% names(dt)) {
          dt[, source_file := NULL]
        }
        # Set column names for data columns only and robustly remove header row if present
        if (!is.null(col.names)) {
          data_col_count <- ncol(dt) - (if(include_filename) 1 else 0) - (if(show_line_numbers) 1 else 0)
          names_to_set <- col.names[1:min(length(col.names), data_col_count)]
          data_cols_indices <- which(!names(dt) %in% c("source_file", "line_number"))
          data.table::setnames(dt, data_cols_indices[1:length(names_to_set)], names_to_set)
          # Remove header row if present as first row
          if (nrow(dt) > 0 && all(dt[1, ..names_to_set] == names_to_set)) {
            dt <- dt[-1]
          }
        }
        res <- dt
      }
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

