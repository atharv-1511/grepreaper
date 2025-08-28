# Test the Fixed Package - search_column functionality
# This script tests if our critical bug fix is working

cat("=== TESTING FIXED PACKAGE ===\n")

# Load the fixed package
library(grepreaper)
library(data.table)

# Test 1: Basic search_column functionality
cat("\n--- Test 1: Basic search_column functionality ---\n")
result <- grep_read(files = "C:\\Users\\Atharv Raskar\\Desktop\\grepreaper\\data\\diabetes.csv",
                    pattern = "150",
                    search_column = "Glucose")
cat("Glucose=150 search - Rows:", nrow(result), "\n")
cat("Expected: 3 rows\n")
cat("Match?", nrow(result) == 3, "\n")

# Test 2: Verify data structure
if (nrow(result) > 0) {
  cat("Columns in result:", paste(names(result), collapse=", "), "\n")
  cat("All glucose values are 150:", all(result$Glucose == 150), "\n")
  cat("First few rows:\n")
  print(head(result, 3))
}

# Test 3: Test other columns
cat("\n--- Test 2: Other column tests ---\n")

# Age = 50
age_result <- grep_read(files = "C:\\Users\\Atharv Raskar\\Desktop\\grepreaper\\data\\diabetes.csv",
                        pattern = "50",
                        search_column = "Age")
cat("Age=50 search - Rows:", nrow(age_result), "\n")
cat("Expected: 8 rows\n")
cat("Match?", nrow(age_result) == 8, "\n")

# BMI = 30
bmi_result <- grep_read(files = "C:\\Users\\Atharv Raskar\\Desktop\\grepreaper\\data\\diabetes.csv",
                        pattern = "30",
                        search_column = "BMI")
cat("BMI=30 search - Rows:", nrow(bmi_result), "\n")
cat("Expected: 7 rows\n")
cat("Match?", nrow(bmi_result) == 7, "\n")

# Outcome = 1
outcome_result <- grep_read(files = "C:\\Users\\Atharv Raskar\\Desktop\\grepreaper\\data\\diabetes.csv",
                            pattern = "1",
                            search_column = "Outcome")
cat("Outcome=1 search - Rows:", nrow(outcome_result), "\n")
cat("Expected: 268 rows\n")
cat("Match?", nrow(outcome_result) == 268, "\n")

# Test 4: Compare with manual filtering
cat("\n--- Test 3: Comparison with manual filtering ---\n")

# Manual filtering
diabetes_data <- fread("C:\\Users\\Atharv Raskar\\Desktop\\grepreaper\\data\\diabetes.csv")
manual_glucose_150 <- diabetes_data[Glucose == 150]
manual_age_50 <- diabetes_data[Age == 50]
manual_bmi_30 <- diabetes_data[BMI == 30]
manual_outcome_1 <- diabetes_data[Outcome == 1]

cat("Manual vs Package comparison:\n")
cat("Glucose=150:", nrow(manual_glucose_150), "vs", nrow(result), "→", nrow(manual_glucose_150) == nrow(result), "\n")
cat("Age=50:", nrow(manual_age_50), "vs", nrow(age_result), "→", nrow(manual_age_50) == nrow(age_result), "\n")
cat("BMI=30:", nrow(manual_bmi_30), "vs", nrow(bmi_result), "→", nrow(manual_bmi_30) == nrow(bmi_result), "\n")
cat("Outcome=1:", nrow(manual_outcome_1), "vs", nrow(outcome_result), "→", nrow(manual_outcome_1) == nrow(outcome_result), "\n")

# Test 5: Global vs Column-specific search
cat("\n--- Test 4: Global vs Column-specific search ---\n")

# Global search (old behavior)
global_150 <- grep_read(files = "C:\\Users\\Atharv Raskar\\Desktop\\grepreaper\\data\\diabetes.csv",
                        pattern = "150")
cat("Global search for '150':", nrow(global_150), "rows\n")

# Column-specific search (new behavior)
column_glucose_150 <- grep_read(files = "C:\\Users\\Atharv Raskar\\Desktop\\grepreaper\\data\\diabetes.csv",
                                pattern = "150",
                                search_column = "Glucose")
cat("Column-specific glucose=150:", nrow(column_glucose_150), "rows\n")

cat("Global vs Column-specific difference:", nrow(global_150) - nrow(column_glucose_150), "rows\n")
cat("This shows how many false positives global search would return!\n")

# Test 6: Final verification
cat("\n--- Test 5: Final verification ---\n")
all_tests_passed <- all(
  nrow(result) == 3,
  nrow(age_result) == 8,
  nrow(bmi_result) == 7,
  nrow(outcome_result) == 268,
  nrow(global_150) > nrow(column_glucose_150)
)

cat("All tests passed:", all_tests_passed, "\n")
if (all_tests_passed) {
  cat("🎉 SUCCESS: search_column parameter is now working correctly!\n")
  cat("✅ Package is operational and accurate!\n")
} else {
  cat("❌ FAILURE: Some tests failed. Package still has issues.\n")
}
