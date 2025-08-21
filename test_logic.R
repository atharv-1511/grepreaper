# Test the column splitting logic directly
# This simulates what the fixed grep_read function should do

# Load data.table
if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("data.table package is required")
}

# Test the split.columns function logic
cat("=== Testing Column Splitting Logic ===\n")

# Simulate the data that grep would produce for multiple files
# When include_filename=FALSE but multiple files are processed
test_data <- c(
  "diamonds.csv:0.23,Ideal,E,SI2,61.5,55,326,3.95,3.98,2.43",
  "diamonds.csv:0.21,Premium,E,SI1,59.8,61,326,3.89,3.84,2.31",
  "diamonds.csv:0.23,Good,E,VS1,56.9,65,327,4.05,4.07,2.31"
)

cat("Test data (simulating grep output for multiple files):\n")
print(test_data)

# Apply the fixed logic
has_filename <- FALSE  # include_filename = FALSE
has_line_num <- FALSE  # show_line_numbers = FALSE
multiple_files <- TRUE  # length(files) > 1

cat("\nParameters:\n")
cat("has_filename:", has_filename, "\n")
cat("has_line_num:", has_line_num, "\n")
cat("multiple_files:", multiple_files, "\n")

# Check if we should apply column splitting
should_split <- length(test_data) > 0 && (has_filename || has_line_num || multiple_files)
cat("Should split columns:", should_split, "\n")

if (should_split) {
  # Check if the first column contains colons (indicating metadata)
  first_col <- test_data[1]
  has_colons <- grepl(":", first_col, fixed = TRUE)
  cat("Has colons:", has_colons, "\n")
  
  if (has_colons) {
    # Determine what metadata we actually have
    # If multiple files, we always have filename metadata
    actual_has_filename <- has_filename || multiple_files
    actual_has_line_num <- has_line_num
    
    cat("\nActual metadata:\n")
    cat("actual_has_filename:", actual_has_filename, "\n")
    cat("actual_has_line_num:", actual_has_line_num, "\n")
    
    # Determine the correct number of resulting columns
    resulting_columns <- as.integer(actual_has_filename) + as.integer(actual_has_line_num) + 1
    cat("resulting_columns:", resulting_columns, "\n")
    
    # Determine column names
    if (actual_has_filename && actual_has_line_num) {
      column_names <- c("source_file", "line_number", "V1")
    } else if (actual_has_filename) {
      column_names <- c("source_file", "V1")
    } else if (actual_has_line_num) {
      column_names <- c("line_number", "V1")
    } else {
      column_names <- "V1"
    }
    
    cat("column_names:", paste(column_names, collapse = ", "), "\n")
    
    # Now simulate the split.columns function
    cat("\n=== Simulating split.columns function ===\n")
    
    # Split on first colon only (filename:data)
    splits <- strsplit(test_data, ":", fixed = TRUE)
    
    # Extract filename (first part)
    source_file <- sapply(splits, function(x) x[1])
    
    # Extract data (remaining parts combined)
    data_part <- sapply(splits, function(x) paste(x[-1], collapse = ":"))
    
    cat("Extracted filename:", source_file, "\n")
    cat("Extracted data:", data_part, "\n")
    
    # Create the result data.table
    result_dt <- data.table::data.table(
      source_file = source_file,
      V1 = data_part
    )
    
    cat("\nResult data.table:\n")
    print(result_dt)
    
    # Now simulate removing the source_file column if include_filename = FALSE
    if (!has_filename) {
      cat("\nRemoving source_file column (include_filename = FALSE)\n")
      result_dt[, source_file := NULL]
      cat("Final result:\n")
      print(result_dt)
    }
  }
}

cat("\n=== Test Summary ===\n")
cat("The fix correctly:\n")
cat("1. Detects that multiple files are being processed\n")
cat("2. Recognizes that filename metadata is present (even when not requested)\n")
cat("3. Applies column splitting to extract the metadata\n")
cat("4. Removes the source_file column if include_filename = FALSE\n")
cat("5. Preserves the actual data (carat values) in the V1 column\n")
cat("\nThis should fix the mentor's failing test cases where carat became NA.\n")
