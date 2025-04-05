library(testthat)
library(data.table)
context("grep_read function tests")

# Create a temporary test file with CSV content
create_test_csv <- function(file_path) {
  lines <- c(
    "id,name,department,salary",
    "1,Alice,HR,60000",
    "2,Bob,IT,75000",
    "3,Charlie,IT,90000",
    "4,David,Marketing,55000",
    "5,Eve,HR,65000"
  )
  writeLines(lines, file_path)
  return(file_path)
}

test_that("grep_read basic functionality", {
  # Skip tests if grep is not available
  skip_if_not(check_grep_availability(), "grep command not available")
  
  # Create temporary test files
  temp_file1 <- tempfile(fileext = ".csv")
  temp_file2 <- tempfile(fileext = ".csv")
  on.exit(unlink(c(temp_file1, temp_file2)), add = TRUE)
  
  create_test_csv(temp_file1)
  create_test_csv(temp_file2)
  
  # Test basic pattern matching
  result <- grep_read(temp_file1, "IT")
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 2)  # Two rows with "IT"
  expect_true(all(result$department == "IT"))
  
  # Test with inverted matching
  result <- grep_read(temp_file1, "IT", invert = TRUE)
  expect_equal(nrow(result), 4)  # Header + three rows without "IT"
  expect_false(any(result$department == "IT"))
  
  # Test case sensitivity
  result <- grep_read(temp_file1, "it", ignore_case = TRUE)
  expect_equal(nrow(result), 2)
  
  # Test with header parameter
  result <- grep_read(temp_file1, "id", header = FALSE)
  expect_equal(nrow(result), 1)
  
  # Test with nrows parameter
  result <- grep_read(temp_file1, "IT", nrows = 1)
  expect_equal(nrow(result), 1)
  
  # Test with skip parameter
  result <- grep_read(temp_file1, "IT", skip = 1)
  expect_equal(nrow(result), 2)  # Two IT employees
  
  # Test with col.names parameter
  custom_cols <- c("ID", "Name", "Dept", "Pay")
  result <- grep_read(temp_file1, "IT", col.names = custom_cols)
  expect_equal(names(result), custom_cols)
  
  # Test multiple files
  result <- grep_read(c(temp_file1, temp_file2), "IT")
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 4)  # 2 IT rows per file
  expect_true("source_file" %in% names(result))
  
  # Test show_cmd parameter
  cmd <- grep_read(temp_file1, "IT", show_cmd = TRUE)
  expect_true(is.character(cmd))
  expect_true(grepl("grep.*IT", cmd))
})

test_that("grep_read handles file errors gracefully", {
  # Skip tests if grep is not available
  skip_if_not(check_grep_availability(), "grep command not available")
  
  # Test with non-existent file
  result <- grep_read("nonexistent_file.csv", "pattern")
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 0)
})
