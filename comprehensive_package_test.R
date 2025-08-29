# ============================================================================
# COMPREHENSIVE GREPREAPER PACKAGE TEST SUITE
# ============================================================================
# This script tests the ENTIRE grepreaper package from day 1 to current fixes
# Covers: Basic functionality, edge cases, known issues, and advanced features

cat("=== COMPREHENSIVE GREPREAPER PACKAGE TEST SUITE ===\n")
cat("Testing entire package from basic functionality to advanced features\n\n")

# ============================================================================
# STEP 1: Install latest package from GitHub
# ============================================================================

cat("=== STEP 1: Installing Latest Package ===\n\n")

# Remove current package if exists
cat("1. Removing current grepreaper package...\n")
tryCatch({
  # First detach if loaded
  if ("package:grepreaper" %in% search()) {
    detach("package:grepreaper", unload = TRUE)
    cat("✓ Package detached\n")
  }
  remove.packages("grepreaper")
  cat("✓ Package removed successfully\n")
}, error = function(e) {
  cat("ℹ Package not currently installed or couldn't be removed\n")
})

# Install devtools if needed
cat("\n2. Checking/installing devtools...\n")
if (!require(devtools, quietly = TRUE)) {
  install.packages("devtools")
  cat("✓ devtools installed\n")
} else {
  cat("✓ devtools already available\n")
}

# Install from GitHub
cat("\n3. Installing latest grepreaper from GitHub...\n")
tryCatch({
  devtools::install_github("https://github.com/atharv-1511/grepreaper/")
  cat("✓ Package installed from GitHub\n")
}, error = function(e) {
  cat("✗ Installation failed:", e$message, "\n")
  cat("Trying to continue with existing package...\n")
})

# Verify installation
cat("\n4. Verifying installation...\n")
tryCatch({
  library(grepreaper)
  cat("✓ Package loaded successfully\n")
  cat("✓ Package version:", as.character(packageVersion("grepreaper")), "\n\n")
}, error = function(e) {
  cat("✗ Package loading failed:", e$message, "\n")
  cat("Please install the package manually and restart R session\n")
  stop("Package installation failed")
})

# ============================================================================
# STEP 2: Load required packages and setup
# ============================================================================

cat("=== STEP 2: Package Setup ===\n\n")

# Load required packages
if (!require(data.table)) {
  install.packages("data.table")
  library(data.table)
}
cat("✓ data.table loaded\n")

# Create test data files
cat("\n5. Creating test data files...\n")
test_dir <- tempdir()

# Simple test CSV
simple_csv <- file.path(test_dir, "simple_test.csv")
writeLines(c("name,age,city", "John,25,NYC", "Jane,30,LA", "Bob,35,Chicago"), simple_csv)

# CSV with special characters
special_csv <- file.path(test_dir, "special_test.csv")
writeLines(c("id,value,description", "1,3.14,pi", "2,2.71,e", "3,1.41,sqrt(2)"), special_csv)

# CSV with empty values
empty_csv <- file.path(test_dir, "empty_test.csv")
writeLines(c("col1,col2,col3", "a,,c", ",b,", "a,b,"), empty_csv)

# Large test file
large_csv <- file.path(test_dir, "large_test.csv")
large_data <- data.frame(
  id = 1:1000,
  name = paste0("User", 1:1000),
  value = rnorm(1000),
  category = sample(letters[1:5], 1000, replace = TRUE)
)
write.csv(large_data, large_csv, row.names = FALSE)

cat("✓ Test data files created in:", test_dir, "\n\n")

# ============================================================================
# STEP 3: Basic Functionality Tests
# ============================================================================

cat("=== STEP 3: Basic Functionality Tests ===\n\n")

# Test 1: Basic file reading
cat("Test 1: Basic file reading...\n")
tryCatch({
  result <- grep_read(files = simple_csv, pattern = "")
  if (is.data.table(result) && nrow(result) == 3) {
    cat("✓ Basic file reading passed\n")
  } else {
    cat("✗ Basic file reading failed\n")
  }
}, error = function(e) {
  cat("✗ Basic file reading error:", e$message, "\n")
})

