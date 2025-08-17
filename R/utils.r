# String concatenation operator
`%+%` <- function(x, y) {
  paste0(x, y)
}

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
#' @export
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
  
  # Check for grep using various methods
  grep_path <- tryCatch({
    if (sys_info$is_windows) {
      # Try multiple methods on Windows
      paths <- character(0)
      
      # Try Git Bash locations
      git_paths <- c(
        # Standard Git for Windows paths
        "C:/Program Files/Git/usr/bin/grep.exe",
        "C:/Program Files (x86)/Git/usr/bin/grep.exe",
        Sys.getenv("PROGRAMFILES") %+% "/Git/usr/bin/grep.exe",
        Sys.getenv("PROGRAMFILES(X86)") %+% "/Git/usr/bin/grep.exe",
        # MSYS2 paths
        "C:/msys64/usr/bin/grep.exe",
        # User-specific Git paths
        file.path(Sys.getenv("USERPROFILE"), "AppData/Local/Programs/Git/usr/bin/grep.exe"),
        # Scoop paths
        file.path(Sys.getenv("USERPROFILE"), "scoop/apps/git/current/usr/bin/grep.exe")
      )
      
      # Check each Git path
      for (path in git_paths) {
        if (file.exists(path)) {
          paths <- c(paths, path)
          break  # Stop after finding first valid path
        }
      }
      
      # If no direct paths work, try Git Bash
      if (length(paths) == 0) {
        # Try to find Git Bash
        git_bash_paths <- c(
          "C:/Program Files/Git/bin/bash.exe",
          "C:/Program Files (x86)/Git/bin/bash.exe",
          Sys.getenv("PROGRAMFILES") %+% "/Git/bin/bash.exe",
          Sys.getenv("PROGRAMFILES(X86)") %+% "/Git/bin/bash.exe"
        )
        
        for (bash_path in git_bash_paths) {
          if (file.exists(bash_path)) {
            # Try to run grep through Git Bash
            grep_cmd <- sprintf('"%s" -c "which grep"', bash_path)
            tryCatch({
              bash_result <- system(grep_cmd, intern = TRUE, ignore.stderr = TRUE)
              if (length(bash_result) > 0 && nchar(bash_result[1]) > 0) {
                paths <- c(paths, bash_result[1])
                break
              }
            }, error = function(e) NULL)
          }
        }
      }
      
      # If still no paths, try system commands
      if (length(paths) == 0) {
        # Try where command
        tryCatch({
          where_result <- system("where grep 2>NUL", intern = TRUE, ignore.stderr = TRUE)
          if (length(where_result) > 0) {
            paths <- c(paths, where_result[1])
          }
        }, error = function(e) NULL)
        
        # Try git exec-path
        if (length(paths) == 0) {
          tryCatch({
            git_exec <- system("git --exec-path", intern = TRUE, ignore.stderr = TRUE)
            if (length(git_exec) > 0) {
              grep_exe <- file.path(git_exec[1], "grep.exe")
              if (file.exists(grep_exe)) {
                paths <- c(paths, grep_exe)
              }
            }
          }, error = function(e) NULL)
        }
      }
      
      # Return first valid path
      if (length(paths) > 0) paths[1] else NULL
    } else {
      # On Unix-like systems, try which and type
      paths <- c(
        tryCatch(system("which grep", intern = TRUE, ignore.stderr = TRUE), error = function(e) character(0)),
        tryCatch(system("type -p grep", intern = TRUE, ignore.stderr = TRUE), error = function(e) character(0))
      )
      # Filter out empty results and take the first valid path
      paths <- paths[paths != ""]
      if (length(paths) > 0) paths[1] else NULL
    }
  }, error = function(e) NULL)
  
  if (!is.null(grep_path)) {
    result$path <- grep_path
  }
  
  # Try to get grep version using the found path
  if (!is.null(grep_path)) {
    version_cmds <- c(
      sprintf('"%s" --version', grep_path),
      sprintf('"%s" -V', grep_path)
    )
    
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
  
  # Handle pattern escaping based on whether -F (fixed) is in options
  if (grepl("-F", options, fixed = TRUE)) {
    # For fixed string matching, escape special regex characters
    escaped_pattern <- shQuote(pattern)
  } else {
    # For regex matching, escape the pattern properly for shell
    # but don't escape regex metacharacters
    escaped_pattern <- shQuote(pattern)
  }
  
  file_paths <- paste(shQuote(files), collapse = " ")
  
  # Build and return command
  cmd <- sprintf("grep %s %s %s", options, escaped_pattern, file_paths)
  # Remove extra space if options is empty
  cmd <- gsub("grep  ", "grep ", cmd, fixed = TRUE)
  return(cmd)
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
