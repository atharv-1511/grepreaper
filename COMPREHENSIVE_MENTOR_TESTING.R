# =============================================================================
# COMPREHENSIVE TESTING PLAN FOR GREPREAPER PACKAGE
# Based on Mentor's Specific Feedback and Requirements
# =============================================================================
#
# Instructions:
# 1. Copy this entire file to another device
# 2. Open R console and source this file: source("COMPREHENSIVE_MENTOR_TESTING.R")
# 3. Run each phase systematically
# 4. Record all outputs and send back to me
#
# =============================================================================

cat("=== GREPREAPER PACKAGE COMPREHENSIVE TESTING ===\n")
cat("Testing based on mentor's specific feedback\n")
cat("=============================================\n\n")

# =============================================================================
# PHASE 1: PACKAGE INSTALLATION & LOADING
# =============================================================================

cat("PHASE 1: PACKAGE INSTALLATION & LOADING\n")
cat("========================================\n")

# 1. Install required packages
cat("1. Installing required packages...\n")
cat("   Installing data.table...\n")
install.packages("data.table")
cat("   Installing devtools...\n")
install.packages("devtools")

# 2. Install grepreaper from GitHub
cat("2. Installing grepreaper from GitHub...\n")
devtools::install_github("atharv-1511/grepreaper")

# 3. Load libraries
cat("3. Loading libraries...\n")
library(data.table)
library(grepreaper)

# 4. Check package help
cat("4. Checking package help...\n")
help(grep_read)

cat("PHASE 1 COMPLETE\n\n")

# =============================================================================
# PHASE 2: BASIC FILE READING TESTS (MENTOR'S CORE CONCERNS)
# =============================================================================

cat("PHASE 2: BASIC FILE READING TESTS\n")
cat("==================================\n")

# Test 2.1: Basic file reading
cat("Test 2.1: Basic file reading\n")
cat("-----------------------------\n")
result <- grep_read(files = "C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv")
cat("Basic reading - Rows:", nrow(result), "Columns:", ncol(result), "\n")
cat("Column names:", paste(names(result), collapse=", "), "\n\n")

# Test 2.2: Reading with nrows limit
cat("Test 2.2: Reading with nrows limit\n")
cat("----------------------------------\n")
result <- grep_read(files = "C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", nrows = 100)
cat("Nrows limit - Rows:", nrow(result), "Columns:", ncol(result), "\n\n")

# Test 2.3: Reading with empty pattern (direct file read)
cat("Test 2.3: Reading with empty pattern (direct file read)\n")
cat("------------------------------------------------------\n")
result <- grep_read(files = "C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", nrows = 100, pattern = "")
cat("Empty pattern - Rows:", nrow(result), "Columns:", ncol(result), "\n\n")

# Test 2.4: Pattern matching (case-insensitive)
cat("Test 2.4: Pattern matching (case-insensitive)\n")
cat("---------------------------------------------\n")
result <- grep_read(files = "C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", nrows = 100, pattern = "VS1")
cat("Pattern VS1 - Rows:", nrow(result), "Columns:", ncol(result), "\n")

result <- grep_read(files = "C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", nrows = 100, pattern = "Good")
cat("Pattern Good - Rows:", nrow(result), "Columns:", ncol(result), "\n")

result <- grep_read(files = "C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", nrows = 100, pattern = "Ideal")
cat("Pattern Ideal - Rows:", nrow(result), "Columns:", ncol(result), "\n\n")

# Test 2.5: Command display
cat("Test 2.5: Command display\n")
cat("-------------------------\n")
cmd <- grep_read(files = "C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", show_cmd = TRUE, nrows = 100, pattern = "VS1")
cat("Command:", cmd, "\n\n")

cat("PHASE 2 COMPLETE\n\n")

# =============================================================================
# PHASE 3: MULTIPLE FILES TESTS (MENTOR'S SPECIFIC FOCUS)
# =============================================================================

cat("PHASE 3: MULTIPLE FILES TESTS\n")
cat("==============================\n")

# Test 3.1: Multiple files without metadata
cat("Test 3.1: Multiple files without metadata\n")
cat("-----------------------------------------\n")
result <- grep_read(files = c("C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", "C:\\Users\\Atharv Raskar\\Downloads\\Amusement_Parks_Rides_Registered.csv"), 
                    show_line_numbers = FALSE, include_filename = FALSE)
