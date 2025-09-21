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
#' @param nrows Integer; maximum number of rows to read.
#' @param skip Integer; number of rows to skip.
#' @param header Logical; if TRUE, treat first row as header.  Note that using FALSE means that the first row will be included as a row of data in the reading process.
#' @param col.names Character vector of column names.
#' @param include_filename Logical; if TRUE, include source filename as a column.
#' @param show_progress Logical; if TRUE, show progress indicators.
#' @param ... Additional arguments passed to fread.
#' @return A data.table with different structures based on the options:
#'   - Default: Data columns with original types preserved
#'   - show_line_numbers=TRUE: Additional 'line_number' column (integer) with source file line numbers
#'   - include_filename=TRUE: Additional 'source_file' column (character)
#'   - only_matching=TRUE: Single 'match' column with matched substrings
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
utils::globalVariables(c(":=", ".N", "V1", "V2", "V3", "count", "rn"))

grep_read <- function(files = NULL, path = NULL, file_pattern = NULL, pattern = "", invert = FALSE, ignore_case = FALSE, fixed = FALSE, show_cmd = FALSE, recursive = FALSE, word_match = FALSE, show_line_numbers = FALSE, only_matching = FALSE, nrows = Inf, skip = 0, header = TRUE, col.names = NULL, include_filename = FALSE, show_progress = FALSE, ...) {
  
  require(data.table)
  
  # Ensure data.table is available
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("The 'data.table' package is required but not installed. Please install it via install.packages('data.table').")
  }
  
  if (is.null(include_filename)) {
    include_filename <- FALSE
  }
  
  if((is.null(files)) & !is.null(path)){
    files <- list.files(path = path, pattern = file_pattern, full.names = TRUE, recursive = recursive, ignore.case = ignore_case)
  }
  
  if(is.na(pattern)){
    pattern <- ""
  }
  
  need_metadata <- (show_line_numbers == T) | (include_filename == T) | (length(files) > 1)
  
  options <- c("-v", "-i", "-F", "-r", "-w", "-n", "-o", "-H")[c(invert, ignore_case, fixed, recursive, word_match, show_line_numbers, only_matching, need_metadata)]
    
  options_str <- paste(options, collapse = " ")
  
  if(show_cmd == TRUE){
    cmd <- build_grep_cmd(pattern = pattern, files = files, options = options_str, fixed = fixed)
    return(cmd)
  }
  
  # Windows-compatible approach: Read files directly and filter in R
  if (.Platform$OS.type == "windows") {
    # Read all files and filter in R for Windows compatibility
    all_data <- list()
    for (file in files) {
      if (file.exists(file)) {
        file_data <- fread(file, header = header, skip = skip, showProgress = show_progress)
        if (pattern != "") {
          # Apply pattern filtering in R
          if (ignore_case) {
            pattern_lower <- tolower(pattern)
            file_data_lower <- file_data[, lapply(.SD, tolower)]
            matches <- apply(file_data_lower, 1, function(row) any(grepl(pattern_lower, row, fixed = fixed)))
          } else {
            matches <- apply(file_data, 1, function(row) any(grepl(pattern, row, fixed = fixed)))
          }
          if (invert) {
            file_data <- file_data[!matches]
          } else {
            file_data <- file_data[matches]
          }
        }
        if (include_filename) {
          file_data[, source_file := basename(file)]
        }
        all_data[[file]] <- file_data
      }
    }
    if (length(all_data) == 0) {
      # Return empty data.table with proper structure
      if (length(files) > 0 && file.exists(files[1])) {
        shallow.copy <- fread(files[1], nrows = 1)
        empty_dt <- data.table()
        for (col_name in names(shallow.copy)) {
          empty_dt[, (col_name) := character(0)]
        }
        return(empty_dt[])
      } else {
        return(data.table())
      }
    }
    dat <- rbindlist(all_data, fill = TRUE)
  } else {
    # Use grep command for Unix-like systems
    cmd <- build_grep_cmd(pattern = pattern, files = files, options = options_str, fixed = fixed)
    # Set an artificial header of V1, V2, etc.
    dat <- fread(cmd = cmd, header = F)
  }
  
  # Platform-specific post-processing
  if (.Platform$OS.type == "windows") {
    # Windows: Data is already in correct format, just check for empty results
    if (nrow(dat) == 0) {
      # Return empty data.table with proper structure
      if (length(files) > 0 && file.exists(files[1])) {
        shallow.copy <- fread(files[1], nrows = 1)
        empty_dt <- data.table()
        for (col_name in names(shallow.copy)) {
          empty_dt[, (col_name) := character(0)]
        }
        return(empty_dt[])
      } else {
        return(data.table())
      }
    }
    # Windows data is ready to return
    return(dat[])
  } else {
    # Unix: Process grep output
    # Check if no matches were found
    if (nrow(dat) == 0) {
    # Return empty data.table with proper structure
    shallow.copy <- fread(input = files[1], nrows = 1)
    empty_dt <- data.table()
    for (col_name in names(shallow.copy)) {
      empty_dt[, (col_name) := character(0)]
    }
    return(empty_dt[])
  }
  
  shallow.copy <- fread(input = files[1], nrows = 10)
  
  # Handles all names except V1, which is addressed after potentially splitting columns downstream.
  setnames(x = dat, old = names(dat), new = c("V1", names(shallow.copy)[2:ncol(shallow.copy)]), skip_absent = TRUE)
  

  # Split first column if metadata is included.
  if(need_metadata == TRUE){
    
    column.names <- c(c("file", "line_number")[c((include_filename == T | length(files > 1)), show_line_numbers == T)], names(shallow.copy)[1])
    
    additional.columns = split.columns(x = dat[, V1], column.names = column.names, resulting.columns = length(column.names))
    
    dat <- data.table(dat, additional.columns)
    dat[, V1 := NULL]
    setcolorder(x = dat, neworder = names(shallow.copy), skip_absent = T)
    
    if(include_filename == FALSE & "file" %in% names(dat)){
      dat[, file := NULL]
    }
    if(show_line_numbers == FALSE & "line_number" %in% names(dat)){
      dat[, line_number := NULL]
    }
    
  }
  if(need_metadata == FALSE){
    setnames(x = dat, old = "V1", new = names(shallow.copy)[1], skip_absent = TRUE)
  }
  
  header_contains_pattern <- length(grep(pattern = pattern, x = names(dat))) > 0
  

            # Remove header rows
  if(header == TRUE){
    if((pattern == "") | (pattern != "" & header_contains_pattern == TRUE)){
      
      num.files <- length(files)
      
      if(num.files == 1){
        dat <- dat[2:.N,]
      }
      if(num.files > 1){
        counts <- grep_count(files = files, path = path, file_pattern = file_pattern, pattern = pattern, invert = invert, ignore_case = ignore_case, fixed = fixed, recursive = recursive, word_match = word_match, only_matching = only_matching, skip = skip, header = header)
        
        dat <- dat[-c(1, 1 + counts[1:(.N-1), cumsum(1 + count)])]
      }
    }
  }

  if(header == TRUE & "line_number" %in% names(dat)){
    dat[, line_number := as.numeric(line_number) - 1]
  }
   
  # Restore original data types
  
  data.types <- as.data.table(x = t(shallow.copy[, lapply(X = .SD, FUN = "class")]), keep.rownames = TRUE)
  
  unique.types <- data.types[, unique(V1)]
  
  for(i in 1:length(unique.types[unique.types != "character"])){
    dat[, names(.SD) := lapply(X = .SD, FUN = "as", Class = unique.types[i]), .SDcols = data.types[V1 == unique.types[i], rn]]
  }

  dat <- dat[1:min(c(.N, nrows)),]
  
  # return data
  return(dat[])
  } # End of Unix-specific branch
}
