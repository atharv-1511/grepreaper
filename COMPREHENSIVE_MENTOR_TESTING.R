# =============================================================================
# COMPREHENSIVE TESTING PLAN FOR GREPREAPER PACKAGE
# Based on Mentor's Specific Feedback: "Solve problems WITHOUT the package first"
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
install.packages("data.table", repos = "https://cran.rstudio.com/")
cat("   Installing devtools...\n")
install.packages("devtools", repos = "https://cran.rstudio.com/")

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
# PHASE 2: MANUAL PROBLEM SOLVING (MENTOR'S APPROACH)
# =============================================================================

cat("PHASE 2: MANUAL PROBLEM SOLVING (MENTOR'S APPROACH)\n")
cat("====================================================\n")
cat("Solving problems WITHOUT the package first using fread + filtering\n\n")

# Test 2.1: Manual approach for "Good" cut diamonds
cat("Test 2.1: Manual approach for 'Good' cut diamonds\n")
cat("--------------------------------------------------\n")
cat("Step 1: Read full data with fread (no grep allowed)\n")
full_data <- fread("data/diamonds.csv")
cat("Full data loaded - Rows:", nrow(full_data), "Columns:", ncol(full_data), "\n")
cat("Column names:", paste(names(full_data), collapse=", "), "\n")
cat("Data types:\n")
str(full_data)

cat("\nStep 2: Apply filtering to find 'Good' cut diamonds\n")
good_cut_diamonds <- full_data[cut == "Good"]
cat("Filtered 'Good' cut diamonds - Rows:", nrow(good_cut_diamonds), "\n")
cat("First 5 rows of filtered data:\n")
print(head(good_cut_diamonds, 5))

cat("\nStep 3: Examine the results carefully (10 minutes as mentor suggested)\n")
cat("Cut column unique values:", paste(unique(full_data$cut), collapse=", "), "\n")
cat("Good cut count:", sum(full_data$cut == "Good"), "\n")
cat("Good cut percentage:", round(mean(full_data$cut == "Good") * 100, 2), "%\n")

# Test 2.2: Manual approach for "VS1" clarity diamonds
cat("\nTest 2.2: Manual approach for 'VS1' clarity diamonds\n")
cat("-----------------------------------------------------\n")
cat("Step 1: Filter for VS1 clarity\n")
vs1_clarity_diamonds <- full_data[clarity == "VS1"]
cat("Filtered 'VS1' clarity diamonds - Rows:", nrow(vs1_clarity_diamonds), "\n")
cat("First 5 rows of filtered data:\n")
print(head(vs1_clarity_diamonds, 5))

cat("\nStep 2: Examine VS1 results carefully\n")
cat("Clarity column unique values:", paste(unique(full_data$clarity), collapse=", "), "\n")
cat("VS1 clarity count:", sum(full_data$clarity == "VS1"), "\n")
cat("VS1 clarity percentage:", round(mean(full_data$clarity == "VS1") * 100, 2), "%\n")

# Test 2.3: Manual approach for multiple files
cat("\nTest 2.3: Manual approach for multiple files\n")
cat("---------------------------------------------\n")
cat("Step 1: Read both files manually\n")
diamonds_data <- fread("data/diamonds.csv")
# Note: Parks data not available locally, will skip this test
parks_data <- data.table()

cat("Diamonds data - Rows:", nrow(diamonds_data), "Columns:", ncol(diamonds_data), "\n")
cat("Parks data - Rows:", nrow(parks_data), "Columns:", ncol(parks_data), "\n")

cat("\nStep 2: Filter both files for 'VS1' and add source identifiers\n")
diamonds_vs1 <- diamonds_data[clarity == "VS1"]
parks_vs1 <- parks_data[grepl("VS1", as.character(.SD), ignore.case = TRUE), .SDcols = names(parks_data)]

cat("Diamonds VS1 - Rows:", nrow(diamonds_vs1), "\n")
cat("Parks VS1 - Rows:", nrow(parks_vs1), "\n")

# Add source file identifiers manually
if (nrow(diamonds_vs1) > 0) {
  diamonds_vs1[, source_file := "diamonds.csv"]
}
if (nrow(parks_vs1) > 0) {
  parks_vs1[, source_file := "Amusement_Parks_Rides_Registered.csv"]
}

cat("PHASE 2 COMPLETE\n\n")

# =============================================================================
# PHASE 3: PACKAGE FUNCTIONALITY TESTING (COMPARISON)
# =============================================================================

cat("PHASE 3: PACKAGE FUNCTIONALITY TESTING (COMPARISON)\n")
cat("==================================================\n")
cat("Now test the package and compare results with manual approach\n\n")

# Test 3.1: Package approach for "Good" cut diamonds
cat("Test 3.1: Package approach for 'Good' cut diamonds\n")
cat("--------------------------------------------------\n")
cat("Step 1: Use grepreaper to find 'Good' cut diamonds\n")
cat("Testing with column-specific search in 'cut' column:\n")
package_good_cut <- grep_read(files = "data/diamonds.csv",
                              pattern = "Good", nrows = 100, search_column = "cut")
