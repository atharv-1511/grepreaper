# Focused test for NA values in carat column
Sys.setenv(PATH = paste("C:/Program Files/Git/usr/bin", Sys.getenv("PATH"), sep=";"))

library(data.table)
library(grepreaper)

cat("=== FOCUSED NA CHECK ===\n\n")

# Test the exact failing case from mentor
result <- grep_read(
  files = c("data/diamonds.csv", "data/diamonds.csv"), 
  pattern = ".*",
  show_line_numbers = FALSE, 
  include_filename = FALSE
)

cat("Result shape:", nrow(result), "rows x", ncol(result), "columns\n")
cat("Column names:", paste(names(result), collapse = ", "), "\n\n")

# Check carat column specifically
if ("carat" %in% names(result)) {
  cat("=== CARAT COLUMN ANALYSIS ===\n")
  cat("Data type:", class(result$carat), "\n")
  cat("First 10 values:", paste(head(result$carat, 10), collapse = ", "), "\n")
  cat("Last 10 values:", paste(tail(result$carat, 10), collapse = ", "), "\n")
  
  # Check for NA values
  na_count <- sum(is.na(result$carat))
  cat("Total NA count:", na_count, "\n")
  cat("Percentage NA:", round(na_count/nrow(result)*100, 2), "%\n")
  
  if (na_count == 0) {
    cat("✅ SUCCESS: No NA values in carat column\n")
  } else {
    cat("❌ FAILURE: Still has NA values in carat column\n")
    
    # Show where NAs are
    na_positions <- which(is.na(result$carat))
    cat("First 10 NA positions:", paste(head(na_positions, 10), collapse = ", "), "\n")
    
    # Check if NAs are at specific positions (like headers)
    if (any(na_positions <= 10)) {
      cat("⚠️  WARNING: NAs found in first 10 rows - possible header issue\n")
    }
  }
  
  # Check data integrity
  cat("\n=== DATA INTEGRITY CHECK ===\n")
  cat("Min carat value:", min(result$carat, na.rm = TRUE), "\n")
  cat("Max carat value:", max(result$carat, na.rm = TRUE), "\n")
  cat("Mean carat value:", mean(result$carat, na.rm = TRUE), "\n")
  
} else {
  cat("❌ ERROR: No carat column found\n")
}

cat("\n=== TEST COMPLETE ===\n")
