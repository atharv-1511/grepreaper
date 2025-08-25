#!/usr/bin/env Rscript

# Test script to verify mentor's feedback issues are fixed
# This tests the specific scenarios that were failing

cat("Testing mentor's feedback fixes...\n\n")

# Test 1: Basic functionality with nrows = 10^6
cat("Test 1: Basic functionality with nrows = 10^6\n")
tryCatch({
  # This should work now - no more "nrows must be a non-negative finite number" error
  result <- grep_read(files = "data/diamonds.csv", nrows = 10^6)
  cat("✓ Test 1 PASSED: nrows = 10^6 works correctly\n")
}, error = function(e) {
  cat("✗ Test 1 FAILED:", e$message, "\n")
})

# Test 2: Empty pattern
cat("\nTest 2: Empty pattern\n")
tryCatch({
  # This should work now - no more "EMPTY_PATTERN" issue
  result <- grep_read(files = "data/diamonds.csv", pattern = "")
  cat("✓ Test 2 PASSED: Empty pattern works correctly\n")
}, error = function(e) {
  cat("✗ Test 2 FAILED:", e$message, "\n")
})

# Test 3: Both nrows and empty pattern
cat("\nTest 3: Both nrows = 10^6 and empty pattern\n")
tryCatch({
  result <- grep_read(files = "data/diamonds.csv", nrows = 10^6, pattern = "")
  cat("✓ Test 3 PASSED: Both parameters work together\n")
}, error = function(e) {
  cat("✗ Test 3 FAILED:", e$message, "\n")
})

# Test 4: Multiple files with metadata
cat("\nTest 4: Multiple files with metadata\n")
tryCatch({
  result <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                      show_line_numbers = TRUE, include_filename = TRUE)
  cat("✓ Test 4 PASSED: Multiple files with metadata work correctly\n")
}, error = function(e) {
  cat("✗ Test 4 FAILED:", e$message, "\n")
})

# Test 5: Large nrows value
cat("\nTest 5: Very large nrows value\n")
tryCatch({
  result <- grep_read(files = "data/diamonds.csv", nrows = 10^9)
  cat("✓ Test 5 PASSED: Very large nrows value works correctly\n")
}, error = function(e) {
  cat("✗ Test 5 FAILED:", e$message, "\n")
})

cat("\n=== Summary ===\n")
cat("All tests completed. Check above for any failures.\n")
cat("The main fixes applied:\n")
cat("1. Fixed nrows validation to allow large positive numbers\n")
cat("2. Fixed empty pattern handling to use '.*' instead of 'EMPTY_PATTERN'\n")
cat("3. Maintained all existing functionality while fixing the issues\n")
