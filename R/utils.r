# Fix data.table global variable bindings
utils::globalVariables(c(":=", ".SD", ".N", ".SDcols"))

#' Split columns based on a delimiter
#' @param x Character vector to split
#' @param column.names Names for the resulting columns
#' @param split Delimiter to split on
#' @param resulting.columns Number of columns to create
#' @param fixed Whether to use fixed string matching
#' @return data.table with split columns
#' @export
split.columns <- function(x, column.names = NA, split = ":", 
                         resulting.columns = 3, fixed = TRUE) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("The 'data.table' package is required but not installed.")
  }
 
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
  for (i in 1:resulting.columns) {
    if (i < resulting.columns) {
      # Extract single elements
      col_values <- character(length(the.pieces))
      for (j in seq_along(the.pieces)) {
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
      for (j in seq_along(the.pieces)) {
        if (length(the.pieces[[j]]) >= i) {
          col_values[j] <- paste(the.pieces[[j]][i:length(the.pieces[[j]])], 
                                collapse = ":")
        } else {
          col_values[j] <- NA_character_
        }
      }
      new.columns[, (sprintf("V%s", i)) := col_values]
    }
  }
  
  # Remove the temporary row_id column
  new.columns[, row_id := NULL]
 
  if (!is.na(column.names[1])) {
    setnames(x = new.columns, old = names(new.columns), new = column.names)
  }
 
  return(new.columns)
}

#' Check if grep is available on the system
#' @return A list with 'available' logical indicating if grep is available
#' @export
check_grep_availability <- function() {
  available <- FALSE
  grep_path <- NULL
  
  tryCatch({
    # On Windows, check for Git's grep first
    if (Sys.info()["sysname"] == "Windows") {
      git_grep_paths <- c(
        "C:/Program Files/Git/usr/bin/grep.exe",
        "C:/Program Files (x86)/Git/usr/bin/grep.exe",
        "C:/Git/usr/bin/grep.exe"
      )
      
      for (git_grep_path in git_grep_paths) {
        if (file.exists(git_grep_path)) {
          # Test if it works
          result <- system(paste0("\"", git_grep_path, "\" --version"), 
                          intern = TRUE, ignore.stderr = TRUE)
          if (length(result) > 0) {
            available <- TRUE
            grep_path <- git_grep_path
            break
          }
        }
      }
      
      # If no Git grep, try WSL
      if (!available) {
        wsl_result <- tryCatch({
          system("wsl grep --version", intern = TRUE, ignore.stderr = TRUE)
        }, error = function(e) NULL, warning = function(w) NULL)
        
        if (!is.null(wsl_result) && length(wsl_result) > 0) {
          available <- TRUE
          grep_path <- "wsl grep"
        }
      }
    } else {
      # On Unix-like systems, use standard grep
      result <- system("grep --version", intern = TRUE, ignore.stderr = TRUE)
      available <- length(result) > 0
      if (available) {
        grep_path <- "grep"
      }
    }
  }, error = function(e) {
    available <- FALSE
  }, warning = function(w) {
    available <- FALSE
  })
  
  return(list(available = available, path = grep_path))
}

#' Build grep command string
#' @param pattern Pattern to search for
#' @param files Files to search in
#' @param options Options string for grep
#' @return Command string
#' @export
build_grep_cmd <- function(pattern, files, options = "") {
  # Input validation
  if (!is.character(pattern) || length(pattern) != 1) {
    stop("'pattern' must be a single character string")
  }
  if (!is.character(files) || length(files) == 0) {
    stop("'files' must be a non-empty character vector")
  }
  if (!is.character(options)) {
    stop("'options' must be a character string")
  }
  
  # Sanitize inputs to prevent command injection
  pattern <- gsub("[\"`$\\\\]", "\\\\&", pattern)  # Escape dangerous characters
  
  # Handle file paths more carefully to avoid hidden file issues
  files <- sapply(files, function(file) {
    # Use absolute paths but avoid resolving symlinks
    if (file.exists(file)) {
      file.path(getwd(), file)
    } else {
      file
    }
  })
  
  # Build command with proper spacing
  # If pattern is empty, return a special indicator
  if (nchar(pattern) == 0) {
    return("EMPTY_PATTERN")
  }
  
  if (nchar(options) > 0) {
    cmd <- sprintf("grep %s %s %s", options, shQuote(pattern), paste(shQuote(files), collapse = " "))
  } else {
    cmd <- sprintf("grep %s %s", shQuote(pattern), paste(shQuote(files), collapse = " "))
  }
  
  return(cmd)
}

#' Safe system call that handles errors gracefully
#' @param cmd Command to execute
#' @param timeout Timeout in seconds (default: 60) - Note: not used in Windows
#' @return Result of system call or empty character vector on error
#' @export
safe_system_call <- function(cmd, timeout = 60) {
  tryCatch({
    # On Windows, system() doesn't support timeout parameter
    # Use intern = TRUE to capture output, ignore.stderr = TRUE to suppress errors
    
    # For grep commands on Windows, automatically use Git's grep if available
    if (grepl("^grep\\s+", cmd) && Sys.info()["sysname"] == "Windows") {
      # Check multiple possible Git grep locations
      git_grep_paths <- c(
        "C:/Program Files/Git/usr/bin/grep.exe",
        "C:/Program Files (x86)/Git/usr/bin/grep.exe",
        "C:/Git/usr/bin/grep.exe"
      )
      
      git_grep_found <- FALSE
      for (git_grep_path in git_grep_paths) {
        if (file.exists(git_grep_path)) {
          # Replace grep with full path
          cmd <- sub("^grep\\s+", paste0("\"", git_grep_path, "\" "), cmd)
          if (getOption("grepreaper.show_progress", FALSE)) {
            message("Using Git's grep: ", cmd)
          }
          git_grep_found <- TRUE
          break
        }
      }
      
      # If no Git grep found, try to use Windows Subsystem for Linux (WSL) grep
      if (!git_grep_found) {
        wsl_result <- tryCatch({
          system("wsl grep --version", intern = TRUE, ignore.stderr = TRUE)
        }, error = function(e) NULL, warning = function(w) NULL)
        
        if (!is.null(wsl_result) && length(wsl_result) > 0) {
          cmd <- sub("^grep\\s+", "wsl grep ", cmd)
          if (getOption("grepreaper.show_progress", FALSE)) {
            message("Using WSL grep: ", cmd)
          }
          git_grep_found <- TRUE
        }
      }
      
      # If still no grep found, return empty result with warning
      if (!git_grep_found) {
        warning("No grep command available on Windows. Please install Git for Windows or WSL.")
        return(character(0))
      }
    }
    
    result <- system(cmd, intern = TRUE, ignore.stderr = TRUE)
    
    # Check if the command executed successfully
    if (attr(result, "status") == 0 || is.null(attr(result, "status"))) {
      return(result)
    } else {
      # Command failed, return empty result
      if (getOption("grepreaper.show_progress", FALSE)) {
        message("Command failed with status: ", attr(result, "status"))
      }
      return(character(0))
    }
  }, error = function(e) {
    # Log the error
    if (getOption("grepreaper.show_progress", FALSE)) {
      message("safe_system_call error: ", e$message)
    }
    return(character(0))
  }, warning = function(w) {
    # Log the warning
    if (getOption("grepreaper.show_progress", FALSE)) {
      message("safe_system_call warning: ", w$message)
    }
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
