#' Search for pattern with context lines
#' 
#' This function searches for a pattern in files and returns matches with context lines
#' before and after each match, similar to grep -A and -B options.
#' 
#' @param files Character vector of file paths.
#' @param pattern Pattern to search for.
#' @param before Integer; number of lines to show before each match.
#' @param after Integer; number of lines to show after each match.
#' @param invert Logical; if TRUE, show non-matching lines.
#' @param ignore_case Logical; if TRUE, perform case-insensitive matching.
#' @param fixed Logical; if TRUE, pattern is a fixed string, not a regular expression.
#' @param show_cmd Logical; if TRUE, print the grep command used.
#' @param recursive Logical; if TRUE, search recursively through directories.
#' @param word_match Logical; if TRUE, match only whole words.
#' @param as_data_table Logical; if TRUE, return a data.table instead of character vector.
#' 
#' @return Character vector of matched lines with context, or data.table if as_data_table is TRUE.
#' 
#' @examples
#' \dontrun{
#' # Search for "IT" with 2 lines before and after each match
#' grep_context("data/sample_data.csv", "IT", before = 2, after = 2)
#' 
#' # Return results as a data.table with source and line information
#' result_dt <- grep_context("data/sample_data.csv", "IT", before = 1, after = 1, as_data_table = TRUE)
#' }
#' 
#' @importFrom data.table data.table
#' @export
grep_context <- function(files, pattern, before = 0, after = 0, invert = FALSE, 
                         ignore_case = FALSE, fixed = FALSE, show_cmd = FALSE, 
                         recursive = FALSE, word_match = FALSE, as_data_table = FALSE) {
  
  # Input validation
  if (!is.character(files) || length(files) == 0) {
    stop("'files' must be a non-empty character vector")
  }
  if (!is.character(pattern) || length(pattern) != 1) {
    stop("'pattern' must be a single character string")
  }
  if (!is.numeric(before) || before < 0) {
    stop("'before' must be a non-negative integer")
  }
  if (!is.numeric(after) || after < 0) {
    stop("'after' must be a non-negative integer")
  }
  
  # Build grep options
  options <- ""
  if (before > 0) options <- paste(options, sprintf("-B %d", before))
  if (after > 0) options <- paste(options, sprintf("-A %d", after))
  if (invert) options <- paste(options, "-v")
  if (ignore_case) options <- paste(options, "-i")
  if (fixed) options <- paste(options, "-F")
  if (recursive) options <- paste(options, "-r")
  if (word_match) options <- paste(options, "-w")
  
  # Add filename info if multiple files are being searched
  if (length(files) > 1) options <- paste(options, "-H")
  
  # Build the command
  cmd <- build_grep_cmd(pattern, files, options)
  
  # Return command if requested
  if (show_cmd) {
    return(cmd)
  }
  
  # Execute grep command
  result <- safe_system_call(cmd)
  
  # If no results, return empty result
  if (length(result) == 0) {
    if (as_data_table) {
      return(data.table::data.table(
        file = character(0),
        line_num = integer(0),
        content = character(0),
        match_type = character(0)
      ))
    } else {
      return(character(0))
    }
  }
  
  # Process results as data.table if requested
  if (as_data_table) {
    # Define pattern for separator lines
    sep_pattern <- "^--$"
    
    # Identify files from results (if filename is included)
    has_file_info <- grepl(":", result, fixed = TRUE)
    
    # Extract file info and build data.table
    files_vec <- character(length(result))
    line_nums <- integer(length(result))
    match_types <- character(length(result)) # "match", "before", "after", or "separator"
    
    # Figure out match type and extract file info
    in_after_context <- FALSE
    for (i in seq_along(result)) {
      line <- result[i]
      
      # Check if it's a separator line
      if (grepl(sep_pattern, line)) {
        match_types[i] <- "separator"
        in_after_context <- FALSE
        next
      }
      
      # Extract file info if available
      if (has_file_info[i]) {
        parts <- strsplit(line, ":", fixed = TRUE)[[1]]
        if (length(parts) >= 2) {
          files_vec[i] <- parts[1]
          # Adjust the result line to remove the file prefix
          result[i] <- paste(parts[-1], collapse = ":")
        }
      } else if (i > 1 && has_file_info[i-1]) {
        # If previous line had file info, use the same
        files_vec[i] <- files_vec[i-1]
      } else {
        # Default to the first file in the list if no info
        files_vec[i] <- files[1]
      }
      
      # Determine match type (this is approximate without line numbers)
      if (grepl(paste0(".*", pattern, ".*"), line, ignore.case = ignore_case)) {
        match_types[i] <- "match"
        in_after_context <- TRUE
      } else if (in_after_context) {
        match_types[i] <- "after"
      } else {
        match_types[i] <- "before"
      }
    }
    
    # Create data.table
    dt <- data.table::data.table(
      file = files_vec,
      line_num = line_nums,  # Note: actual line numbers aren't available without extra parsing
      content = result,
      match_type = match_types
    )
    
    return(dt)
  } else {
    # Return as character vector
    return(result)
  }
} 