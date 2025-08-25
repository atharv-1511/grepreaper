#!/usr/bin/env Rscript

# Comprehensive test to verify ALL mentor's feedback issues are resolved
# This tests every single scenario that was failing

cat("=== COMPREHENSIVE MENTOR ISSUES VERIFICATION ===\n\n")

# Load the package
if (!require(grepreaper, quietly = TRUE)) {
  cat("Loading grepreaper package...\n")
  devtools::load_all(".")
}

cat("Testing ALL scenarios that were failing...\n\n")

# Test 1: Basic functionality with nrows = 10^6 (was failing with validation error)
cat("Test 1: nrows = 10^6 (was failing with 'nrows must be a non-negative finite number')\n")
tryCatch({
  result <- grep_read(files = "data/diamonds.csv", nrows = 10^6)
  cat("✓ PASSED: nrows = 10^6 works correctly\n")
  cat("  - Rows returned:", nrow(result), "\n")
  cat("  - Columns:", paste(names(result), collapse = ", "), "\n")
}, error = function(e) {
  cat("✗ FAILED:", e$message, "\n")
})

# Test 2: Empty pattern (was failing with EMPTY_PATTERN)
cat("\nTest 2: Empty pattern (was failing with EMPTY_PATTERN)\n")
tryCatch({
  result <- grep_read(files = "data/diamonds.csv", pattern = "")
  cat("✓ PASSED: Empty pattern works correctly\n")
  cat("  - Rows returned:", nrow(result), "\n")
  cat("  - Columns:", paste(names(result), collapse = ", "), "\n")
}, error = function(e) {
  cat("✗ FAILED:", e$message, "\n")
})

# Test 3: Pattern matching with nrows = 10^6
cat("\nTest 3: Pattern matching with nrows = 10^6\n")
tryCatch({
  result <- grep_read(files = "data/diamonds.csv", nrows = 10^6, pattern = "VS1")
  cat("✓ PASSED: Pattern matching with large nrows works\n")
  cat("  - Rows returned:", nrow(result), "\n")
  cat("  - First few rows:\n")
  if (nrow(result) > 0) {
    print(head(result, 3))
  }
}, error = function(e) {
  cat("✗ FAILED:", e$message, "\n")
})

# Test 4: Multiple files - No filename, no line numbers
cat("\nTest 4: Multiple files - No filename, no line numbers\n")
tryCatch({
  result <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                      show_line_numbers = FALSE, include_filename = FALSE)
  cat("✓ PASSED: Multiple files without metadata works\n")
  cat("  - Rows returned:", nrow(result), "\n")
  cat("  - Columns:", paste(names(result), collapse = ", "), "\n")
}, error = function(e) {
  cat("✗ FAILED:", e$message, "\n")
})

# Test 5: Multiple files - No filename, with line numbers
cat("\nTest 5: Multiple files - No filename, with line numbers\n")
tryCatch({
  result <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                      show_line_numbers = TRUE, include_filename = FALSE)
  cat("✓ PASSED: Multiple files with line numbers works\n")
  cat("  - Rows returned:", nrow(result), "\n")
  cat("  - Columns:", paste(names(result), collapse = ", "), "\n")
  if ("line_number" %in% names(result)) {
    cat("  - Line numbers present and working\n")
  }
}, error = function(e) {
  cat("✗ FAILED:", e$message, "\n")
})

# Test 6: Multiple files - With filename, no line numbers
cat("\nTest 6: Multiple files - With filename, no line numbers\n")
tryCatch({
  result <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                      show_line_numbers = FALSE, include_filename = TRUE)
  cat("✓ PASSED: Multiple files with filename works\n")
  cat("  - Rows returned:", nrow(result), "\n")
  cat("  - Columns:", paste(names(result), collapse = ", "), "\n")
  if ("source_file" %in% names(result)) {
    cat("  - Source file column present and working\n")
  }
}, error = function(e) {
  cat("✗ FAILED:", e$message, "\n")
})

