#' Check if grep is available in the system
#' 
#' This function checks if the grep command is available in the system.
#' 
#' @return Logical value: TRUE if grep is available, FALSE otherwise.
#' 
#' @keywords internal
check_grep_availability <- function() {
  tryCatch({
    system("grep --version", intern = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE)
    return(TRUE)
  }, error = function(e) {
    return(FALSE)
  }, warning = function(w) {
    return(FALSE)
  })
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
  if (!check_grep_availability()) {
    stop("The 'grep' command is not available on this system. ",
         "Please install grep or ensure it's in your PATH.")
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
    is_unix = os_type == "unix",
    has_grep = check_grep_availability()
  )
}