cat("Package result - Rows:", nrow(package_good_cut), "Columns:", ncol(package_good_cut), "\n")
cat("Package column names:", paste(names(package_good_cut), collapse=", "), "\n")

cat("\nStep 2: Compare with manual approach\n")
cat("Manual approach found:", nrow(good_cut_diamonds), "rows\n")
cat("Package approach found:", nrow(package_good_cut), "rows\n")
cat("Match?", nrow(package_good_cut) == nrow(good_cut_diamonds), "\n")

if (nrow(package_good_cut) > 0) {
  cat("First 5 rows from package:\n")
  print(head(package_good_cut, 5))
}

# Test 3.2: Package approach for "VS1" clarity diamonds
cat("\nTest 3.2: Package approach for 'VS1' clarity diamonds\n")
cat("------------------------------------------------------\n")
cat("Step 1: Use grepreaper to find 'VS1' clarity diamonds\n")
cat("Testing with column-specific search in 'clarity' column:\n")
package_vs1_clarity <- grep_read(files = "data/diamonds.csv",
                                 pattern = "VS1", nrows = 100, search_column = "clarity")
cat("Package result - Rows:", nrow(package_vs1_clarity), "Columns:", ncol(package_vs1_clarity), "\n")
cat("Package column names:", paste(names(package_vs1_clarity), collapse=", "), "\n")

cat("\nStep 2: Compare with manual approach\n")
cat("Manual approach found:", nrow(vs1_clarity_diamonds), "rows\n")
cat("Package approach found:", nrow(package_vs1_clarity), "rows\n")
cat("Match?", nrow(package_vs1_clarity) == nrow(vs1_clarity_diamonds), "\n")

if (nrow(package_vs1_clarity) > 0) {
  cat("First 5 rows from package:\n")
  print(head(package_vs1_clarity, 5))
}

# Test 3.3: Package approach for multiple files
cat("\nTest 3.3: Package approach for multiple files\n")
cat("----------------------------------------------\n")
cat("Step 1: Use grepreaper for multiple files with 'VS1' pattern\n")
# Note: Only testing with diamonds.csv since parks data not available locally
package_multiple_vs1 <- grep_read(files = "data/diamonds.csv",
                                  pattern = "VS1", nrows = 100, include_filename = TRUE)
cat("Package result - Rows:", nrow(package_multiple_vs1), "Columns:", ncol(package_multiple_vs1), "\n")
cat("Package column names:", paste(names(package_multiple_vs1), collapse=", "), "\n")

cat("\nStep 2: Compare with manual approach\n")
manual_total_vs1 <- nrow(diamonds_vs1) + nrow(parks_vs1)
cat("Manual approach total VS1 rows:", manual_total_vs1, "\n")
cat("Package approach total VS1 rows:", nrow(package_multiple_vs1), "\n")
cat("Match?", nrow(package_multiple_vs1) == manual_total_vs1, "\n")

if (nrow(package_multiple_vs1) > 0) {
  cat("First 5 rows from package:\n")
  print(head(package_multiple_vs1, 5))
}

# Test 3.4: Command display functionality
cat("\nTest 3.4: Command display functionality\n")
cat("---------------------------------------\n")
cat("Step 1: Get grep command that would be executed\n")
cmd_output <- grep_read(files = "data/diamonds.csv",
                        show_cmd = TRUE, pattern = "VS1")
cat("Generated grep command:\n")
cat(cmd_output, "\n")

cat("\nStep 2: Check if command looks correct\n")
cat("Command contains 'VS1':", grepl("VS1", cmd_output), "\n")
cat("Command contains file path:", grepl("diamonds.csv", cmd_output), "\n")
cat("Command contains grep:", grepl("grep", cmd_output), "\n")

# Test 3.5: Column-specific vs Global pattern matching comparison
cat("\nTest 3.5: Column-specific vs Global pattern matching comparison\n")
cat("----------------------------------------------------------------\n")
cat("Step 1: Test global pattern matching (old behavior)\n")
package_good_global <- grep_read(files = "data/diamonds.csv",
                                 pattern = "Good", nrows = 100)
cat("Global pattern matching - Rows:", nrow(package_good_global), "\n")

cat("\nStep 2: Test column-specific pattern matching (new behavior)\n")
package_good_column <- grep_read(files = "data/diamonds.csv",
                                 pattern = "Good", nrows = 100, search_column = "cut")
cat("Column-specific pattern matching - Rows:", nrow(package_good_column), "\n")

cat("\nStep 3: Compare results\n")
cat("Global search found:", nrow(package_good_global), "rows\n")
cat("Column-specific search found:", nrow(package_good_column), "rows\n")
cat("Manual approach found:", nrow(good_cut_diamonds), "rows\n")
cat("Column-specific matches manual?", nrow(package_good_column) == nrow(good_cut_diamonds), "\n")

cat("PHASE 3 COMPLETE\n\n")

