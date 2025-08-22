# Test script for mentor's failing case
Sys.setenv(PATH = paste("C:/Program Files/Git/usr/bin", Sys.getenv("PATH"), sep=";"))

library(data.table)
library(grepreaper)

cat("=== TESTING MENTOR'S FAILING CASE ===\n\n")

# Test 1: Multiple files without filename (the failing case)
cat("Test 1: Multiple files without filename\n")
cat("Files: data/diamonds.csv, data/diamonds.csv\n")
cat("Parameters: show_line_numbers = FALSE, include_filename = FALSE\n\n")

tryCatch({
  result <- grep_read(
    files = c("data/diamonds.csv", "data/diamonds.csv"), 
    pattern = ".*",  # Match all lines
    show_line_numbers = FALSE, 
    include_filename = FALSE
  )
  
  cat("✅ SUCCESS: Function executed\n")
  cat("Result shape:", nrow(result), "rows x", ncol(result), "columns\n")
  cat("Column names:", paste(names(result), collapse = ", "), "\n")
  
  if ("carat" %in% names(result)) {
    na_count <- sum(is.na(result$carat))
    cat("NA count in carat:", na_count, "\n")
    cat("First few carat values:", paste(head(result$carat, 5), collapse = ", "), "\n")
    
    if (na_count == 0) {
      cat("✅ PASS: No NA values in carat column\n")
    } else {
      cat("❌ FAIL: Still has NA values in carat column\n")
      cat("Percentage NA:", round(na_count/nrow(result)*100, 2), "%\n")
    }
  } else {
    cat("❌ FAIL: No 'carat' column found\n")
    cat("Available columns:", paste(names(result), collapse = ", "), "\n")
  }
  
}, error = function(e) {
  cat("❌ ERROR:", e$message, "\n")
  cat("Error class:", class(e), "\n")
})

cat("\n", paste(rep("=", 50), collapse = ""), "\n\n")

# Test 2: Check what grep command is being built
cat("Test 2: Check grep command\n")
tryCatch({
  cmd <- grep_read(
    files = c("data/diamonds.csv", "data/diamonds.csv"), 
    pattern = ".*",
    show_line_numbers = FALSE, 
    include_filename = FALSE,
    show_cmd = TRUE
  )
  
  cat("Grep command:", cmd, "\n")
  
}, error = function(e) {
  cat("❌ ERROR:", e$message, "\n")
})

cat("\n=== TESTING COMPLETE ===\n")
