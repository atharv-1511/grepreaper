# ============================================================================
# TEST SCRIPT FOR MENTOR'S SPECIFIC FEEDBACK ISSUES
# ============================================================================
# This script tests the exact issues highlighted by the mentor:
# 1. Column splitting issue with multiple files (no filename, no line numbers)
# 2. Line number recording should show actual source file lines, not sequential rows
# ============================================================================

cat("=== TESTING MENTOR'S SPECIFIC FEEDBACK ISSUES ===\n\n")

# Source the functions
source("R/utils.r")
source("R/grep_read.r")

# Test with local dataset
DIAMONDS_FILE <- "data/diamonds.csv"

cat("=== ISSUE 1: Column Splitting with Multiple Files (No Filename, No Line Numbers) ===\n")
cat("Testing: grep_read(files = c(diamonds.csv, diamonds.csv), show_line_numbers = F, include_filename = F)\n\n")

tryCatch({
  result <- grep_read(files = c(DIAMONDS_FILE, DIAMONDS_FILE), 
                      show_line_numbers = FALSE, 
                      include_filename = FALSE)
  
  cat("Result structure:\n")
  cat("Number of rows:", nrow(result), "\n")
  cat("Number of columns:", ncol(result), "\n")
  cat("Column names:", paste(names(result), collapse = ", "), "\n")
  
  if (nrow(result) > 0) {
    cat("\nFirst few rows:\n")
    print(head(result, 3))
  }
  
  # Check if columns are properly split
  if (ncol(result) > 1) {
    cat("\n✓ Column splitting appears to be working\n")
  } else {
    cat("\n✗ Column splitting FAILED - only one column found\n")
  }
  
}, error = function(e) {
  cat("✗ ERROR:", e$message, "\n")
})

cat("\n", paste(rep("=", 50), collapse=""), "\n\n")

cat("=== ISSUE 2: Line Number Recording (Should Show Actual Source File Lines) ===\n")
cat("Testing: grep_read(files = c(diamonds.csv, diamonds.csv), show_line_numbers = T, include_filename = F)\n\n")

tryCatch({
  result <- grep_read(files = c(DIAMONDS_FILE, DIAMONDS_FILE), 
                      show_line_numbers = TRUE, 
                      include_filename = FALSE)
  
  cat("Result structure:\n")
  cat("Number of rows:", nrow(result), "\n")
  cat("Number of columns:", ncol(result), "\n")
  cat("Column names:", paste(names(result), collapse = ", "), "\n")
  
  if (nrow(result) > 0) {
    cat("\nFirst few rows:\n")
    print(head(result, 3))
    
    # Check line numbers
    if ("line_number" %in% names(result)) {
      cat("\nLine number analysis:\n")
      cat("Line numbers found:", paste(head(result$line_number, 10), collapse = ", "), "...\n")
      
      # Check if line numbers are sequential (1,2,3...) or actual file lines
      first_10_lines <- head(result$line_number, 10)
      if (all(first_10_lines == 1:10)) {
        cat("✗ Line numbers are sequential (1,2,3...) - should be actual source file lines\n")
      } else {
        cat("✓ Line numbers appear to be actual source file lines\n")
      }
    } else {
      cat("✗ No line_number column found\n")
    }
  }
  
}, error = function(e) {
  cat("✗ ERROR:", e$message, "\n")
})

cat("\n", paste(rep("=", 50), collapse=""), "\n\n")

cat("=== SUMMARY ===\n")
cat("The mentor's feedback indicates two main issues:\n")
cat("1. Column splitting not working properly with multiple files\n")
cat("2. Line numbers showing sequential row numbers instead of actual source file lines\n")
cat("\nThese issues need to be fixed in the grep_read function.\n")