cat("Multiple files no metadata - Rows:", nrow(result), "Columns:", ncol(result), "\n\n")

# Test 3.2: Multiple files without metadata, with nrows limit
cat("Test 3.2: Multiple files without metadata, with nrows limit\n")
cat("-----------------------------------------------------------\n")
result <- grep_read(files = c("C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", "C:\\Users\\Atharv Raskar\\Downloads\\Amusement_Parks_Rides_Registered.csv"), 
                    show_line_numbers = FALSE, include_filename = FALSE, nrows = 100)
cat("Multiple files no metadata + nrows - Rows:", nrow(result), "Columns:", ncol(result), "\n\n")

# Test 3.3: Multiple files without metadata, with nrows limit and empty pattern
cat("Test 3.3: Multiple files without metadata, with nrows limit and empty pattern\n")
cat("-------------------------------------------------------------------------\n")
result <- grep_read(files = c("C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", "C:\\Users\\Atharv Raskar\\Downloads\\Amusement_Parks_Rides_Registered.csv"), 
                    show_line_numbers = FALSE, include_filename = FALSE, nrows = 100, pattern = "")
cat("Multiple files no metadata + nrows + empty pattern - Rows:", nrow(result), "Columns:", ncol(result), "\n\n")

# Test 3.4: Multiple files without metadata, with nrows limit and pattern
cat("Test 3.4: Multiple files without metadata, with nrows limit and pattern\n")
cat("--------------------------------------------------------------------\n")
result <- grep_read(files = c("C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", "C:\\Users\\Atharv Raskar\\Downloads\\Amusement_Parks_Rides_Registered.csv"), 
                    show_line_numbers = FALSE, include_filename = FALSE, nrows = 100, pattern = "VS1")
cat("Multiple files no metadata + nrows + pattern - Rows:", nrow(result), "Columns:", ncol(result), "\n")
cat("First 2 rows:\n")
print(result[1:2,])
cat("\n")

cat("PHASE 3 COMPLETE\n\n")

# =============================================================================
# PHASE 4: LINE NUMBERS TESTS (MENTOR'S CRITICAL CONCERN)
# =============================================================================

cat("PHASE 4: LINE NUMBERS TESTS\n")
cat("===========================\n")

# Test 4.1: Multiple files with line numbers but no filenames
cat("Test 4.1: Multiple files with line numbers but no filenames\n")
cat("----------------------------------------------------------\n")
result <- grep_read(files = c("C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", "C:\\Users\\Atharv Raskar\\Downloads\\Amusement_Parks_Rides_Registered.csv"), 
                    show_line_numbers = TRUE, include_filename = FALSE)
cat("Multiple files + line numbers no filenames - Rows:", nrow(result), "Columns:", ncol(result), "\n")
cat("Columns:", paste(names(result), collapse=", "), "\n\n")

# Test 4.2: Multiple files with line numbers but no filenames, with nrows limit
cat("Test 4.2: Multiple files with line numbers but no filenames, with nrows limit\n")
cat("-------------------------------------------------------------------------\n")
result <- grep_read(files = c("C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", "C:\\Users\\Atharv Raskar\\Downloads\\Amusement_Parks_Rides_Registered.csv"), 
                    show_line_numbers = TRUE, include_filename = FALSE, nrows = 100)
cat("Multiple files + line numbers no filenames + nrows - Rows:", nrow(result), "Columns:", ncol(result), "\n\n")

# Test 4.3: Multiple files with line numbers but no filenames, with nrows limit and empty pattern
cat("Test 4.3: Multiple files with line numbers but no filenames, with nrows limit and empty pattern\n")
cat("------------------------------------------------------------------------------------------------\n")
result <- grep_read(files = c("C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", "C:\\Users\\Atharv Raskar\\Downloads\\Amusement_Parks_Rides_Registered.csv"), 
                    show_line_numbers = TRUE, include_filename = FALSE, nrows = 100, pattern = "")
cat("Multiple files + line numbers no filenames + nrows + empty pattern - Rows:", nrow(result), "Columns:", ncol(result), "\n\n")

