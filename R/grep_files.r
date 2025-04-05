#' Find files containing pattern matches
#' 
#' This function identifies which files contain lines that match the given pattern.
#' It returns only file names rather than the actual matching content.
#' 
#' @param files Character vector of file paths.
#' @param pattern Pattern to search for.
#' @param invert Logical; if TRUE, find files that don't contain the pattern.
#' @param ignore_case Logical; if TRUE, perform case-insensitive matching.
#' @param fixed Logical; if TRUE, pattern is a fixed string, not a regular expression.
#' @param show_cmd Logical; if TRUE, print the grep command used.
#' @param recursive Logical; if TRUE, search recursively through directories.
#' @param word_match Logical; if TRUE, match only whole words.
#' @param one_per_file Logical; if TRUE, return only the first match per file.
#' 
#' @return Character vector of file paths containing matches, with match count as attribute.
#' 
#' @examples
#' \dontrun{
#' # Find files containing "IT"
#' it_files <- grep_files(c("data/file1.csv", "data/file2.csv"), "IT")
#' 
#' # Find files that don't contain "IT"
#' non_it_files <- grep_files(c("data/file1.csv", "data/file2.csv"), "IT", invert = TRUE)
#' 
#' # Get the match counts
#' match_counts <- attr(it_files, "counts")
#' }
#' 
#' @export
grep_files <- function(files, pattern, invert = FALSE, ignore_case = FALSE, 
                       fixed = FALSE, show_cmd = FALSE, recursive = FALSE,
                       word_match = FALSE, one_per_file = FALSE) {
  
  # Input validation
  if (!is.character(files) || length(files) == 0) {
    stop("'files' must be a non-empty character vector")
  }
  if (!is.character(pattern) || length(pattern) != 1) {
    stop("'pattern' must be a single character string")
  }
  
  # Build grep options
  options <- "-l" # List matching files only
  if (invert) options <- paste(options, "-v")
  if (ignore_case) options <- paste(options, "-i")
  if (fixed) options <- paste(options, "-F")
  if (recursive) options <- paste(options, "-r")
  if (word_match) options <- paste(options, "-w")
  
  # Build the command
  cmd <- build_grep_cmd(pattern, files, options)
  
  # To get counts as well, build a second command for counting
  count_cmd <- build_grep_cmd(pattern, files, gsub("-l", "", options), count = TRUE)
  
  # Return command if requested
  if (show_cmd) {
    return(list(files_cmd = cmd, count_cmd = count_cmd))
  }
  
  # Execute grep command
  matching_files <- safe_system_call(cmd)
  
  # If we got no matches, return empty vector
  if (length(matching_files) == 0) {
    return(character(0))
  }
  
  # Get counts for each file (optional)
  if (!one_per_file) {
    # Execute count command to get counts for each file
    count_results <- safe_system_call(count_cmd)
    
    # Parse count results to create a named vector
    if (length(count_results) > 0) {
      counts <- sapply(count_results, function(line) {
        parts <- strsplit(line, ":", fixed = TRUE)[[1]]
        if (length(parts) >= 2) {
          file_name <- parts[1]
          count <- as.integer(parts[2])
          c(file_name, count)
        } else {
          c("unknown", 0)
        }
      })
      
      if (is.list(counts)) {
        count_vector <- as.integer(unlist(counts[2,]))
        names(count_vector) <- unlist(counts[1,])
      } else {
        count_vector <- as.integer(counts[2,])
        names(count_vector) <- counts[1,]
      }
      
      # Create a named vector for just the matching files
      file_counts <- count_vector[matching_files]
      
      # Add counts as an attribute
      attr(matching_files, "counts") <- file_counts
    }
  }
  
  return(matching_files)
} 