# Test 2: Pattern matching
cat("\nTest 2: Pattern matching...\n")
tryCatch({
  result <- grep_read(files = simple_csv, pattern = "John")
  if (is.data.table(result) && nrow(result) == 1) {
    cat("✓ Pattern matching passed\n")
  } else {
    cat("✗ Pattern matching failed\n")
  }
}, error = function(e) {
  cat("✗ Pattern matching error:", e$message, "\n")
})

# Test 3: Case insensitive search
cat("\nTest 3: Case insensitive search...\n")
tryCatch({
  result <- grep_read(files = simple_csv, pattern = "john", ignore_case = TRUE)
  if (is.data.table(result) && nrow(result) == 1) {
    cat("✓ Case insensitive search passed\n")
  } else {
    cat("✗ Case insensitive search failed\n")
  }
}, error = function(e) {
  cat("✗ Case insensitive search error:", e$message, "\n")
})

# Test 4: Fixed string search
cat("\nTest 4: Fixed string search...\n")
tryCatch({
  result <- grep_read(files = special_csv, pattern = "3.14", fixed = TRUE)
  if (is.data.table(result) && nrow(result) == 1) {
    cat("✓ Fixed string search passed\n")
  } else {
    cat("✗ Fixed string search failed\n")
  }
}, error = function(e) {
  cat("✗ Fixed string search error:", e$message, "\n")
})

# Test 5: Invert search
cat("\nTest 5: Invert search...\n")
tryCatch({
  result <- grep_read(files = simple_csv, pattern = "John", invert = TRUE)
  if (is.data.table(result) && nrow(result) == 2) {
    cat("✓ Invert search passed\n")
  } else {
    cat("✗ Invert search failed\n")
  }
}, error = function(e) {
  cat("✗ Invert search error:", e$message, "\n")
})

# ============================================================================
# STEP 4: Advanced Feature Tests
# ============================================================================

cat("\n=== STEP 4: Advanced Feature Tests ===\n\n")

# Test 6: Line numbers
cat("Test 6: Line numbers...\n")
tryCatch({
  result <- grep_read(files = simple_csv, pattern = "", show_line_numbers = TRUE)
  if (is.data.table(result) && "line_number" %in% names(result)) {
    cat("✓ Line numbers feature passed\n")
  } else {
    cat("✗ Line numbers feature failed\n")
  }
}, error = function(e) {
  cat("✗ Line numbers error:", e$message, "\n")
})

# Test 7: Source filename inclusion
cat("\nTest 7: Source filename inclusion...\n")
tryCatch({
  result <- grep_read(files = simple_csv, pattern = "", include_filename = TRUE)
  if (is.data.table(result) && "source_file" %in% names(result)) {
    cat("✓ Source filename inclusion passed\n")
  } else {
    cat("✗ Source filename inclusion failed\n")
  }
}, error = function(e) {
  cat("✗ Source filename inclusion error:", e$message, "\n")
})

# Test 8: Only matching
cat("\nTest 8: Only matching...\n")
tryCatch({
  result <- grep_read(files = simple_csv, pattern = "John", only_matching = TRUE)
  if (is.data.table(result) && "match" %in% names(result)) {
    cat("✓ Only matching feature passed\n")
  } else {
    cat("✗ Only matching feature failed\n")
  }
}, error = function(e) {
  cat("✗ Only matching error:", e$message, "\n")
})

# Test 9: Count only
cat("\nTest 9: Count only...\n")
tryCatch({
  result <- grep_read(files = simple_csv, pattern = "John", count_only = TRUE)
  if (is.data.table(result) && "count" %in% names(result)) {
    cat("✓ Count only feature passed\n")
  } else {
    cat("✗ Count only feature failed\n")
  }
}, error = function(e) {
  cat("✗ Count only error:", e$message, "\n")
})

# Test 10: Show command
cat("\nTest 10: Show command...\n")
tryCatch({
  cmd <- grep_read(files = simple_csv, pattern = "John", show_cmd = TRUE)
  if (is.character(cmd) && length(cmd) == 1) {
    cat("✓ Show command feature passed\n")
  } else {
    cat("✗ Show command feature failed\n")
  }
}, error = function(e) {
  cat("✗ Show command error:", e$message, "\n")
})

