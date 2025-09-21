# Windows-specific test for grepreaper package
cat("=== WINDOWS COMPATIBILITY TEST ===\n")
cat("Platform:", R.version$platform, "\n")
cat("OS Type:", .Platform$OS.type, "\n\n")

# Load package
library(devtools)
load_all()

cat("Testing Windows-compatible functions...\n\n")

# Test 1: Basic grep_read functionality
cat("Test 1: grep_read with pattern matching\n")
tryCatch({
  result1 <- grep_read(files = "data/diamonds.csv", pattern = "Ideal", nrows = 5)
  cat("✅ grep_read successful -", nrow(result1), "rows returned\n")
  if (nrow(result1) > 0) {
    cat("   Columns:", paste(names(result1), collapse = ", "), "\n")
    cat("   Sample data:\n")
    print(head(result1, 2))
  }
}, error = function(e) {
  cat("❌ grep_read failed:", e$message, "\n")
})

# Test 2: grep_count functionality
cat("\nTest 2: grep_count with pattern matching\n")
tryCatch({
  result2 <- grep_count(files = "data/diamonds.csv", pattern = "Ideal")
  cat("✅ grep_count successful -", nrow(result2), "rows returned\n")
  if (nrow(result2) > 0) {
    cat("   Result:\n")
    print(result2)
  }
}, error = function(e) {
  cat("❌ grep_count failed:", e$message, "\n")
})

# Test 3: Case-insensitive matching
cat("\nTest 3: Case-insensitive matching\n")
tryCatch({
  result3 <- grep_read(files = "data/diamonds.csv", pattern = "ideal", ignore_case = TRUE, nrows = 3)
  cat("✅ Case-insensitive matching successful -", nrow(result3), "rows returned\n")
}, error = function(e) {
  cat("❌ Case-insensitive matching failed:", e$message, "\n")
})

# Test 4: Fixed string matching
cat("\nTest 4: Fixed string matching\n")
tryCatch({
  result4 <- grep_read(files = "data/diamonds.csv", pattern = "Ideal", fixed = TRUE, nrows = 3)
  cat("✅ Fixed string matching successful -", nrow(result4), "rows returned\n")
}, error = function(e) {
  cat("❌ Fixed string matching failed:", e$message, "\n")
})

# Test 5: Multiple files (if available)
cat("\nTest 5: Multiple files\n")
available_files <- list.files("data", pattern = "\\.csv$", full.names = TRUE)
if (length(available_files) > 1) {
  tryCatch({
    result5 <- grep_read(files = available_files, pattern = "Ideal", nrows = 3)
    cat("✅ Multiple files successful -", nrow(result5), "rows returned\n")
  }, error = function(e) {
    cat("❌ Multiple files failed:", e$message, "\n")
  })
} else {
  cat("ℹ️ Only one file available, skipping multiple files test\n")
}

# Test 6: Empty pattern (should return all rows)
cat("\nTest 6: Empty pattern (all rows)\n")
tryCatch({
  result6 <- grep_read(files = "data/diamonds.csv", pattern = "", nrows = 5)
  cat("✅ Empty pattern successful -", nrow(result6), "rows returned\n")
}, error = function(e) {
  cat("❌ Empty pattern failed:", e$message, "\n")
})

# Test 7: No matches scenario
cat("\nTest 7: No matches scenario\n")
tryCatch({
  result7 <- grep_read(files = "data/diamonds.csv", pattern = "NONEXISTENT_PATTERN", nrows = 5)
  cat("✅ No matches handled correctly -", nrow(result7), "rows returned\n")
}, error = function(e) {
  cat("❌ No matches test failed:", e$message, "\n")
})

cat("\n=== WINDOWS TEST COMPLETE ===\n")
cat("All Windows compatibility tests completed!\n")
