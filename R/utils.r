#' Check if grep is available in the system
#' 
#' This function checks if the grep command is available in the system.
#' It performs platform-specific checks and provides detailed error messages.
#' 
#' @return A list with the following components:
#' \itemize{
#'   \item available: Logical indicating if grep is available
#'   \item version: Character string with grep version (if available)
#'   \item path: Character string with path to grep executable (if found)
#'   \item error: Character string with error message (if any)
#' }
#' 
#' @keywords internal
check_grep_availability <- function() {
  # Get system information
  sys_info <- get_system_info()
  
  # Initialize result
  result <- list(
    available = FALSE,
    version = NULL,
    path = NULL,
    error = NULL
  )
  
  # Check for grep using which/where
  grep_path <- tryCatch({
    if (sys_info$is_windows) {
      # Try multiple methods on Windows
      paths <- c(
        system("where grep", intern = TRUE, ignore.stderr = TRUE),
        system("where.exe grep", intern = TRUE, ignore.stderr = TRUE),
        system("git --exec-path", intern = TRUE, ignore.stderr = TRUE)
      )
      # Filter out empty results and take the first valid path
      paths <- paths[paths != ""]
      if (length(paths) > 0) paths[1] else NULL
    } else {
      # On Unix-like systems, try which and type
      paths <- c(
        system("which grep", intern = TRUE, ignore.stderr = TRUE),
        system("type -p grep", intern = TRUE, ignore.stderr = TRUE)
      )
      # Filter out empty results and take the first valid path
      paths <- paths[paths != ""]
      if (length(paths) > 0) paths[1] else NULL
    }
  }, error = function(e) NULL)
  
  if (!is.null(grep_path)) {
    result$path <- grep_path
  }
  
  # Try to get grep version with different commands
  version_cmds <- if (sys_info$is_windows) {
    c("grep --version", "grep -V")
  } else {
    c("grep --version 2>&1", "grep -V 2>&1")
  }
  
  for (cmd in version_cmds) {
    tryCatch({
      version_output <- system(cmd, intern = TRUE, ignore.stderr = TRUE)
      if (length(version_output) > 0) {
        result$version <- version_output[1]
        result$available <- TRUE
        break
      }
    }, error = function(e) {
      # Continue to next command if this one fails
    }, warning = function(w) {
      # Continue to next command if this one fails
    })
  }
  
  # If grep is not available, provide platform-specific guidance
  if (!result$available) {
    if (sys_info$is_windows) {
      result$error <- paste(
        "grep not found. On Windows, you can install grep through:",
        "1. Git Bash (recommended): Install Git for Windows",
        "2. MSYS2: Install MSYS2 and run 'pacman -S grep'",
        "3. WSL: Install Windows Subsystem for Linux",
        "",
        "Note: If you have Git for Windows installed, make sure it's in your PATH.",
        sep = "\n"
      )
    } else if (sys_info$os_name == "Darwin") {  # MacOS
      result$error <- paste(
        "grep not found. On MacOS, grep should be available by default.",
        "If it's missing, you can install it through:",
        "1. Homebrew: 'brew install grep'",
        "2. MacPorts: 'sudo port install grep'",
        "",
        "Note: If you've installed grep through Homebrew, you might need to:",
        "1. Add Homebrew's bin directory to your PATH",
        "2. Use the full path: /usr/local/bin/grep or /opt/homebrew/bin/grep",
        sep = "\n"
      )
    } else {  # Linux and other Unix-like systems
      result$error <- paste(
        "grep not found. On Unix-like systems, install grep using your package manager:",
        "1. Debian/Ubuntu: 'sudo apt-get install grep'",
        "2. RHEL/CentOS: 'sudo yum install grep'",
        "3. Arch Linux: 'sudo pacman -S grep'",
        "",
        "Note: If grep is installed but not found, check your PATH environment variable.",
        sep = "\n"
      )
    }
  }
  
  return(result)
}

#' Build a grep command with proper escaping and options
#' 
#' This function builds a grep command with proper escaping and options
#' based on the provided parameters.
#' 
#' @param pattern Pattern to search for.
#' @param files Character vector of file paths.
#' @param options Character string of grep options.
#' @param count Logical; if TRUE, add the -c option to count matches.
#' 
#' @return A character string with the grep command.
#' 
#' @keywords internal
build_grep_cmd <- function(pattern, files, options = "", count = FALSE) {
  # Check if grep is available
  grep_check <- check_grep_availability()
  if (!grep_check$available) {
    stop("The 'grep' command is not available on this system.\n",
         grep_check$error)
  }
  
  # Add count option if requested
  if (count) options <- paste(options, "-c")
  
  # Escape pattern for shell
  escaped_pattern <- gsub("'", "'\\\\''", pattern)
  
  # Properly quote file paths
  file_paths <- paste(shQuote(files), collapse = " ")
  
  # Build and return command
  sprintf("grep %s '%s' %s", options, escaped_pattern, file_paths)
}

#' Execute a shell command safely
#' 
#' This function executes a shell command and handles errors gracefully.
#' 
#' @param cmd Command to execute.
#' @param intern Logical; if TRUE, capture the output.
#' 
#' @return Command output as character vector, or empty vector on error.
#' 
#' @keywords internal
safe_system_call <- function(cmd, intern = TRUE) {
  tryCatch({
    system(cmd, intern = intern)
  }, error = function(e) {
    # Grep returns exit code 1 if no matches found, which is not an error for us
    character(0)
  }, warning = function(w) {
    # Handle warnings
    character(0)
  })
}

#' Get platform-specific system information
#' 
#' This function returns information about the system, including OS type.
#' 
#' @return A list with system information.
#' 
#' @keywords internal
get_system_info <- function() {
  os_type <- .Platform$OS.type
  os_name <- Sys.info()["sysname"]
  
  # Return system information
  list(
    os_type = os_type,
    os_name = os_name,
    is_windows = os_type == "windows",
    is_unix = os_type == "unix"
  )
}
