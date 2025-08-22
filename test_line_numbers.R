# Test for multiple files with line numbers but no filename
Sys.setenv(PATH = paste("C:/Program Files/Git/usr/bin", Sys.getenv("PATH"), sep=";"))

library(data.table)
library(grepreaper)

cat("=== TEST: MULTIPLE FILES WITH LINE NUMBERS, NO FILENAME ===\n\n")

# Test the second failing case from mentor
result <- grep_read(
  files = c("data/diamonds.csv", "data/diamonds.csv"), 
  pattern = ".*",
  show_line_numbers = TRUE, 
  include_filename = FALSE
)

cat("Result shape:", nrow(result), "rows x", ncol(result), "columns\n")
cat("Column names:", paste(names(result), collapse = ", "), "\n\n")

# Check if line_number column exists and is correct
if ("line_number" %in% names(result)) {
  cat("=== LINE NUMBER ANALYSIS ===\n")
  cat("Data type:", class(result$line_number), "\n")
  cat("First 10 line numbers:", paste(head(result$line_number, 10), collapse = ", "), "\n")
  cat("Last 10 line numbers:", paste(tail(result$line_number, 10), collapse = ", "), "\n")
  
  # Check for NA values in line numbers
  na_count_line <- sum(is.na(result$line_number))
  cat("NA count in line_number:", na_count_line, "\n")
  
  # Check if line numbers are sequential
  line_diff <- diff(result$line_number)
  if (all(line_diff == 1)) {
    cat("✅ SUCCESS: Line numbers are sequential\n")
  } else {
    cat("❌ FAILURE: Line numbers are not sequential\n")
    cat("First few differences:", paste(head(line_diff, 10), collapse = ", "), "\n")
  }
  
} else {
  cat("❌ ERROR: No line_number column found\n")
}

# Check carat column integrity
if ("carat" %in% names(result)) {
  cat("\n=== CARAT COLUMN CHECK ===\n")
  na_count_carat <- sum(is.na(result$carat))
  cat("NA count in carat:", na_count_carat, "\n")
  
  if (na_count_carat == 0) {
    cat("✅ SUCCESS: No NA values in carat column\n")
  } else {
    cat("❌ FAILURE: Still has NA values in carat column\n")
  }
  
  # Check data integrity
  cat("Min carat value:", min(result$carat, na.rm = TRUE), "\n")
  cat("Max carat value:", max(result$carat, na.rm = TRUE), "\n")
  cat("Mean carat value:", mean(result$carat, na.rm = TRUE), "\n")
  
} else {
  cat("❌ ERROR: No carat column found\n")
}

cat("\n=== TEST COMPLETE ===\n")
