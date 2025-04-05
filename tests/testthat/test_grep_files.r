library(testthat)
context("grep_files function tests")

# Reuse the file creation function from previous tests
create_test_file <- function(file_path, content) {
  writeLines(content, file_path)
  return(file_path)
}

test_that("grep_files basic functionality", {
  # Skip tests if grep is not available
  skip_if_not(check_grep_availability(), "grep command not available")
  
  # Create temporary test files with different content
  temp_files <- c(
    file1 = tempfile(fileext = ".txt"),
    file2 = tempfile(fileext = ".txt"),
    file3 = tempfile(fileext = ".txt")
  )
  on.exit(unlink(temp_files), add = TRUE)
  
  create_test_file(temp_files["file1"], c(
    "This file contains pattern A",
    "And also pattern B"
  ))
  
  create_test_file(temp_files["file2"], c(
    "This file contains pattern A",
    "But not pattern B"
  ))
  
  create_test_file(temp_files["file3"], c(
    "This file contains neither",
    "Only pattern C here"
  ))
  
  # Test basic pattern matching
  result <- grep_files(temp_files, "pattern A")
  expect_true(is.character(result))
  expect_equal(length(result), 2)
  expect_true(all(temp_files[c("file1", "file2")] %in% result))
  expect_false(temp_files["file3"] %in% result)
  
  # Test with count attribute
  expect_true(!is.null(attr(result, "counts")))
  expect_equal(attr(result, "counts"), c(1, 1))
  
  # Test with pattern B
  result <- grep_files(temp_files, "pattern B")
  expect_equal(length(result), 1)
  expect_true(temp_files["file1"] %in% result)
  
  # Test with invert parameter
  result <- grep_files(temp_files, "pattern A", invert = TRUE)
  expect_equal(length(result), 1)
  expect_true(temp_files["file3"] %in% result)
  
  # Test with one_per_file parameter
  result <- grep_files(temp_files, "pattern", one_per_file = TRUE)
  expect_equal(length(result), 3)
  expect_null(attr(result, "counts"))
  
  # Test case sensitivity
  result <- grep_files(temp_files, "PATTERN A", ignore_case = TRUE)
  expect_equal(length(result), 2)
  result <- grep_files(temp_files, "PATTERN A", ignore_case = FALSE)
  expect_equal(length(result), 0)
  
  # Test show_cmd parameter
  cmds <- grep_files(temp_files, "pattern", show_cmd = TRUE)
  expect_true(is.list(cmds))
  expect_true(all(c("files_cmd", "count_cmd") %in% names(cmds)))
  expect_true(grepl("grep.*-l.*pattern", cmds$files_cmd))
})

test_that("grep_files handles file errors gracefully", {
  # Skip tests if grep is not available
  skip_if_not(check_grep_availability(), "grep command not available")
  
  # Test with non-existent file
  result <- grep_files(c("nonexistent_file1.txt", "nonexistent_file2.txt"), "pattern")
  expect_true(is.character(result))
  expect_equal(length(result), 0)
}) 