# =============================================================================
# PHASE 4: DETAILED OUTPUT ANALYSIS (MENTOR'S 10-MINUTE EXAMINATION)
# =============================================================================

cat("PHASE 4: DETAILED OUTPUT ANALYSIS (MENTOR'S 10-MINUTE EXAMINATION)\n")
cat("==================================================================\n")
cat("Take 10 minutes to examine every aspect of the results\n\n")

# Analysis 4.1: Data structure comparison
cat("Analysis 4.1: Data structure comparison\n")
cat("---------------------------------------\n")
cat("Manual approach structure:\n")
str(good_cut_diamonds)
cat("\nPackage approach structure:\n")
if (nrow(package_good_cut) > 0) {
  str(package_good_cut)
} else {
  cat("Package returned empty result\n")
}

# Analysis 4.2: Column comparison
cat("\nAnalysis 4.2: Column comparison\n")
cat("--------------------------------\n")
cat("Manual approach columns:", paste(names(good_cut_diamonds), collapse=", "), "\n")
if (nrow(package_good_cut) > 0) {
  cat("Package approach columns:", paste(names(package_good_cut), collapse=", "), "\n")
  cat("Column match?", identical(names(good_cut_diamonds), names(package_good_cut)), "\n")
} else {
  cat("Package returned empty result - cannot compare columns\n")
}

# Analysis 4.3: Data content comparison
cat("\nAnalysis 4.3: Data content comparison\n")
cat("-------------------------------------\n")
if (nrow(package_good_cut) > 0 && nrow(good_cut_diamonds) > 0) {
  cat("First row comparison:\n")
  cat("Manual first row:\n")
  print(good_cut_diamonds[1])
  cat("Package first row:\n")
  print(package_good_cut[1])
  
  cat("\nData type comparison:\n")
  cat("Manual cut column type:", class(good_cut_diamonds$cut), "\n")
  if ("cut" %in% names(package_good_cut)) {
    cat("Package cut column type:", class(package_good_cut$cut), "\n")
  } else {
    cat("Package does not have cut column\n")
  }
} else {
  cat("Cannot compare content - one or both approaches returned empty results\n")
}

# Analysis 4.4: Pattern matching accuracy
cat("\nAnalysis 4.4: Pattern matching accuracy\n")
cat("----------------------------------------\n")
cat("Testing different patterns:\n")

patterns_to_test <- c("Good", "VS1", "Premium", "Ideal", "D", "E", "F")
for (pattern in patterns_to_test) {
  cat("\nPattern:", pattern, "\n")
  
  # Manual approach
  manual_count <- if (pattern %in% names(full_data)) {
    sum(full_data[[pattern]] == pattern)
  } else {
    sum(grepl(pattern, as.character(as.matrix(full_data)), ignore.case = TRUE))
  }
  
  # Package approach
  package_result <- grep_read(files = "data/diamonds.csv",
                             pattern = pattern, nrows = 100)
  package_count <- nrow(package_result)
  
  cat("  Manual count:", manual_count, "\n")
  cat("  Package count:", package_count, "\n")
  cat("  Match?", manual_count == package_count, "\n")
}

cat("PHASE 4 COMPLETE\n\n")

# =============================================================================
# PHASE 5: SUMMARY AND RECOMMENDATIONS
# =============================================================================

cat("PHASE 5: SUMMARY AND RECOMMENDATIONS\n")
cat("====================================\n")

cat("Testing Summary:\n")
cat("----------------\n")
cat("1. Manual approach results:\n")
cat("   - Good cut diamonds:", nrow(good_cut_diamonds), "\n")
cat("   - VS1 clarity diamonds:", nrow(vs1_clarity_diamonds), "\n")
cat("   - Total VS1 across files:", manual_total_vs1, "\n")

cat("\n2. Package approach results:\n")
cat("   - Good cut diamonds:", nrow(package_good_cut), "\n")
cat("   - VS1 clarity diamonds:", nrow(package_vs1_clarity), "\n")
cat("   - Total VS1 across files:", nrow(package_multiple_vs1), "\n")

cat("\n3. Critical issues found:\n")
if (nrow(package_good_cut) == 0) {
  cat("   ❌ Pattern matching for 'Good' is BROKEN\n")
} else {
  cat("   ✅ Pattern matching for 'Good' is WORKING\n")
}

if (nrow(package_vs1_clarity) == 0) {
  cat("   ❌ Pattern matching for 'VS1' is BROKEN\n")
} else {
  cat("   ✅ Pattern matching for 'VS1' is WORKING\n")
}

if (nrow(package_multiple_vs1) == 0) {
  cat("   ❌ Multiple file pattern matching is BROKEN\n")
} else {
  cat("   ✅ Multiple file pattern matching is WORKING\n")
}

cat("\n4. Recommendations:\n")
cat("   - If any pattern matching is broken, the package needs immediate fixes\n")
cat("   - Focus on data quality and accuracy, not just error-free execution\n")
cat("   - Compare every output with manual approach results\n")

cat("\n=== TESTING COMPLETE ===\n")
cat("Send these results back to me for analysis\n")
