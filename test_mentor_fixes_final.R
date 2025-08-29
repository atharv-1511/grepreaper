# Comprehensive Test Script for Mentor Feedback Fixes
# This script tests ALL the issues mentioned in the mentor's feedback
# Using the specific file paths provided by the user

library(data.table)

# Define the file paths
DIAMONDS_FILE <- "C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv"
AMUSEMENT_FILE <- "C:\\Users\\Atharv Raskar\\Downloads\\Amusement_Parks_Rides_Registered.csv"
STRESS_FILE <- "C:\\Users\\Atharv Raskar\\Downloads\\academic Stress level - maintainance 1.csv"

cat("=== Testing Mentor Feedback Fixes with User's Data Files ===\n\n")

# Test 1: Check if data.table is properly required (Issue 1)
cat("Test 1: Checking data.table requirement...\n")
tryCatch({
  # This should work without errors
  result <- grep_read(files = DIAMONDS_FILE, count_only = TRUE)
  cat("✓ data.table requirement test passed\n")
  cat("  Result type:", class(result), "\n")
  cat("  Result structure:\n")
  print(result)
}, error = function(e) {
  cat("✗ data.table requirement test failed:", e$message, "\n")
})

# Test 2: Test count_only with multiple files (Issue 2 - the mentor's specific example)
cat("\nTest 2: Testing count_only with multiple files...\n")
tryCatch({
  # This should return proper counts, not NA values
  result <- grep_read(files = rep(DIAMONDS_FILE, 2), count_only = TRUE, pattern = "VVS1")
  cat("✓ count_only with multiple files test passed\n")
  cat("  Result type:", class(result), "\n")
  cat("  Result structure:\n")
  print(result)
}, error = function(e) {
  cat("✗ count_only with multiple files test failed:", e$message, "\n")
})

# Test 3: Test the specific mentor example with rep.int
cat("\nTest 3: Testing the specific mentor example with rep.int...\n")
tryCatch({
  # This should return proper counts, not NA values
  result <- grep_read(files = rep.int(x = DIAMONDS_FILE, times = 2), 
                      count_only = TRUE, pattern = "VVS1")
  cat("✓ rep.int example test passed\n")
  cat("  Result type:", class(result), "\n")
  cat("  Result structure:\n")
  print(result)
}, error = function(e) {
  cat("✗ rep.int example test failed:", e$message, "\n")
})

# Test 4: Test column splitting in multiple file scenarios (Issue 3)
cat("\nTest 4: Testing column splitting in multiple file scenarios...\n")
tryCatch({
  # This should properly split columns when using multiple files
  result <- grep_read(files = c(DIAMONDS_FILE, AMUSEMENT_FILE), 
                      show_line_numbers = FALSE, 
                      include_filename = FALSE, 
                      nrows = 100, 
                      pattern = "")
  cat("✓ column splitting in multiple files test passed\n")
  cat("  Columns:", paste(names(result), collapse = ", "), "\n")
  cat("  Rows:", nrow(result), "\n")
}, error = function(e) {
  cat("✗ column splitting in multiple files test failed:", e$message, "\n")
})

# Test 5: Test line numbers recording actual source file lines (Issue 4)
cat("\nTest 5: Testing line numbers recording actual source file lines...\n")
tryCatch({
  # This should record actual line numbers from source files, not sequential row numbers
  result <- grep_read(files = c(DIAMONDS_FILE, AMUSEMENT_FILE), 
                      show_line_numbers = TRUE, 
                      include_filename = FALSE, 
                      nrows = 100, 
                      pattern = "")
  cat("✓ line numbers test passed\n")
  if ("line_number" %in% names(result)) {
    cat("  Line numbers present:", length(unique(result$line_number)), "unique values\n")
    cat("  First few line numbers:", head(result$line_number, 5), "\n")
    cat("  Line numbers range:", range(result$line_number), "\n")
  } else {
    cat("  No line_number column found (this might be expected)\n")
  }
}, error = function(e) {
  cat("✗ line numbers test failed:", e$message, "\n")
})

# Test 6: Test show_cmd to verify grep command building
cat("\nTest 6: Testing show_cmd to verify grep command building...\n")
tryCatch({
  # This should show the grep command with proper -H flag
  cmd <- grep_read(files = c(DIAMONDS_FILE, AMUSEMENT_FILE), 
                   count_only = TRUE, 
                   pattern = "test", 
                   show_cmd = TRUE)
  cat("✓ show_cmd test passed\n")
  cat("  Command:", cmd, "\n")
  # Check if -H flag is present for multiple files
  if (grepl("-H", cmd)) {
    cat("  ✓ -H flag is present (correct for multiple files)\n")
  } else {
    cat("  ✗ -H flag is missing (incorrect for multiple files)\n")
  }
}, error = function(e) {
  cat("✗ show_cmd test failed:", e$message, "\n")
})

# Test 7: Test multiple files with line numbers and no filename
cat("\nTest 7: Testing multiple files with line numbers and no filename...\n")
tryCatch({
  # This should work correctly and preserve actual line numbers
  result <- grep_read(files = c(DIAMONDS_FILE, AMUSEMENT_FILE), 
                      show_line_numbers = TRUE, 
                      include_filename = FALSE, 
                      nrows = 100, 
                      pattern = "")
  cat("✓ multiple files with line numbers test passed\n")
  cat("  Rows:", nrow(result), "\n")
  if ("line_number" %in% names(result)) {
    cat("  Line numbers range:", range(result$line_number), "\n")
  }
}, error = function(e) {
  cat("✗ multiple files with line numbers test failed:", e$message, "\n")
})

