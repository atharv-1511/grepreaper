## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = grepreaper::check_grep_availability()$available
)

## ----load-packages------------------------------------------------------------
library(grepreaper)
library(data.table)

## ----basic-usage--------------------------------------------------------------
# Create a sample CSV file
sample_data <- data.frame(
  id = 1:5,
  name = c("Alice", "Bob", "Charlie", "Diana", "Eve"),
  value = c(10.5, 20.3, 15.7, 8.9, 12.1)
)
write.csv(sample_data, "sample.csv", row.names = FALSE)

# Read the entire file
result <- grep_read(files = "sample.csv")
print(result)

## ----pattern-filtering--------------------------------------------------------
# Filter rows containing "Alice"
alice_data <- grep_read(files = "sample.csv", pattern = "Alice")
print(alice_data)

# Filter rows with values greater than 15 (using regex)
high_values <- grep_read(
  files = "sample.csv", 
  pattern = "1[5-9]\\.[0-9]"
)
print(high_values)

## ----multiple-files-----------------------------------------------------------
# Create multiple files
write.csv(sample_data[1:3, ], "file1.csv", row.names = FALSE)
write.csv(sample_data[3:5, ], "file2.csv", row.names = FALSE)

# Read from multiple files
multi_result <- grep_read(files = c("file1.csv", "file2.csv"))
print(multi_result)

## ----directory-selection------------------------------------------------------
# Create a subdirectory and move files
dir.create("data_files", showWarnings = FALSE)
file.copy(c("file1.csv", "file2.csv"), "data_files/")

# Read all CSV files in a directory
dir_result <- grep_read(
  path = "data_files", 
  file_pattern = "\\.csv$"
)
print(dir_result)

## ----line-numbers-------------------------------------------------------------
# Show line numbers
with_lines <- grep_read(files = "sample.csv", show_line_numbers = TRUE)
print(with_lines)

# Include filename when reading multiple files
with_files <- grep_read(
  files = c("file1.csv", "file2.csv"), 
  include_filename = TRUE
)
print(with_files)

# Both line numbers and filenames
with_both <- grep_read(
  files = c("file1.csv", "file2.csv"), 
  show_line_numbers = TRUE, 
  include_filename = TRUE
)
print(with_both)

## ----only-matching------------------------------------------------------------
# Extract only the matching parts
# Note: Use fixed=TRUE for literal string matching
matches <- grep_read(
  files = "sample.csv", 
  pattern = "Alice", 
  only_matching = TRUE, 
  fixed = TRUE
)
print(matches)

# Extract numeric values (using regex)
numbers <- grep_read(
  files = "sample.csv", 
  pattern = "[0-9]+\\.[0-9]+", 
  only_matching = TRUE
)
print(numbers)

## ----count-only---------------------------------------------------------------
# Count matches per file
counts <- grep_read(
  files = c("file1.csv", "file2.csv"), 
  pattern = "Charlie", 
  count_only = TRUE
)
print(counts)

## ----column-structure---------------------------------------------------------
# Demonstrate the column splitting
complex_result <- grep_read(
  files = c("file1.csv", "file2.csv"),
  show_line_numbers = TRUE,
  include_filename = TRUE
)
print(complex_result)

## ----manual-splitting---------------------------------------------------------
# Get the raw grep output
cmd <- grep_read(
  files = c("file1.csv", "file2.csv"),
  show_line_numbers = TRUE,
  include_filename = TRUE,
  show_cmd = TRUE
)
print(cmd)

# Read the raw data
raw_data <- fread(cmd = cmd)
print(raw_data)

# Manual column splitting using mentor's approach
split_columns <- function(x, column_names = NA, split = ":", fixed = TRUE) {
  the_pieces <- strsplit(x = x, split = split, fixed = fixed)
  new_columns <- rbindlist(lapply(the_pieces, function(y) {
    as.data.table(t(y))
  }))
  
  if (!is.na(column_names[1])) {
    setnames(x = new_columns, old = names(new_columns), new = column_names)
  }
  new_columns
}

# Apply the splitting
raw_data[, c("V1", "V2", "V3") := split_columns(
  x = get(names(raw_data)[1])
)]
print(raw_data)

# Remove the original column and rename
raw_data[, eval(names(raw_data)[1]) := NULL]
setnames(
  raw_data, 
  old = c("V1", "V2", "V3"), 
  new = c("file", "line", "data")
)
print(raw_data)

## ----header-handling----------------------------------------------------------
# Create a file with duplicate headers
header_data <- rbind(
  names(sample_data),  # Header row
  sample_data,
  names(sample_data),  # Duplicate header
  sample_data
)
write.csv(header_data, "header_test.csv", row.names = FALSE)

# Read with automatic header removal
clean_result <- grep_read(files = "header_test.csv")
print(clean_result)

## ----type-restoration---------------------------------------------------------
# Create data with mixed types
mixed_data <- data.frame(
  numeric_col = c(1.5, 2.7, 3.1),
  integer_col = c(1L, 2L, 3L),
  character_col = c("a", "b", "c"),
  factor_col = factor(c("low", "medium", "high"))
)
write.csv(mixed_data, "mixed_types.csv", row.names = FALSE)

# Read and check types
typed_result <- grep_read(files = "mixed_types.csv")
print(typed_result)
str(typed_result)

## ----pattern-notes------------------------------------------------------------
# This will match "3894" because "." is a regex metacharacter
regex_result <- grep_read(
  files = "sample.csv", 
  pattern = "3.94", 
  only_matching = TRUE
)
print(regex_result)

# This will only match the literal "3.94"
fixed_result <- grep_read(
  files = "sample.csv", 
  pattern = "3.94", 
  only_matching = TRUE, 
  fixed = TRUE
)
print(fixed_result)

## ----error-handling-----------------------------------------------------------
# Try to read a non-existent file
tryCatch({
  grep_read(files = "nonexistent.csv")
}, error = function(e) {
  cat("Error:", e$message, "\n")
})

## ----help---------------------------------------------------------------------
# Get function documentation
?grep_read

# Check grep availability
grepreaper::check_grep_availability()

## ----citation-----------------------------------------------------------------
citation("grepreaper")

## ----cleanup, include=FALSE---------------------------------------------------
# Clean up temporary files
unlink(c("sample.csv", "file1.csv", "file2.csv", "header_test.csv", "mixed_types.csv"))
unlink("data_files", recursive = TRUE)