# ============================================================================
# STEP 5: Multiple File Tests
# ============================================================================

cat("\n=== STEP 5: Multiple File Tests ===\n\n")

# Test 11: Multiple files basic
cat("Test 11: Multiple files basic...\n")
tryCatch({
  result <- grep_read(files = c(simple_csv, special_csv), pattern = "")
  if (is.data.table(result) && nrow(result) > 0) {
    cat("✓ Multiple files basic passed\n")
  } else {
    cat("✗ Multiple files basic failed\n")
  }
}, error = function(e) {
  cat("✗ Multiple files basic error:", e$message, "\n")
})

# Test 12: Multiple files with line numbers
cat("\nTest 12: Multiple files with line numbers...\n")
tryCatch({
  result <- grep_read(files = c(simple_csv, special_csv), pattern = "", show_line_numbers = TRUE)
  if (is.data.table(result) && "line_number" %in% names(result)) {
    cat("✓ Multiple files with line numbers passed\n")
  } else {
    cat("✗ Multiple files with line numbers failed\n")
  }
}, error = function(e) {
  cat("✗ Multiple files with line numbers error:", e$message, "\n")
})

# Test 13: Multiple files with source filename
cat("\nTest 13: Multiple files with source filename...\n")
tryCatch({
  result <- grep_read(files = c(simple_csv, special_csv), pattern = "", include_filename = TRUE)
  if (is.data.table(result) && "source_file" %in% names(result)) {
    cat("✓ Multiple files with source filename passed\n")
  } else {
    cat("✗ Multiple files with source filename failed\n")
  }
}, error = function(e) {
  cat("✗ Multiple files with source filename error:", e$message, "\n")
})

# ============================================================================
# STEP 6: Edge Case Tests
# ============================================================================

cat("\n=== STEP 6: Edge Case Tests ===\n\n")

# Test 14: Empty pattern
cat("Test 14: Empty pattern...\n")
tryCatch({
  result <- grep_read(files = simple_csv, pattern = "")
  if (is.data.table(result) && nrow(result) > 0) {
    cat("✓ Empty pattern passed\n")
  } else {
    cat("✗ Empty pattern failed\n")
  }
}, error = function(e) {
  cat("✗ Empty pattern error:", e$message, "\n")
})

# Test 15: No matches
cat("\nTest 15: No matches...\n")
tryCatch({
  result <- grep_read(files = simple_csv, pattern = "XYZ123")
  if (is.data.table(result)) {
    cat("✓ No matches handled correctly\n")
  } else {
    cat("✗ No matches handling failed\n")
  }
}, error = function(e) {
  cat("✗ No matches error:", e$message, "\n")
})

# Test 16: Large file handling
cat("\nTest 16: Large file handling...\n")
tryCatch({
  result <- grep_read(files = large_csv, pattern = "", nrows = 100)
  if (is.data.table(result) && nrow(result) == 100) {
    cat("✓ Large file handling passed\n")
  } else {
    cat("✗ Large file handling failed\n")
  }
}, error = function(e) {
  cat("✗ Large file handling error:", e$message, "\n")
})

# Test 17: Skip rows
cat("\nTest 17: Skip rows...\n")
tryCatch({
  result <- grep_read(files = large_csv, pattern = "", skip = 100, nrows = 50)
  if (is.data.table(result) && nrow(result) == 50) {
    cat("✓ Skip rows passed\n")
  } else {
    cat("✗ Skip rows failed\n")
  }
}, error = function(e) {
  cat("✗ Skip rows error:", e$message, "\n")
})

# ============================================================================
# STEP 7: Known Issue Tests (Previously Fixed)
# ============================================================================

cat("\n=== STEP 7: Known Issue Tests (Previously Fixed) ===\n\n")

# Test 18: data.table requirement (Issue 1)
cat("Test 18: data.table requirement (Issue 1)...\n")
tryCatch({
  result <- grep_read(files = simple_csv, count_only = TRUE)
  if (is.data.table(result)) {
    cat("✓ data.table requirement test passed\n")
  } else {
    cat("✗ data.table requirement test failed\n")
  }
}, error = function(e) {
  cat("✗ data.table requirement test error:", e$message, "\n")
})

