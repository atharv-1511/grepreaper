# Test script to verify feedback issues are resolved
library(grepreaper)
library(data.table)

cat("=== Testing grepreaper package for feedback issues ===\n\n")

# Test 1: Basic functionality
cat("Test 1: Basic file reading\n")
test_file <- "data/diamonds.csv"
result <- grep_read(files = test_file, nrows = 5)
cat("Basic test - Rows:", nrow(result), "Columns:", ncol(result), "\n")
cat("Carat column exists:", "carat" %in% names(result), "\n")
cat("First few carat values:", paste(head(result$carat, 3), collapse = ", "), "\n\n")

# Test 2: Multiple files - No metadata (CRITICAL TEST)
cat("Test 2: Multiple files - No metadata (CRITICAL TEST)\n")
multiple_files <- c(test_file, test_file)
result_multiple <- grep_read(
  files = multiple_files, 
  show_line_numbers = FALSE, 
  include_filename = FALSE,
  nrows = 10
)
cat("Multiple files result - Rows:", nrow(result_multiple), "Columns:", ncol(result_multiple), "\n")
if ("carat" %in% names(result_multiple)) {
  carat_na_count <- sum(is.na(result_multiple$carat))
  carat_total <- nrow(result_multiple)
  cat("Carat column - Total rows:", carat_total, "\n")
  cat("Carat column - NA rows:", carat_na_count, "\n")
  cat("Carat column - % NA:", round(carat_na_count/carat_total * 100, 1), "%\n")
  cat("Sample carat values:", paste(head(result_multiple$carat, 5), collapse = ", "), "\n")
} else {
  cat("FAILED: Carat column not found!\n")
}
cat("\n")

# Test 3: Multiple files - Line numbers only (CRITICAL TEST)
cat("Test 3: Multiple files - Line numbers only (CRITICAL TEST)\n")
result_multiple_lines <- grep_read(
  files = multiple_files, 
  show_line_numbers = TRUE, 
  include_filename = FALSE,
  nrows = 10
)
cat("Multiple files with line numbers - Rows:", nrow(result_multiple_lines), "Columns:", ncol(result_multiple_lines), "\n")
if ("carat" %in% names(result_multiple_lines)) {
  carat_na_count <- sum(is.na(result_multiple_lines$carat))
  carat_total <- nrow(result_multiple_lines)
  cat("Carat column - % NA:", round(carat_na_count/carat_total * 100, 1), "%\n")
} else {
  cat("FAILED: Carat column not found!\n")
}
cat("\n")

# Test 4: Multiple files - Filename only (Should pass)
cat("Test 4: Multiple files - Filename only (Should pass)\n")
result_multiple_filename <- grep_read(
  files = multiple_files, 
  show_line_numbers = FALSE, 
  include_filename = TRUE,
  nrows = 10
)
cat("Multiple files with filename - Rows:", nrow(result_multiple_filename), "Columns:", ncol(result_multiple_filename), "\n")
if ("carat" %in% names(result_multiple_filename)) {
  carat_na_count <- sum(is.na(result_multiple_filename$carat))
  carat_total <- nrow(result_multiple_filename)
  cat("Carat column - % NA:", round(carat_na_count/carat_total * 100, 1), "%\n")
} else {
  cat("FAILED: Carat column not found!\n")
}
cat("\n")

# Test 5: Multiple files - Both metadata (Should pass)
cat("Test 5: Multiple files - Both metadata (Should pass)\n")
result_multiple_both <- grep_read(
  files = multiple_files, 
  show_line_numbers = TRUE, 
  include_filename = TRUE,
  nrows = 10
)
cat("Multiple files with both metadata - Rows:", nrow(result_multiple_both), "Columns:", ncol(result_multiple_both), "\n")
if ("carat" %in% names(result_multiple_both)) {
  carat_na_count <- sum(is.na(result_multiple_both$carat))
  carat_total <- nrow(result_multiple_both)
  cat("Carat column - % NA:", round(carat_na_count/carat_total * 100, 1), "%\n")
} else {
  cat("FAILED: Carat column not found!\n")
}
cat("\n")

# Summary
cat("=== SUMMARY ===\n")
cat("All critical tests completed. Check the results above to verify that:\n")
cat("1. Carat column data is preserved (not NA)\n")
cat("2. Multiple file handling works correctly\n")
cat("3. Metadata parsing doesn't corrupt data\n")
cat("\nIf carat column shows 0% NA, the issues are RESOLVED!\n")
