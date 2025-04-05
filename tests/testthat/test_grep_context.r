library(testthat)
library(data.table)
context("grep_context function tests")

# Create a test file with numbered lines
create_test_file <- function(file_path) {
  lines <- c(
    "Line 1: This is a test file",
    "Line 2: It contains multiple lines",
    "Line 3: Some lines contain the pattern we're looking for",
    "Line 4: While others don't have the pattern",
    "Line 5: The pattern appears again here",
    "Line 6: This is the last line"
  )
  writeLines(lines, file_path)
  return(file_path)
}

test_that("grep_context basic functionality", {
  # Skip tests if grep is not available
  skip_if_not(check_grep_availability(), "grep command not available")
  
  # Create temporary test file
  temp_file <- tempfile(fileext = ".txt")
  on.exit(unlink(temp_file), add = TRUE)
  
  create_test_file(temp_file)
  
  # Test basic pattern matching with no context
  result <- grep_context(temp_file, "pattern")
  expect_true(is.character(result))
  expect_equal(length(result), 2) # Two lines with "pattern"
  
  # Test with before context
  result <- grep_context(temp_file, "pattern", before = 1)
  expect_equal(length(result), 5) # 2 matches + 2 before lines + 1 separator
  
  # Test with after context
  result <- grep_context(temp_file, "pattern", after = 1)
  expect_equal(length(result), 5) # 2 matches + 2 after lines + 1 separator
  
  # Test with both before and after context
  result <- grep_context(temp_file, "pattern", before = 1, after = 1)
  expect_equal(length(result), 7) # 2 matches + 2 before + 2 after + 1 separator
  
  # Test with case sensitivity
  result <- grep_context(temp_file, "PATTERN", ignore_case = FALSE)
  expect_equal(length(result), 0)
  result <- grep_context(temp_file, "PATTERN", ignore_case = TRUE)
  expect_equal(length(result), 2)
  
  # Test with invert parameter
  result <- grep_context(temp_file, "pattern", invert = TRUE)
  expect_equal(length(result), 4) # 4 lines without "pattern"
  
  # Test as data.table
  result <- grep_context(temp_file, "pattern", as_data_table = TRUE)
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 2)
  expect_true(all(c("file", "line_num", "content", "match_type") %in% names(result)))
  expect_true(all(result$match_type == "match"))
  
  # Test as data.table with context
  result <- grep_context(temp_file, "pattern", before = 1, after = 1, as_data_table = TRUE)
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 6) # 2 matches + 2 before + 2 after (no separators in data.table)
  expect_equal(sum(result$match_type == "match"), 2)
  expect_equal(sum(result$match_type == "before"), 2)
  expect_equal(sum(result$match_type == "after"), 2)
  
  # Test show_cmd parameter
  cmd <- grep_context(temp_file, "pattern", before = 1, after = 1, show_cmd = TRUE)
  expect_true(is.character(cmd))
  expect_true(grepl("grep.*-B 1.*-A 1", cmd))
})

test_that("grep_context handles file errors gracefully", {
  # Skip tests if grep is not available
  skip_if_not(check_grep_availability(), "grep command not available")
  
  # Test with non-existent file
  result <- grep_context("nonexistent_file.txt", "pattern")
  expect_true(is.character(result))
  expect_equal(length(result), 0)
  
  result <- grep_context("nonexistent_file.txt", "pattern", as_data_table = TRUE)
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 0)
}) 