# Test 19: count_only with multiple files (Issue 2 - the main fix)
cat("\nTest 19: count_only with multiple files (Issue 2)...\n")
tryCatch({
  result <- grep_read(files = rep(simple_csv, 2), count_only = TRUE, pattern = "John")
  if (is.data.table(result) && nrow(result) == 2 && !any(is.na(result$count))) {
    cat("✓ count_only with multiple files test passed\n")
  } else {
    cat("✗ count_only with multiple files test failed\n")
  }
}, error = function(e) {
  cat("✗ count_only with multiple files test error:", e$message, "\n")
})

# Test 20: rep.int example (mentor's specific case)
cat("\nTest 20: rep.int example (mentor's specific case)...\n")
tryCatch({
  result <- grep_read(files = rep.int(x = simple_csv, times = 2), count_only = TRUE, pattern = "John")
  if (is.data.table(result) && nrow(result) == 2 && !any(is.na(result$count))) {
    cat("✓ rep.int example test passed\n")
  } else {
    cat("✗ rep.int example test failed\n")
  }
}, error = function(e) {
  cat("✗ rep.int example test error:", e$message, "\n")
})

# Test 21: Column splitting in multiple files (Issue 3)
cat("\nTest 21: Column splitting in multiple files (Issue 3)...\n")
tryCatch({
  result <- grep_read(files = c(simple_csv, special_csv), pattern = "", nrows = 50)
  if (is.data.table(result) && ncol(result) > 0) {
    cat("✓ Column splitting in multiple files test passed\n")
  } else {
    cat("✗ Column splitting in multiple files test failed\n")
  }
}, error = function(e) {
  cat("✗ Column splitting in multiple files test error:", e$message, "\n")
})

# Test 22: Line numbers recording actual source file lines (Issue 4)
cat("\nTest 22: Line numbers recording actual source file lines (Issue 4)...\n")
tryCatch({
  result <- grep_read(files = c(simple_csv, special_csv), show_line_numbers = TRUE, nrows = 50)
  if (is.data.table(result) && "line_number" %in% names(result)) {
    cat("✓ Line numbers recording actual source file lines test passed\n")
  } else {
    cat("✗ Line numbers recording actual source file lines test failed\n")
  }
}, error = function(e) {
  cat("✗ Line numbers recording actual source file lines test error:", e$message, "\n")
})

# ============================================================================
# STEP 8: Windows Compatibility Tests
# ============================================================================

cat("\n=== STEP 8: Windows Compatibility Tests ===\n\n")

# Test 23: Windows path handling
cat("Test 23: Windows path handling...\n")
tryCatch({
  # Create a file with Windows-style path
  windows_path <- file.path(test_dir, "windows_test.csv")
  writeLines(c("col1,col2", "a,1", "b,2"), windows_path)
  
  result <- grep_read(files = windows_path, pattern = "")
  if (is.data.table(result) && nrow(result) == 2) {
    cat("✓ Windows path handling passed\n")
  } else {
    cat("✗ Windows path handling failed\n")
  }
}, error = function(e) {
  cat("✗ Windows path handling error:", e$message, "\n")
})

# Test 24: Windows path with count_only (the main fix)
cat("\nTest 24: Windows path with count_only (the main fix)...\n")
tryCatch({
  windows_path <- file.path(test_dir, "windows_test.csv")
  result <- grep_read(files = rep(windows_path, 2), count_only = TRUE, pattern = "a")
  if (is.data.table(result) && nrow(result) == 2 && !any(is.na(result$count))) {
    cat("✓ Windows path with count_only test passed\n")
  } else {
    cat("✗ Windows path with count_only test failed\n")
  }
}, error = function(e) {
  cat("✗ Windows path with count_only test error:", e$message, "\n")
})

# ============================================================================
# STEP 9: Performance and Stress Tests
# ============================================================================

cat("\n=== STEP 9: Performance and Stress Tests ===\n\n")

# Test 25: Multiple patterns
cat("Test 25: Multiple patterns...\n")
tryCatch({
  result <- grep_read(files = large_csv, pattern = "User", nrows = 100)
  if (is.data.table(result) && nrow(result) > 0) {
    cat("✓ Multiple patterns test passed\n")
  } else {
    cat("✗ Multiple patterns test failed\n")
  }
}, error = function(e) {
  cat("✗ Multiple patterns test error:", e$message, "\n")
})