# Test 4.4: Multiple files with line numbers but no filenames, with nrows limit and pattern
cat("Test 4.4: Multiple files with line numbers but no filenames, with nrows limit and pattern\n")
cat("----------------------------------------------------------------------------------------\n")
result <- grep_read(files = c("C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", "C:\\Users\\Atharv Raskar\\Downloads\\Amusement_Parks_Rides_Registered.csv"), 
                    show_line_numbers = TRUE, include_filename = FALSE, nrows = 100, pattern = "VS1")
cat("Multiple files + line numbers no filenames + nrows + pattern - Rows:", nrow(result), "Columns:", ncol(result), "\n")
cat("First 2 rows:\n")
print(result[1:2,])
cat("\n")

cat("PHASE 4 COMPLETE\n\n")

# =============================================================================
# PHASE 5: FILENAME TESTS (MENTOR'S METADATA FOCUS)
# =============================================================================

cat("PHASE 5: FILENAME TESTS\n")
cat("=======================\n")

# Test 5.1: Multiple files with filenames but no line numbers
cat("Test 5.1: Multiple files with filenames but no line numbers\n")
cat("-----------------------------------------------------------\n")
result <- grep_read(files = c("C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", "C:\\Users\\Atharv Raskar\\Downloads\\Amusement_Parks_Rides_Registered.csv"), 
                    show_line_numbers = FALSE, include_filename = TRUE)
cat("Multiple files + filenames no line numbers - Rows:", nrow(result), "Columns:", ncol(result), "\n")
cat("Columns:", paste(names(result), collapse=", "), "\n\n")

# Test 5.2: Multiple files with filenames but no line numbers, with nrows limit
cat("Test 5.2: Multiple files with filenames but no line numbers, with nrows limit\n")
cat("-------------------------------------------------------------------------\n")
result <- grep_read(files = c("C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", "C:\\Users\\Atharv Raskar\\Downloads\\Amusement_Parks_Rides_Registered.csv"), 
                    show_line_numbers = FALSE, include_filename = TRUE, nrows = 100)
cat("Multiple files + filenames no line numbers + nrows - Rows:", nrow(result), "Columns:", ncol(result), "\n\n")

# Test 5.3: Multiple files with filenames but no line numbers, with nrows limit and empty pattern
cat("Test 5.3: Multiple files with filenames but no line numbers, with nrows limit and empty pattern\n")
cat("------------------------------------------------------------------------------------------------\n")
result <- grep_read(files = c("C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", "C:\\Users\\Atharv Raskar\\Downloads\\Amusement_Parks_Rides_Registered.csv"), 
                    show_line_numbers = FALSE, include_filename = TRUE, nrows = 100, pattern = "")
cat("Multiple files + filenames no line numbers + nrows + empty pattern - Rows:", nrow(result), "Columns:", ncol(result), "\n\n")

# Test 5.4: Multiple files with filenames but no line numbers, with nrows limit and pattern
cat("Test 5.4: Multiple files with filenames but no line numbers, with nrows limit and pattern\n")
cat("----------------------------------------------------------------------------------------\n")
result <- grep_read(files = c("C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", "C:\\Users\\Atharv Raskar\\Downloads\\Amusement_Parks_Rides_Registered.csv"), 
                    show_line_numbers = FALSE, include_filename = TRUE, nrows = 100, pattern = "VS1")
cat("Multiple files + filenames no line numbers + nrows + pattern - Rows:", nrow(result), "Columns:", ncol(result), "\n")
cat("First 2 rows:\n")
print(result[1:2,])
cat("\n")

cat("PHASE 5 COMPLETE\n\n")

# =============================================================================
# PHASE 6: COMPLETE METADATA TESTS (MENTOR'S FULL FUNCTIONALITY TEST)
# =============================================================================

cat("PHASE 6: COMPLETE METADATA TESTS\n")
cat("=================================\n")

# Test 6.1: Multiple files with both filenames and line numbers
cat("Test 6.1: Multiple files with both filenames and line numbers\n")
cat("------------------------------------------------------------\n")
result <- grep_read(files = c("C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", "C:\\Users\\Atharv Raskar\\Downloads\\Amusement_Parks_Rides_Registered.csv"), 
                    show_line_numbers = TRUE, include_filename = TRUE)
cat("Multiple files + both metadata - Rows:", nrow(result), "Columns:", ncol(result), "\n")
cat("Columns:", paste(names(result), collapse=", "), "\n\n")

