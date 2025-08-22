# Debug script for grep_read function
library(data.table)

# Set PATH for Windows users (Git grep utility)
if (Sys.info()["sysname"] == "Windows") {
  Sys.setenv(PATH = paste("C:/Program Files/Git/usr/bin", Sys.getenv("PATH"), sep=";"))
}

# Test 1: Check if grep is available
cat("=== Testing grep availability ===\n")
tryCatch({
  grep_result <- system("grep --version", intern = TRUE)
  cat("Grep version:", grep_result[1], "\n")
}, error = function(e) {
  cat("Grep not available:", e$message, "\n")
})

# Test 2: Check if diamonds.csv exists and has content
cat("\n=== Testing file existence ===\n")
diamonds_file <- "data/diamonds.csv"
if (file.exists(diamonds_file)) {
  cat("File exists:", diamonds_file, "\n")
  file_size <- file.size(diamonds_file)
  cat("File size:", file_size, "bytes\n")
  
  # Check first few lines
  first_lines <- readLines(diamonds_file, n = 3)
  cat("First 3 lines:\n")
  for (i in seq_along(first_lines)) {
    cat("Line", i, ":", first_lines[i], "\n")
  }
} else {
  cat("File does not exist:", diamonds_file, "\n")
}

# Test 3: Test basic grep command
cat("\n=== Testing basic grep command ===\n")
tryCatch({
  grep_cmd <- paste("grep", ".*", shQuote(diamonds_file))
  cat("Grep command:", grep_cmd, "\n")
  
  grep_output <- system(grep_cmd, intern = TRUE)
  cat("Grep output length:", length(grep_output), "\n")
  if (length(grep_output) > 0) {
    cat("First few lines of grep output:\n")
    for (i in 1:min(3, length(grep_output))) {
      cat("Line", i, ":", grep_output[i], "\n")
    }
  }
}, error = function(e) {
  cat("Grep command failed:", e$message, "\n")
})

# Test 4: Test with grepreaper package
cat("\n=== Testing grepreaper package ===\n")
tryCatch({
  library(grepreaper)
  cat("Package loaded successfully\n")
  
  # Test simple grep_read
  cat("Testing simple grep_read...\n")
  result <- grep_read(files = diamonds_file, pattern = ".*")
  cat("Result class:", class(result), "\n")
  cat("Result dimensions:", if(is.null(dim(result))) "NULL" else paste(dim(result), collapse="x"), "\n")
  cat("Result names:", if(is.null(names(result))) "NULL" else paste(names(result), collapse=", "), "\n")
  
  if (!is.null(result) && length(result) > 0) {
    cat("First few rows:\n")
    print(head(result, 3))
  }
  
}, error = function(e) {
  cat("Package test failed:", e$message, "\n")
  cat("Error details:", e$call, "\n")
})
