#' @export
split.columns <- function(x, column.names = NA, split = ":", resulting.columns = 3, fixed = TRUE) {
  require(data.table)
 
  # Input validation
  if (!is.character(x) || length(x) == 0) {
    stop("'x' must be a non-empty character vector")
  }
  if (!is.numeric(resulting.columns) || resulting.columns < 1) {
    stop("'resulting.columns' must be a positive integer")
  }
  
  the.pieces <- strsplit(x = x, split = split, fixed = fixed)
 
  # Create empty data.table with the right number of rows
  new.columns <- data.table(row_id = seq_along(x))
  
  # Add each column one by one to ensure character types
  for(i in 1:resulting.columns) {
    if(i < resulting.columns) {
      # Extract single elements
      col_values <- character(length(the.pieces))
      for(j in seq_along(the.pieces)) {
        if (length(the.pieces[[j]]) >= i) {
          col_values[j] <- the.pieces[[j]][i]
        } else {
          col_values[j] <- NA_character_
        }
      }
      new.columns[, (sprintf("V%s", i)) := col_values]
    } else {
      # Combine remaining elements for the last column
      col_values <- character(length(the.pieces))
      for(j in seq_along(the.pieces)) {
        if (length(the.pieces[[j]]) >= i) {
          col_values[j] <- paste(the.pieces[[j]][i:length(the.pieces[[j]])], collapse = ":")
        } else {
          col_values[j] <- NA_character_
        }
      }
      new.columns[, (sprintf("V%s", i)) := col_values]
    }
  }
  
  # Remove the temporary row_id column
  new.columns[, row_id := NULL]
 
  if(!is.na(column.names[1])) {
    setnames(x = new.columns, old = names(new.columns), new = column.names)
  }
 
  return(new.columns)
}

#' Check if grep is available on the system
#' @return A list with 'available' logical indicating if grep is available
#' @export
check_grep_availability <- function() {
  available <- FALSE
  tryCatch({
    result <- system("grep --version", intern = TRUE, ignore.stderr = TRUE)
    available <- length(result) > 0
  }, error = function(e) {
    available <- FALSE
  }, warning = function(w) {
    available <- FALSE
  })
  
  return(list(available = available))
}

#' Build grep command string
#' @param pattern Pattern to search for
#' @param files Files to search in
#' @param options Options string for grep
#' @return Command string
#' @export
build_grep_cmd <- function(pattern, files, options = "") {
  # Input validation
  if (!is.character(pattern) || length(pattern) != 1 || nchar(pattern) == 0) {
    stop("'pattern' must be a non-empty character string")
  }
  if (!is.character(files) || length(files) == 0) {
    stop("'files' must be a non-empty character vector")
  }
  if (!is.character(options)) {
    stop("'options' must be a character string")
  }
  
  # Sanitize inputs to prevent command injection
  pattern <- gsub("[\"`$\\\\]", "\\\\&", pattern)  # Escape dangerous characters
  files <- normalizePath(files, mustWork = FALSE)  # Normalize file paths
  
  # Build command with proper spacing
  if (nchar(options) > 0) {
    cmd <- sprintf("grep %s %s %s", options, shQuote(pattern), paste(shQuote(files), collapse = " "))
  } else {
    cmd <- sprintf("grep %s %s", shQuote(pattern), paste(shQuote(files), collapse = " "))
  }
  
  return(cmd)
}

#' Safe system call that handles errors gracefully
#' @param cmd Command to execute
#' @param timeout Timeout in seconds (default: 60)
#' @return Result of system call or empty character vector on error
#' @export
safe_system_call <- function(cmd, timeout = 60) {
  tryCatch({
    # Use timeout to prevent hanging
    result <- system(cmd, intern = TRUE, ignore.stderr = TRUE, timeout = timeout)
    return(result)
  }, error = function(e) {
    return(character(0))
  }, warning = function(w) {
    return(character(0))
  })
}

#' Get system information
#' @return List with system information
#' @export
get_system_info <- function() {
  info <- list(
    os = Sys.info()["sysname"],
    release = Sys.info()["release"],
    machine = Sys.info()["machine"],
    grep_available = check_grep_availability()$available
  )
  return(info)
}

#' Check if a file is binary
#' @param file_path Path to the file to check
#' @return Logical indicating if the file appears to be binary
#' @export
is_binary_file <- function(file_path) {
  tryCatch({
    # Read first 1024 bytes to check for null bytes
    con <- file(file_path, "rb")
    on.exit(close(con))
    bytes <- readBin(con, "raw", n = 1024)
    
    # Check for null bytes (common in binary files)
    has_nulls <- any(bytes == 0)
    
    # Check for high-ASCII characters (common in binary files)
    high_ascii <- any(bytes > 127)
    
    # Simple heuristic: if more than 10% are nulls or high-ASCII, likely binary
    return(has_nulls || (sum(high_ascii) / length(bytes) > 0.1))
  }, error = function(e) {
    return(FALSE)  # Assume text if we can't read
  })
}