# Test 6.2: Multiple files with both filenames and line numbers, with nrows limit
cat("Test 6.2: Multiple files with both filenames and line numbers, with nrows limit\n")
cat("---------------------------------------------------------------------------\n")
result <- grep_read(files = c("C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", "C:\\Users\\Atharv Raskar\\Downloads\\Amusement_Parks_Rides_Registered.csv"), 
                    show_line_numbers = TRUE, include_filename = TRUE, nrows = 100)
cat("Multiple files + both metadata + nrows - Rows:", nrow(result), "Columns:", ncol(result), "\n\n")

# Test 6.3: Multiple files with both filenames and line numbers, with nrows limit and empty pattern
cat("Test 6.3: Multiple files with both filenames and line numbers, with nrows limit and empty pattern\n")
cat("------------------------------------------------------------------------------------------------\n")
result <- grep_read(files = c("C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", "C:\\Users\\Atharv Raskar\\Downloads\\Amusement_Parks_Rides_Registered.csv"), 
                    show_line_numbers = TRUE, include_filename = TRUE, nrows = 100, pattern = "")
cat("Multiple files + both metadata + nrows + empty pattern - Rows:", nrow(result), "Columns:", ncol(result), "\n\n")

# Test 6.4: Multiple files with both filenames and line numbers, with nrows limit and pattern
cat("Test 6.4: Multiple files with both filenames and line numbers, with nrows limit and pattern\n")
cat("----------------------------------------------------------------------------------------\n")
result <- grep_read(files = c("C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", "C:\\Users\\Atharv Raskar\\Downloads\\Amusement_Parks_Rides_Registered.csv"), 
                    show_line_numbers = TRUE, include_filename = TRUE, nrows = 100, pattern = "VS1")
cat("Multiple files + both metadata + nrows + pattern - Rows:", nrow(result), "Columns:", ncol(result), "\n")
cat("First 2 rows:\n")
print(result[1:2,])
cat("\n")

cat("PHASE 6 COMPLETE\n\n")

# =============================================================================
# PHASE 7: DATA INTEGRITY TESTS (MENTOR'S QUALITY CHECK)
# =============================================================================

cat("PHASE 7: DATA INTEGRITY TESTS\n")
cat("==============================\n")

# Test 7.1: Check for data corruption
cat("Test 7.1: Check for data corruption\n")
cat("-----------------------------------\n")
result <- grep_read(files = "C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", nrows = 1000, pattern = "")
cat("Data integrity check - Rows:", nrow(result), "Columns:", ncol(result), "\n")

# Check for NA values in carat column
if ("carat" %in% names(result)) {
  na_count <- sum(is.na(result$carat))
  na_percentage <- round((na_count / nrow(result)) * 100, 2)
  cat("NA values in carat column:", na_count, "(", na_percentage, "%)\n")
  
  if (na_percentage == 0) {
    cat("🎉 PERFECT: No data corruption detected!\n")
  } else {
    cat("❌ WARNING: Data corruption detected\n")
  }
} else {
  cat("❌ ERROR: carat column not found\n")
}
cat("\n")

# Test 7.2: Check line number sequence
cat("Test 7.2: Check line number sequence\n")
cat("------------------------------------\n")
result <- grep_read(files = c("C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", "C:\\Users\\Atharv Raskar\\Downloads\\Amusement_Parks_Rides_Registered.csv"), 
                    show_line_numbers = TRUE, include_filename = TRUE, nrows = 100)
cat("Line number check - Rows:", nrow(result), "Columns:", ncol(result), "\n")

# Check if line numbers restart for each file
if ("line_number" %in% names(result) && "source_file" %in% names(result)) {
  unique_files <- unique(result$source_file)
  cat("Files found:", paste(unique_files, collapse=", "), "\n")
  
  for (file in unique_files) {
    file_data <- result[result$source_file == file, ]
    cat("File:", file, "- Line numbers:", min(file_data$line_number), "to", max(file_data$line_number), "\n")
  }
} else {
  cat("❌ ERROR: Required columns not found\n")
}
cat("\n")

cat("PHASE 7 COMPLETE\n\n")

# =============================================================================
# FINAL SUMMARY
# =============================================================================

cat("=== TESTING COMPLETE ===\n")
cat("All phases have been executed.\n")
cat("Please send me the complete output from this testing session.\n")
cat("Include any error messages, warnings, or unexpected behavior.\n")
cat("=============================================\n")
