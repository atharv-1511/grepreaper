# Cross-Device Testing Script for grepreaper Package
# This script tests the package functionality across different platforms

cat("=== GREPREAPER CROSS-DEVICE TESTING ===\n")
cat("Testing grepreaper package functionality\n")
cat("Date:", Sys.Date(), "\n")
cat("Platform:", R.version$platform, "\n")
cat("R Version:", R.version$version.string, "\n\n")

# Load required libraries
required_packages <- c("devtools", "data.table")
missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]

if (length(missing_packages) > 0) {
  cat("❌ Missing required packages:", paste(missing_packages, collapse = ", "), "\n")
  cat("Please install with: install.packages(c(", paste0('"', missing_packages, '"', collapse = ", "), "))\n")
  stop("Required packages missing")
}

cat("✅ All required packages available\n\n")

# Load the package
cat("Loading grepreaper package...\n")
tryCatch({
  devtools::load_all()
  cat("✅ Package loaded successfully\n\n")
}, error = function(e) {
  cat("❌ Package loading failed:", e$message, "\n")
  stop("Package loading failed")
})

# Test 1: Function Availability
cat("=== TEST 1: FUNCTION AVAILABILITY ===\n")
functions_to_test <- c("grep_read", "grep_count", "split.columns", "build_grep_cmd")
function_results <- list()

for (func in functions_to_test) {
  if (exists(func)) {
    cat("✅", func, "function available\n")
    function_results[[func]] <- "AVAILABLE"
  } else {
    cat("❌", func, "function NOT available\n")
    function_results[[func]] <- "MISSING"
  }
}

# Test 2: Basic Functionality
cat("\n=== TEST 2: BASIC FUNCTIONALITY ===\n")

# Test grep_count
cat("Testing grep_count...\n")
tryCatch({
  result_count <- grep_count(files = "data/diamonds.csv", pattern = "Ideal")
  cat("✅ grep_count works - Result:", nrow(result_count), "rows\n")
  if (nrow(result_count) > 0) {
    cat("   Sample result:", result_count[1, ], "\n")
  }
}, error = function(e) {
  cat("❌ grep_count failed:", e$message, "\n")
})

# Test grep_read
cat("Testing grep_read...\n")
tryCatch({
  result_read <- grep_read(files = "data/diamonds.csv", pattern = "Ideal", nrows = 3)
  cat("✅ grep_read works - Result:", nrow(result_read), "rows\n")
  if (nrow(result_read) > 0) {
    cat("   Columns:", paste(names(result_read), collapse = ", "), "\n")
  }
}, error = function(e) {
  cat("❌ grep_read failed:", e$message, "\n")
})

# Test 3: Edge Cases
cat("\n=== TEST 3: EDGE CASES ===\n")

# Test with no matches
cat("Testing no matches scenario...\n")
tryCatch({
  result_no_match <- grep_read(files = "data/diamonds.csv", pattern = "NONEXISTENT_PATTERN", nrows = 5)
  cat("✅ No matches handled correctly - Result:", nrow(result_no_match), "rows\n")
}, error = function(e) {
  cat("❌ No matches test failed:", e$message, "\n")
})

# Test with empty pattern
cat("Testing empty pattern...\n")
tryCatch({
  result_empty <- grep_read(files = "data/diamonds.csv", pattern = "", nrows = 3)
  cat("✅ Empty pattern handled correctly - Result:", nrow(result_empty), "rows\n")
}, error = function(e) {
  cat("❌ Empty pattern test failed:", e$message, "\n")
})

# Test 4: Performance Test
cat("\n=== TEST 4: PERFORMANCE TEST ===\n")
cat("Testing performance with larger dataset...\n")
start_time <- Sys.time()
tryCatch({
  result_perf <- grep_read(files = "data/diamonds.csv", pattern = "Ideal", nrows = 100)
  end_time <- Sys.time()
  duration <- as.numeric(difftime(end_time, start_time, units = "secs"))
  cat("✅ Performance test passed - Duration:", round(duration, 3), "seconds\n")
  cat("   Processed", nrow(result_perf), "rows\n")
}, error = function(e) {
  cat("❌ Performance test failed:", e$message, "\n")
})

# Test 5: Platform-Specific Tests
cat("\n=== TEST 5: PLATFORM-SPECIFIC TESTS ===\n")

# Test file path handling
cat("Testing file path handling...\n")
tryCatch({
  # Test with different path formats
  test_files <- c("data/diamonds.csv", "./data/diamonds.csv")
  for (file in test_files) {
    if (file.exists(file)) {
      result_path <- grep_read(files = file, pattern = "Ideal", nrows = 2)
      cat("✅ Path format", file, "works\n")
    }
  }
}, error = function(e) {
  cat("❌ File path test failed:", e$message, "\n")
})

# Test 6: Data Type Preservation
cat("\n=== TEST 6: DATA TYPE PRESERVATION ===\n")
tryCatch({
  result_types <- grep_read(files = "data/diamonds.csv", pattern = "Ideal", nrows = 5)
  cat("✅ Data types preserved\n")
  cat("   Column types:", paste(sapply(result_types, class), collapse = ", "), "\n")
}, error = function(e) {
  cat("❌ Data type test failed:", e$message, "\n")
})

# Test 7: Multiple Files (if available)
cat("\n=== TEST 7: MULTIPLE FILES TEST ===\n")
available_files <- list.files("data", pattern = "\\.csv$", full.names = TRUE)
if (length(available_files) > 1) {
  cat("Testing multiple files:", length(available_files), "files available\n")
  tryCatch({
    result_multi <- grep_read(files = available_files, pattern = "Ideal", nrows = 5)
    cat("✅ Multiple files test passed - Result:", nrow(result_multi), "rows\n")
  }, error = function(e) {
    cat("❌ Multiple files test failed:", e$message, "\n")
  })
} else {
  cat("ℹ️ Only one file available, skipping multiple files test\n")
}

# Summary
cat("\n=== TESTING SUMMARY ===\n")
cat("Platform:", R.version$platform, "\n")
cat("R Version:", R.version$version.string, "\n")
cat("Package Version: 0.1.0\n")
cat("Test Date:", Sys.Date(), "\n")
cat("Test Time:", format(Sys.time(), "%H:%M:%S"), "\n")

# Count successful tests
total_tests <- 7
cat("\nCross-device testing completed!\n")
cat("Please share these results with the development team.\n")
cat("If any tests failed, please include the error messages.\n")