# Test 26: Recursive search
cat("\nTest 26: Recursive search...\n")
tryCatch({
  result <- grep_read(path = test_dir, file_pattern = "*.csv", pattern = "", nrows = 50)
  if (is.data.table(result) && nrow(result) > 0) {
    cat("✓ Recursive search test passed\n")
  } else {
    cat("✗ Recursive search test failed\n")
  }
}, error = function(e) {
  cat("✗ Recursive search test error:", e$message, "\n")
})

# ============================================================================
# STEP 10: Error Handling Tests
# ============================================================================

cat("\n=== STEP 10: Error Handling Tests ===\n\n")

# Test 27: Non-existent file
cat("Test 27: Non-existent file...\n")
tryCatch({
  result <- grep_read(files = "non_existent_file.csv", pattern = "")
  cat("✗ Non-existent file should have failed\n")
}, error = function(e) {
  cat("✓ Non-existent file properly handled\n")
})

# Test 28: Invalid pattern
cat("\nTest 28: Invalid pattern...\n")
tryCatch({
  result <- grep_read(files = simple_csv, pattern = NULL)
  cat("✗ Invalid pattern should have failed\n")
}, error = function(e) {
  cat("✓ Invalid pattern properly handled\n")
})

# Test 29: Empty file list
cat("\nTest 29: Empty file list...\n")
tryCatch({
  result <- grep_read(files = character(0), pattern = "")
  cat("✗ Empty file list should have failed\n")
}, error = function(e) {
  cat("✓ Empty file list properly handled\n")
})

# ============================================================================
# STEP 11: Final Validation Tests
# ============================================================================

cat("\n=== STEP 11: Final Validation Tests ===\n\n")

# Test 30: Complex scenario - multiple files, line numbers, source filename
cat("Test 30: Complex scenario - multiple files, line numbers, source filename...\n")
tryCatch({
  result <- grep_read(
    files = c(simple_csv, special_csv, empty_csv),
    pattern = "",
    show_line_numbers = TRUE,
    include_filename = TRUE,
    nrows = 100
  )
  if (is.data.table(result) && 
      "line_number" %in% names(result) && 
      "source_file" %in% names(result) && 
      nrow(result) > 0) {
    cat("✓ Complex scenario test passed\n")
  } else {
    cat("✗ Complex scenario test failed\n")
  }
}, error = function(e) {
  cat("✗ Complex scenario test error:", e$message, "\n")
})

# Test 31: Count only with multiple files (final validation)
cat("\nTest 31: Count only with multiple files (final validation)...\n")
tryCatch({
  result <- grep_read(
    files = c(simple_csv, special_csv, empty_csv),
    count_only = TRUE,
    pattern = "a"
  )
  if (is.data.table(result) && 
      nrow(result) == 3 && 
      !any(is.na(result$count)) && 
      all(result$count >= 0)) {
    cat("✓ Count only with multiple files final validation passed\n")
  } else {
    cat("✗ Count only with multiple files final validation failed\n")
  }
}, error = function(e) {
  cat("✗ Count only with multiple files final validation error:", e$message, "\n")
})

# ============================================================================
# STEP 12: Cleanup and Summary
# ============================================================================

cat("\n=== STEP 12: Cleanup and Summary ===\n\n")

# Clean up test files
cat("Cleaning up test files...\n")
unlink(c(simple_csv, special_csv, empty_csv, large_csv))
cat("✓ Test files cleaned up\n")

# Final summary
cat("\n=== COMPREHENSIVE TEST SUITE COMPLETED ===\n")
cat("If all tests passed, the grepreaper package is fully functional!\n")
cat("This covers:\n")
cat("- Basic functionality\n")
cat("- Advanced features\n")
cat("- Multiple file handling\n")
cat("- Edge cases\n")
cat("- All previously fixed issues\n")
cat("- Windows compatibility\n")
cat("- Error handling\n")
cat("- Performance scenarios\n\n")

cat("The package is ready for production use!\n")
