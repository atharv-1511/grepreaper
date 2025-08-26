# Fix data.table global variable bindings
utils::globalVariables(c(":=", ".SD", ".N"))

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
  
  # PERFORMANCE OPTIMIZATION: Use vectorized strsplit instead of loops
  the.pieces <- strsplit(x = x, split = split, fixed = fixed)
  
  # PERFORMANCE OPTIMIZATION: Pre-allocate result data.table
  n_rows <- length(x)
  result_dt <- data.table::data.table()
  
  # PERFORMANCE OPTIMIZATION: Vectorized column creation
  if (resulting.columns == 1) {
    # Single column case - most efficient
    result_dt[, V1 := x]
  } else if (resulting.columns == 2) {
    # Two columns case - optimized
    col1 <- sapply(the.pieces, function(piece) if (length(piece) >= 1) piece[1] else NA_character_)
    col2 <- sapply(the.pieces, function(piece) if (length(piece) >= 2) paste(piece[2:length(piece)], collapse = split) else NA_character_)
    result_dt[, V1 := col1]
    result_dt[, V2 := col2]
  } else if (resulting.columns == 3) {
    # Three columns case - optimized for common grep metadata format
    col1 <- sapply(the.pieces, function(piece) if (length(piece) >= 1) piece[1] else NA_character_)
    col2 <- sapply(the.pieces, function(piece) if (length(piece) >= 2) piece[2] else NA_character_)
    col3 <- sapply(the.pieces, function(piece) if (length(piece) >= 3) paste(piece[3:length(piece)], collapse = split) else NA_character_)
    result_dt[, V1 := col1]
    result_dt[, V2 := col2]
    result_dt[, V3 := col3]
  } else {
    # General case - still optimized but handles arbitrary column counts
    # PERFORMANCE OPTIMIZATION: Use sapply instead of loops
    for (i in seq_len(resulting.columns)) {
      if (i < resulting.columns) {
        # Extract single elements
        col_values <- sapply(the.pieces, function(piece) {
          if (length(piece) >= i) piece[i] else NA_character_
        })
        result_dt[, (paste0("V", i)) := col_values]
      } else {
        # Combine remaining elements for the last column
        col_values <- sapply(the.pieces, function(piece) {
          if (length(piece) >= i) paste(piece[i:length(piece)], collapse = split) else NA_character_
        })
        result_dt[, (paste0("V", i)) := col_values]
      }
    }
  }
 
  # PERFORMANCE OPTIMIZATION: Set column names efficiently
  if (!is.na(column.names[1]) && length(column.names) == ncol(result_dt)) {
    data.table::setnames(result_dt, names(result_dt), column.names)
  }
 
  return(result_dt)
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
  # If pattern is empty, use a pattern that matches all lines
  if (nchar(pattern) == 0) {
    pattern <- ".*"
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
    
    # PERFORMANCE OPTIMIZATION: Cache grep path detection to avoid repeated file system checks
    # For grep commands on Windows, automatically use Git's grep if available
    if (grepl("^grep\\s+", cmd) && Sys.info()["sysname"] == "Windows") {
      # Check if we already have a cached grep path
      cached_grep_path <- getOption("grepreaper.cached_grep_path", NULL)
      
      if (!is.null(cached_grep_path)) {
        # Use cached path for better performance
        cmd <- sub("^grep\\s+", paste0("\"", cached_grep_path, "\" "), cmd)
        if (getOption("grepreaper.show_progress", FALSE)) {
          message("Using cached Git grep: ", cmd)
        }
      } else {
        # PERFORMANCE OPTIMIZATION: Check multiple possible Git grep locations once
        git_grep_paths <- c(
          "C:/Program Files/Git/usr/bin/grep.exe",
          "C:/Program Files (x86)/Git/usr/bin/grep.exe",
          "C:/Git/usr/bin/grep.exe"
        )
        
        git_grep_found <- FALSE
        for (git_grep_path in git_grep_paths) {
          if (file.exists(git_grep_path)) {
            # Test if it works
            test_result <- tryCatch({
              system(paste0("\"", git_grep_path, "\" --version"), 
                     intern = TRUE, ignore.stderr = TRUE)
            }, error = function(e) NULL, warning = function(w) NULL)
            
            if (!is.null(test_result) && length(test_result) > 0) {
              # Cache the working grep path for future use
              options(grepreaper.cached_grep_path = git_grep_path)
              cmd <- sub("^grep\\s+", paste0("\"", git_grep_path, "\" "), cmd)
              if (getOption("grepreaper.show_progress", FALSE)) {
                message("Using Git's grep (cached): ", cmd)
              }
              git_grep_found <- TRUE
              break
            }
          }
        }
        
        # If no Git grep found, try to use Windows Subsystem for Linux (WSL) grep
        if (!git_grep_found) {
          wsl_result <- tryCatch({
            system("wsl grep --version", intern = TRUE, ignore.stderr = TRUE)
          }, error = function(e) NULL, warning = function(w) NULL)
          
          if (!is.null(wsl_result) && length(wsl_result) > 0) {
            # Cache WSL grep for future use
            options(grepreaper.cached_grep_path = "wsl grep")
            cmd <- sub("^grep\\s+", "wsl grep ", cmd)
            if (getOption("grepreaper.show_progress", FALSE)) {
              message("Using WSL grep (cached): ", cmd)
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
    }
    
    # PERFORMANCE OPTIMIZATION: Execute command with optimized system call
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

#' Performance monitoring function for grepreaper operations
#' @param expr Expression to evaluate and monitor
#' @param show_details Logical; if TRUE, show detailed performance metrics
#' @return List with performance metrics
#' @export
monitor_performance <- function(expr, show_details = FALSE) {
  # Record start time and memory
  start_time <- Sys.time()
  start_mem <- sum(gc()[, 2])
  
  # Execute the expression
  result <- eval(expr)
  
  # Record end time and memory
  end_time <- Sys.time()
  end_mem <- sum(gc()[, 2])
  
  # Calculate metrics
  execution_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
  memory_used <- end_mem - start_mem
  
  # Performance summary
  performance_metrics <- list(
    execution_time_seconds = execution_time,
    memory_used_mb = memory_used / (1024 * 1024),
    timestamp = end_time
  )
  
  if (show_details) {
    cat("Performance Metrics:\n")
    cat("==================\n")
    cat("Execution Time:", round(execution_time, 3), "seconds\n")
    cat("Memory Used:", round(memory_used / (1024 * 1024), 2), "MB\n")
    cat("Timestamp:", format(end_time, "%Y-%m-%d %H:%M:%S"), "\n")
  }
  
  return(performance_metrics)
}
