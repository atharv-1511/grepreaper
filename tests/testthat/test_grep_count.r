library(testthat)
context("grep_count function tests")

# Create a temporary test file
create_test_file <- function(file_path) {
  lines <- c(
    "This is line one with pattern A",
    "This is line two with pattern B",
    "This is line three with pattern A again",
    "This is line four with pattern C",
    "This is line five with pattern B again"
  )
  writeLines(lines, file_path)
  return(file_path)
}

# Setup test data
test_that("grep_count basic functionality", {
  # Skip tests if grep is not available
  skip_if_not(check_grep_availability(), "grep command not available")
  
  # Create temporary test files
  temp_file1 <- tempfile(fileext = ".txt")
  temp_file2 <- tempfile(fileext = ".txt")
  on.exit(unlink(c(temp_file1, temp_file2)), add = TRUE)
  
  create_test_file(temp_file1)
  create_test_file(temp_file2)
  
  # Test basic pattern matching
  expect_equal(grep_count(temp_file1, "pattern A"), 2)
  expect_equal(grep_count(temp_file1, "pattern B"), 2)
  expect_equal(grep_count(temp_file1, "pattern D"), 0)
  
  # Test with inverted matching
  expect_equal(grep_count(temp_file1, "pattern A", invert = TRUE), 3)
  
  # Test case sensitivity
  expect_equal(grep_count(temp_file1, "PATTERN A", ignore_case = TRUE), 2)
  expect_equal(grep_count(temp_file1, "PATTERN A", ignore_case = FALSE), 0)
  
  # Test fixed string matching
  expect_equal(grep_count(temp_file1, "pattern.", fixed = TRUE), 0)
  expect_equal(grep_count(temp_file1, "pattern.", fixed = FALSE), 5)
  
  # Test multiple files
  result <- grep_count(c(temp_file1, temp_file2), "pattern A")
  expect_true(is.integer(result))
  expect_equal(length(result), 2)
  expect_equal(sum(result), 4) # 2 matches per file
  
  # Test show_cmd parameter
  cmd <- grep_count(temp_file1, "pattern", show_cmd = TRUE)
  expect_true(is.character(cmd))
  expect_true(grepl("grep.*pattern", cmd))
})

test_that("grep_count handles file errors gracefully", {
  # Skip tests if grep is not available
  skip_if_not(check_grep_availability(), "grep command not available")
  
  # Test with non-existent file
  expect_equal(grep_count("nonexistent_file.txt", "pattern"), 0)
})