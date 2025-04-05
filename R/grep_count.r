#' Count occurrences matching a pattern in one or more files
#' 
#' This function counts the number of lines in one or more files that match a given pattern.
#' It leverages the command-line grep utility for efficient pattern matching.
#' 
#' @param files Character vector of file paths.
#' @param pattern Pattern to search for.
#' @param invert Logical; if TRUE, count non-matching lines.
#' @param ignore_case Logical; if TRUE, perform case-insensitive matching.
#' @param fixed Logical; if TRUE, pattern is a fixed string, not a regular expression.
#' @param show_cmd Logical; if TRUE, print the grep command used.
#' @param recursive Logical; if TRUE, search recursively through directories.
#' @param word_match Logical; if TRUE, match only whole words.
#' 
#' @return Integer count of matching lines (or command string if show_cmd=TRUE).
#' 
#' @examples
#' \dontrun{
#' # Count occurrences of "IT" in sample_data.csv
#' grep_count("data/sample_data.csv", "IT")
#' 
#' # Count non-matching lines (those not containing "IT")
#' grep_count("data/sample_data.csv", "IT", invert = TRUE)
#' 
#' # Search in multiple files
#' grep_count(c("data/file1.csv", "data/file2.csv"), "pattern")
#' }
#' 
#' @export
grep_count <- function(files, pattern, invert = FALSE, ignore_case = FALSE, 
                      fixed = FALSE, show_cmd = FALSE, recursive = FALSE,
                      word_match = FALSE) {
  
  # Input validation
  if (!is.character(files) || length(files) == 0) {
    stop("'files' must be a non-empty character vector")
  }
  if (!is.character(pattern) || length(pattern) != 1) {
    stop("'pattern' must be a single character string")
  }
  
  # Build grep options
  options <- ""
  if (invert) options <- paste(options, "-v")
  if (ignore_case) options <- paste(options, "-i")
  if (fixed) options <- paste(options, "-F")
  if (recursive) options <- paste(options, "-r")
  if (word_match) options <- paste(options, "-w")
  
  # Build the command
  cmd <- build_grep_cmd(pattern, files, options, count = TRUE)
  
  # Return command if requested
  if (show_cmd) {
    return(cmd)
  }
  
  # Execute command and process results
  result <- safe_system_call(cmd)
  
  # Process results based on number of input files
  if (length(files) == 1) {
    # Single file case - return a single number
    as.integer(ifelse(length(result) == 0, 0, result))
  } else {
    # Multiple files case - return a named vector
    # Parse result of format "filename:count"
    if (length(result) == 0) {
      return(setNames(rep(0, length(files)), files))
    }
    
    counts <- sapply(result, function(line) {
      parts <- strsplit(line, ":", fixed = TRUE)[[1]]
      if (length(parts) >= 2) {
        file_name <- parts[1]
        count <- as.integer(parts[2])
        return(c(file_name, count))
      } else {
        # For files with no matches
        return(c("unknown", 0))
      }
    })
    
    if (is.list(counts)) {
      # Handle result formatting
      count_vector <- as.integer(unlist(counts[2,]))
      names(count_vector) <- unlist(counts[1,])
      return(count_vector)
    } else {
      # In case we have a matrix
      count_vector <- as.integer(counts[2,])
      names(count_vector) <- counts[1,]
      return(count_vector)
    }
  }
}