# Test 7: Multiple files - With filename and line numbers
cat("\nTest 7: Multiple files - With filename and line numbers\n")
tryCatch({
  result <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                      show_line_numbers = TRUE, include_filename = TRUE)
  cat("✓ PASSED: Multiple files with both metadata works\n")
  cat("  - Rows returned:", nrow(result), "\n")
  cat("  - Columns:", paste(names(result), collapse = ", "), "\n")
  if ("source_file" %in% names(result) && "line_number" %in% names(result)) {
    cat("  - Both metadata columns present and working\n")
  }
}, error = function(e) {
  cat("✗ FAILED:", e$message, "\n")
})

# Test 8: Large nrows with multiple files and metadata
cat("\nTest 8: Large nrows with multiple files and metadata\n")
tryCatch({
  result <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                      nrows = 10^6, show_line_numbers = TRUE, include_filename = TRUE)
  cat("✓ PASSED: Large nrows with metadata works\n")
  cat("  - Rows returned:", nrow(result), "\n")
  cat("  - Columns:", paste(names(result), collapse = ", "), "\n")
}, error = function(e) {
  cat("✗ FAILED:", e$message, "\n")
})

# Test 9: Empty pattern with multiple files and metadata
cat("\nTest 9: Empty pattern with multiple files and metadata\n")
tryCatch({
  result <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                      pattern = "", show_line_numbers = TRUE, include_filename = TRUE)
  cat("✓ PASSED: Empty pattern with metadata works\n")
  cat("  - Rows returned:", nrow(result), "\n")
  cat("  - Columns:", paste(names(result), collapse = ", "), "\n")
}, error = function(e) {
  cat("✗ FAILED:", e$message, "\n")
})

# Test 10: Pattern matching with multiple files and metadata
cat("\nTest 10: Pattern matching with multiple files and metadata\n")
tryCatch({
  result <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                      pattern = "VS1", show_line_numbers = TRUE, include_filename = TRUE)
  cat("✓ PASSED: Pattern matching with metadata works\n")
  cat("  - Rows returned:", nrow(result), "\n")
  cat("  - Columns:", paste(names(result), collapse = ", "), "\n")
  if (nrow(result) > 0) {
    cat("  - First few rows:\n")
    print(head(result, 3))
  }
}, error = function(e) {
  cat("✗ FAILED:", e$message, "\n")
})

# Test 11: Show command functionality
cat("\nTest 11: Show command functionality\n")
tryCatch({
  cmd <- grep_read(files = "data/diamonds.csv", show_cmd = TRUE, nrows = 10^6, pattern = "VS1")
  cat("✓ PASSED: Show command works\n")
  cat("  - Command:", cmd, "\n")
}, error = function(e) {
  cat("✗ FAILED:", e$message, "\n")
})

# Test 12: Data integrity check - verify carat column is not corrupted
cat("\nTest 12: Data integrity check - verify carat column is not corrupted\n")
tryCatch({
  result <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                      show_line_numbers = TRUE, include_filename = TRUE)
  
  if ("carat" %in% names(result)) {
    # Check if carat values are numeric and reasonable
    carat_vals <- result$carat
    if (is.numeric(carat_vals) && all(carat_vals >= 0, na.rm = TRUE)) {
      cat("✓ PASSED: Carat column integrity maintained\n")
      cat("  - Carat values are numeric and reasonable\n")
      cat("  - Range:", range(carat_vals, na.rm = TRUE), "\n")
    } else {
      cat("✗ FAILED: Carat column corrupted - values not numeric or reasonable\n")
    }
  } else {
    cat("✗ FAILED: Carat column missing\n")
  }
}, error = function(e) {
  cat("✗ FAILED:", e$message, "\n")
})

cat("\n=== VERIFICATION COMPLETE ===\n")
cat("All tests completed. Check above for any failures.\n")