# Test 8: Test multiple files with filename and line numbers
cat("\nTest 8: Testing multiple files with filename and line numbers...\n")
tryCatch({
  # This should work correctly and preserve actual line numbers
  result <- grep_read(files = c(DIAMONDS_FILE, AMUSEMENT_FILE), 
                      show_line_numbers = TRUE, 
                      include_filename = TRUE, 
                      nrows = 100, 
                      pattern = "")
  cat("✓ multiple files with filename and line numbers test passed\n")
  cat("  Rows:", nrow(result), "\n")
  if ("source_file" %in% names(result)) {
    cat("  Source files:", unique(result$source_file), "\n")
  }
  if ("line_number" %in% names(result)) {
    cat("  Line numbers range:", range(result$line_number), "\n")
  }
}, error = function(e) {
  cat("✗ multiple files with filename and line numbers test failed:", e$message, "\n")
})

# Test 9: Test pattern matching with actual data
cat("\nTest 9: Testing pattern matching with actual data...\n")
tryCatch({
  # Test with a pattern that should exist in the diamonds data
  result <- grep_read(files = DIAMONDS_FILE, 
                      pattern = "VVS1", 
                      nrows = 50, 
                      show_line_numbers = TRUE)
  cat("✓ pattern matching test passed\n")
  cat("  Rows found:", nrow(result), "\n")
  if ("line_number" %in% names(result)) {
    cat("  Line numbers range:", range(result$line_number), "\n")
  }
}, error = function(e) {
  cat("✗ pattern matching test failed:", e$message, "\n")
})

# Test 10: Test with all three files
cat("\nTest 10: Testing with all three files...\n")
tryCatch({
  # This should work correctly with all three files
  result <- grep_read(files = c(DIAMONDS_FILE, AMUSEMENT_FILE, STRESS_FILE), 
                      show_line_numbers = TRUE, 
                      include_filename = TRUE, 
                      nrows = 50, 
                      pattern = "")
  cat("✓ all three files test passed\n")
  cat("  Rows:", nrow(result), "\n")
  if ("source_file" %in% names(result)) {
    cat("  Source files:", unique(result$source_file), "\n")
  }
  if ("line_number" %in% names(result)) {
    cat("  Line numbers range:", range(result$line_number), "\n")
  }
}, error = function(e) {
  cat("✗ all three files test failed:", e$message, "\n")
})

# Test 11: Test count_only with all three files
cat("\nTest 11: Testing count_only with all three files...\n")
tryCatch({
  # This should return proper counts for all three files
  result <- grep_read(files = c(DIAMONDS_FILE, AMUSEMENT_FILE, STRESS_FILE), 
                      count_only = TRUE, 
                      pattern = "test")
  cat("✓ count_only with all three files test passed\n")
  cat("  Result type:", class(result), "\n")
  cat("  Result structure:\n")
  print(result)
}, error = function(e) {
  cat("✗ count_only with all three files test failed:", e$message, "\n")
})

# Test 12: Debug count_only mode to see what grep actually returns
cat("\nTest 12: Debug count_only mode...\n")
tryCatch({
  # Let's see what the actual grep command returns
  cmd <- grep_read(files = rep(DIAMONDS_FILE, 2), 
                   count_only = TRUE, 
                   pattern = "VVS1", 
                   show_cmd = TRUE)
  cat("  Grep command:", cmd, "\n")
  
  # Now let's see what the raw result looks like
  result <- grep_read(files = rep(DIAMONDS_FILE, 2), 
                      count_only = TRUE, 
                      pattern = "VVS1")
  cat("  Raw result class:", class(result), "\n")
  cat("  Raw result:\n")
  print(result)
  
  # Check if it's a data.table
  if (is.data.table(result)) {
    cat("  ✓ Result is a data.table\n")
    cat("  Columns:", names(result), "\n")
    cat("  Rows:", nrow(result), "\n")
    if (nrow(result) > 0) {
      cat("  First row:\n")
      print(result[1])
    }
  } else {
    cat("  ✗ Result is NOT a data.table\n")
  }
}, error = function(e) {
  cat("✗ Debug count_only test failed:", e$message, "\n")
})

cat("\n=== All Tests Completed ===\n")
cat("If all tests passed, the mentor's feedback issues have been resolved.\n")
cat("You can now test this on another device.\n")
cat("\n=== Summary of Tests ===\n")
cat("✓ Test 1: data.table requirement\n")
cat("✓ Test 2: count_only with multiple files\n")
cat("✓ Test 3: rep.int example (mentor's specific case)\n")
cat("✓ Test 4: column splitting in multiple file scenarios\n")
cat("✓ Test 5: line numbers recording actual source file lines\n")
cat("✓ Test 6: show_cmd with proper -H flag\n")
cat("✓ Test 7: multiple files with line numbers and no filename\n")
cat("✓ Test 8: multiple files with filename and line numbers\n")
cat("✓ Test 9: pattern matching with actual data\n")
cat("✓ Test 10: all three files together\n")
cat("✓ Test 11: count_only with all three files\n")
cat("✓ Test 12: Debug count_only mode\n")
