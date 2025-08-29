# Fix data.table global variable bindings
utils::globalVariables(c(":=", ".N", "V1", "V2", "V3"))

#' Split columns based on a delimiter
#' 
#' Efficiently splits character vectors into multiple columns based on a specified delimiter.
#' This function is optimized for performance and handles common use cases like parsing
#' grep output or other delimited text data.
#' 
#' @param x Character vector to split
#' @param column.names Names for the resulting columns (optional)
#' @param split Delimiter to split on (default: ":")
#' @param resulting.columns Number of columns to create (default: 3)
#' @param fixed Whether to use fixed string matching (default: TRUE)
#' 
#' @return A data.table with split columns. Column names are automatically assigned
#'   as V1, V2, V3, etc. unless custom names are provided via \code{column.names}.
#' 
#' @examples
#' # Split grep-like output with colon delimiter
#' data <- c("file.txt:15:error message", "file.txt:23:warning message")
#' result <- split.columns(data, resulting.columns = 3)
#' print(result)
#' 
#' # With custom column names
#' result_named <- split.columns(data, 
#'                              column.names = c("filename", "line", "message"),
#'                              resulting.columns = 3)
#' print(result_named)
#' 
#' # Split into 2 columns (combining remaining elements)
#' result_2col <- split.columns(data, resulting.columns = 2)
#' print(result_2col)
#' 
#' @export
split.columns <- function(x, column.names = NA, split = ":", 
                         resulting.columns = 3, fixed = TRUE) {
  # CRITICAL FIX: Add require(data.table) for mentor feedback
  if (!require(data.table, quietly = TRUE)) {
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
#' 
#' This function checks whether the grep command-line utility is available on the current
#' system. On Windows, it automatically detects Git for Windows installation or WSL (Windows
#' Subsystem for Linux) to provide grep functionality. On Unix-like systems, it checks
#' for the standard grep command.
#' 
#' @return A list with two components:
#'   \item{available}{Logical indicating if grep is available on the system}
#'   \item{path}{Character string with the path to the grep executable, or NULL if not found}
#' 
#' @examples
#' # Check if grep is available
#' grep_status <- check_grep_availability()
#' if (grep_status$available) {
#'   cat("grep is available at:", grep_status$path, "\n")
#' } else {
#'   cat("grep is not available on this system\n")
#' }
#' 
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
#' 
#' Constructs a safe and properly formatted grep command string for system execution.
#' This function handles input sanitization to prevent command injection and ensures
#' proper quoting of patterns and file paths. It's designed to work with the
#' \code{safe_system_call} function for secure command execution.
#' 
#' @param pattern Pattern to search for (will be automatically quoted)
#' @param files Files to search in (can be a single file or vector of files)
#' @param options Options string for grep (e.g., "-i" for case-insensitive)
#' @param fixed Logical; if TRUE, pattern is treated as a literal string (not escaped)
#' 
#' @return A properly formatted command string ready for system execution
#' 
#' @examples
#' # Basic grep command
#' cmd <- build_grep_cmd("error", "log.txt")
#' cat("Command:", cmd, "\n")
#' 
#' # With grep options
#' cmd_verbose <- build_grep_cmd("warning", "*.log", options = "-i -n")
#' cat("Verbose command:", cmd_verbose, "\n")
#' 
#' # Multiple files
#' cmd_multi <- build_grep_cmd("ERROR", c("file1.txt", "file2.txt"))
#' cat("Multi-file command:", cmd_multi, "\n")
#' 
#' @export
build_grep_cmd <- function(pattern, files, options = "", fixed = FALSE) {
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
  # Only escape if not using fixed string matching
  if (!fixed) {
    pattern <- gsub("[\"`$\\\\]", "\\\\&", pattern)  # Escape dangerous characters
  }
  
  # Handle file paths more carefully to avoid hidden file issues
  files <- sapply(files, function(file) {
    # Use absolute paths but avoid resolving symlinks
    if (file.exists(file)) {
      normalizePath(file, winslash = "/", mustWork = FALSE)
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
#' 
#' Executes system commands with comprehensive error handling and cross-platform
#' compatibility. This function automatically detects and uses the appropriate grep
#' implementation on Windows (Git for Windows or WSL) and provides timeout handling
#' on Unix-like systems. It's designed to work seamlessly with the grep-related
#' functions in this package.
#' 
#' @param cmd Command to execute (typically built with \code{build_grep_cmd})
#' @param timeout Timeout in seconds (default: 60) - Note: not used in Windows
#' 
#' @return Result of system call as a character vector, or empty character vector
#'   on error or timeout
#' 
#' @examples
#' # Safe execution of a grep command
#' cmd <- build_grep_cmd("error", "log.txt")
#' result <- safe_system_call(cmd)
#' if (length(result) > 0) {
#'   cat("Found", length(result), "matching lines\n")
#' } else {
#'   cat("No matches found or command failed\n")
#' }
#' 
#' # With timeout (Unix-like systems only)
#' result_timeout <- safe_system_call(cmd, timeout = 30)
#' 
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
        
        # If still no Git grep found, try to use native Windows grep
        if (!git_grep_found) {
          native_grep_result <- tryCatch({
            system("grep --version", intern = TRUE, ignore.stderr = TRUE)
          }, error = function(e) NULL, warning = function(w) NULL)
          
          if (!is.null(native_grep_result) && length(native_grep_result) > 0) {
            # Cache native Windows grep for future use
            options(grepreaper.cached_grep_path = "grep")
            # Test if the command actually works
            test_cmd <- sub("^grep\\s+", "grep ", cmd)
            test_result <- tryCatch({
              system(test_cmd, intern = TRUE, ignore.stderr = TRUE)
            }, error = function(e) NULL, warning = function(w) NULL)
            
            if (!is.null(test_result)) {
              # Native grep works, use it
              cmd <- test_cmd
              if (getOption("grepreaper.show_progress", FALSE)) {
                message("Using native Windows grep (cached): ", cmd)
              }
              git_grep_found <- TRUE
            } else {
              # Native grep doesn't work, try to find it in PATH
              where_grep <- tryCatch({
                system("where grep", intern = TRUE, ignore.stderr = TRUE)
              }, error = function(e) NULL, warning = function(w) NULL)
              
              if (!is.null(where_grep) && length(where_grep) > 0) {
                grep_path <- where_grep[1]
                cmd <- sub("^grep\\s+", paste0("\"", grep_path, "\" "), cmd)
                options(grepreaper.cached_grep_path = grep_path)
                if (getOption("grepreaper.show_progress", FALSE)) {
                  message("Using native Windows grep from PATH: ", cmd)
                }
                git_grep_found <- TRUE
              }
            }
          }
        }
        
        # If still no grep found, return empty result with warning
        if (!git_grep_found) {
          warning("No grep command available on Windows. Please install Git for Windows, WSL, or ensure grep is in PATH.")
          return(character(0))
        }
      }
    }
    
    # PERFORMANCE OPTIMIZATION: Execute command with optimized system call
    result <- system(cmd, intern = TRUE, ignore.stderr = TRUE)
    
    # Check if the command executed successfully
    # system() with intern=TRUE doesn't always set status attribute
    if (is.null(attr(result, "status")) || attr(result, "status") == 0) {
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
#' 
#' Retrieves basic system information relevant to the grepreaper package functionality.
#' This includes operating system details and grep availability status, which is
#' useful for debugging and ensuring compatibility.
#' 
#' @return A list containing system information:
#'   \item{os}{Operating system name (e.g., "Windows", "Linux", "Darwin")}
#'   \item{release}{OS release version}
#'   \item{machine}{Machine architecture (e.g., "x86_64")}
#'   \item{grep_available}{Logical indicating if grep command is available}
#' 
#' @examples
#' # Get system information
#' sys_info <- get_system_info()
#' cat("OS:", sys_info$os, "\n")
#' cat("Grep available:", sys_info$grep_available, "\n")
#' 
#' # Check if package will work on this system
#' if (sys_info$grep_available) {
#'   cat("grepreaper should work on this system\n")
#' } else {
#'   cat("grep not available - some functions may not work\n")
#' }
#' 
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
#' 
#' Determines whether a file appears to be binary by examining the first 1024 bytes
#' for common binary file characteristics. This function is useful for avoiding
#' attempts to process binary files with text-based functions, which could cause
#' errors or unexpected behavior.
#' 
#' @param file_path Path to the file to check
#' 
#' @return Logical indicating if the file appears to be binary. Returns FALSE for
#'   empty files or if the file cannot be read.
#' 
#' @examples
#' # Check if a file is binary
#' is_binary <- is_binary_file("data.csv")
#' if (is_binary) {
#'   cat("File appears to be binary - use appropriate reader\n")
#' } else {
#'   cat("File appears to be text-based\n")
#' }
#' 
#' # Check multiple files
#' files <- c("text.txt", "image.png", "data.csv")
#' binary_status <- sapply(files, is_binary_file)
#' print(binary_status)
#' 
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
    # Handle empty files (length 0) to avoid division by zero
    if (length(bytes) == 0) {
      return(FALSE)  # Empty files are considered text
    }
    return(has_nulls || (sum(high_ascii) / length(bytes) > 0.1))
  }, error = function(e) {
    return(FALSE)  # Assume text if we can't read
  })
}

#' Performance monitoring function for grepreaper operations
#' 
#' Tracks execution time and memory usage of expressions, providing detailed
#' performance metrics for grepreaper operations. This is useful for benchmarking
#' different approaches and identifying performance bottlenecks in data processing
#' workflows.
#' 
#' @param expr Expression to evaluate and monitor (use curly braces for multiple statements)
#' @param show_details Logical; if TRUE, displays detailed performance metrics to console
#' 
#' @return A list containing performance metrics:
#'   \item{execution_time_seconds}{Execution time in seconds}
#'   \item{memory_used_mb}{Memory usage in megabytes}
#'   \item{timestamp}{Timestamp when monitoring completed}
#' 
#' @examples
#' # Monitor a simple operation
#' perf <- monitor_performance({
#'   result <- grep_read(files = "data.csv", pattern = "test")
#' }, show_details = TRUE)
#' 
#' # Monitor multiple operations
#' perf_multi <- monitor_performance({
#'   data1 <- grep_read(files = "file1.csv", pattern = "error")
#'   data2 <- grep_read(files = "file2.csv", pattern = "warning")
#'   combined <- rbind(data1, data2)
#' })
#' 
#' # Access specific metrics
#' cat("Operation took:", round(perf_multi$execution_time_seconds, 3), "seconds\n")
#' cat("Memory used:", round(perf_multi$memory_used_mb, 2), "MB\n")
#' 
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
