#' @export
split.columns <- function(x, column.names = NA, split = ":", resulting.columns = 3, fixed = TRUE) {
  require(data.table)
 
  the.pieces <- strsplit(x = x, split = split, fixed = fixed)
 
  new.columns <- data.table()
 
  for(i in 1:resulting.columns) {
    if(i < resulting.columns) {
      new.columns[, eval(sprintf("V%s", i)) := lapply(X = the.pieces, FUN = function(y) {
        return(y[i])
      })]
    }
    if(i == resulting.columns) {
      new.columns[, eval(sprintf("V%s", i)) := lapply(X = the.pieces, FUN = function(y) {
        return(paste(y[i:length(y)], collapse = ":"))
      })]
    }
  }
 
  if(!is.na(column.names[1])) {
    setnames(x = new.columns, old = names(new.columns), new = column.names)
  }
 
  return(new.columns)
}

#' Check if grep is available on the system
#' @return A list with 'available' logical indicating if grep is available
#' @export
check_grep_availability <- function() {
  available <- FALSE
  tryCatch({
    result <- system("grep --version", intern = TRUE, ignore.stderr = TRUE)
    available <- length(result) > 0
  }, error = function(e) {
    available <- FALSE
  }, warning = function(w) {
    available <- FALSE
  })
  
  return(list(available = available))
}

#' Build grep command string
#' @param pattern Pattern to search for
#' @param files Files to search in
#' @param options Options string for grep
#' @return Command string
#' @export
build_grep_cmd <- function(pattern, files, options = "") {
  if (options != "") {
    options <- paste(options, "")
  }
  cmd <- sprintf("grep %s%s %s", options, shQuote(pattern), paste(shQuote(files), collapse = " "))
  return(cmd)
}

#' Safe system call that handles errors gracefully
#' @param cmd Command to execute
#' @return Result of system call or empty character vector on error
#' @export
safe_system_call <- function(cmd) {
  tryCatch({
    result <- system(cmd, intern = TRUE, ignore.stderr = TRUE)
    return(result)
  }, error = function(e) {
    return(character(0))
  }, warning = function(w) {
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
