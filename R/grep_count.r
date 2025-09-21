#' grep_count: Efficiently count the number of relevant records from one or more files using grep, with or without pattern searching.
#' @param files Character vector of file paths to read.
#' @param path Optional. Directory path to search for files.
#' @param file_pattern Optional. A pattern to filter filenames when using the
#'   `path` argument. Passed to `list.files`.
#' @param pattern Pattern to search for within files (passed to grep).
#' @param invert Logical; if TRUE, return non-matching lines.
#' @param ignore_case Logical; if TRUE, perform case-insensitive matching (default: TRUE).
#' @param fixed Logical; if TRUE, pattern is a fixed string, not a regular
#'   expression.
#' @param show_cmd Logical; if TRUE, return the grep command string instead of
#'   executing it.
#' @param recursive Logical; if TRUE, search recursively through directories.
#' @param word_match Logical; if TRUE, match only whole words.
#' @param show_line_numbers Logical; if TRUE, include line numbers from source
#'   files. Headers are automatically removed and lines renumbered.
#' @param only_matching Logical; if TRUE, return only the matching part of the
#'   lines.
#' @param count_only Logical; if TRUE, return only the count of matching lines.
#' @param nrows Integer; maximum number of rows to read.
#' @param skip Integer; number of rows to skip.
#' @param header Logical; if TRUE, treat first row as header.
#' @param col.names Character vector of column names.
#' @param include_filename Logical; if TRUE, include source filename as a column.
#' @param show_progress Logical; if TRUE, show progress indicators.
#' @param ... Additional arguments passed to fread.
#' @return A data.table with different structures based on the options:
#'   - Default: Data columns with original types preserved
#'   - show_line_numbers=TRUE: Additional 'line_number' column (integer) with source file line numbers
#'   - include_filename=TRUE: Additional 'source_file' column (character)
#'   - only_matching=TRUE: Single 'match' column with matched substrings
#'   - count_only=TRUE: 'source_file' and 'count' columns
#'   - show_cmd=TRUE: Character string containing the grep command
#' @importFrom data.table fread setnames data.table as.data.table rbindlist setorder setcolorder ":=" .N
#' @importFrom stats setNames rowSums
#' @importFrom utils globalVariables
#' @export
#' @note When searching for literal strings (not regex patterns), set
#'   `fixed = TRUE` to avoid regex interpretation. For example, searching for
#'   "3.94" with `fixed = FALSE` will match "3894" because "." is a regex
#'   metacharacter.
#'
#' Header rows are automatically handled:
#'   - With show_line_numbers=TRUE: Headers (line_number=1) are removed and
#'     lines renumbered
#'   - Without line numbers: Headers matching column names are removed
#'   - Empty rows and all-NA rows are automatically filtered out

# Fix data.table global variable bindings
utils::globalVariables(c(":=", ".N", "V1", "V2", "V3", "count"))

grep_count <- function(files = NULL, path = NULL, file_pattern = NULL, pattern = "", invert = FALSE, ignore_case = FALSE, fixed = FALSE, recursive = FALSE, word_match = FALSE, only_matching = FALSE, skip = 0, header = TRUE, include_filename = FALSE, show_cmd = FALSE, show_progress = FALSE, ...) {
  
  require(data.table)
  
  need_metadata <- TRUE
  count_only <- TRUE
  
  if(is.null(files) & !is.null(path)){
    files <- list.files(path = path, pattern = file_pattern, full.names = TRUE, recursive = recursive, ignore.case = ignore_case)
  }
  
  
  options <- c("-v", "-i", "-F", "-r", "-w", "-o", "-c", "-H")[c(invert, ignore_case, fixed, recursive, word_match, only_matching, count_only, need_metadata)]
  
  options_str <- paste(options, collapse = " ")
  cmd <- build_grep_cmd(pattern = pattern, files = files, options = options_str, fixed = fixed)

  if(show_cmd == TRUE){
    return(cmd)
  }
  
  # Note:  header=F prevents placing the first file's count in the output's header.  This is different from including the values in the file's header in the count of matching patterns.
  dat <- fread(cmd = cmd, header = F, skip = skip, showProgress = show_progress)
  
  # Split first column if metadata is included.
  
  setnames(x = dat, old = names(dat)[1], new = "V1")
    
  column.names <- c("file", "count")
  additional.columns = split.columns(x = dat[, V1], column.names = column.names, resulting.columns = length(column.names))
    
  dat <- data.table(dat, additional.columns)
  dat[, V1 := NULL]
  
  dat[, count := as.numeric(count)]
  
  if(include_filename == FALSE & "file" %in% names(dat)){
    dat[, file := NULL]
  }
  
  if(header == TRUE){
    simplified.cmd <- build_grep_cmd(pattern = pattern, files = files)
    shallow.copy <- fread(cmd = simplified.cmd, nrows = 1)
    
    in.names <- 1
    if(pattern != ""){
      in.names <- 1*(length(grep(pattern = pattern, x = names(shallow.copy))) > 0)
    }
    dat[, count := count - in.names]
  }
  
  return(dat[])
}
