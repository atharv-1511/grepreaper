test_that("grep_read handles default pattern correctly", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  # Create a sample CSV file
  sample_data <- data.frame(
    department = c("IT", "HR", "IT", "Finance", "IT"),
    employee = c("John", "Alice", "Bob", "Charlie", "David"),
    salary = c(75000, 65000, 80000, 70000, 85000)
  )
  write.csv(sample_data, "sample_data.csv", row.names = FALSE)
  
  # Test reading all lines with default pattern
  result <- grep_read("sample_data.csv")
  expect_equal(nrow(result), nrow(sample_data))
  expect_equal(names(result), c("department", "employee", "salary"))
  
  # Cleanup
  unlink("sample_data.csv")
})

test_that("grep_read preserves column names", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  # Create a sample CSV file with headers
  sample_data <- data.frame(
    dept = c("IT", "HR", "IT"),
    name = c("John", "Alice", "Bob"),
    pay = c(75000, 65000, 80000)
  )
  write.csv(sample_data, "sample_data.csv", row.names = FALSE)
  
  # Test reading with pattern
  result <- grep_read("sample_data.csv", "IT")
  expect_equal(names(result), c("dept", "name", "pay"))
  
  # Test reading with custom column names
  custom_names <- c("department", "employee", "salary")
  result <- grep_read("sample_data.csv", "IT", col.names = custom_names)
  expect_equal(names(result), custom_names)
  
  # Cleanup
  unlink("sample_data.csv")
})

test_that("grep_read handles multiple files correctly", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  # Create two sample files
  file1_data <- data.frame(
    department = c("IT", "HR"),
    employee = c("John", "Alice")
  )
  file2_data <- data.frame(
    department = c("IT", "Finance"),
    employee = c("Bob", "Charlie")
  )
  
  write.csv(file1_data, "file1.csv", row.names = FALSE)
  write.csv(file2_data, "file2.csv", row.names = FALSE)
  
  # Test reading from multiple files
  result <- grep_read(c("file1.csv", "file2.csv"), "IT", include_filename = TRUE)
  expect_equal(nrow(result), 2)  # Two IT entries
  expect_true("source_file" %in% names(result))
  
  # Test count only
  counts <- grep_read(c("file1.csv", "file2.csv"), "IT", count_only = TRUE)
  expect_equal(nrow(counts), 2)
  expect_equal(sum(counts$count), 2)
  
  # Cleanup
  unlink(c("file1.csv", "file2.csv"))
})

test_that("grep_read handles line numbers correctly", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  # Create a sample file
  sample_data <- data.frame(
    department = c("IT", "HR", "IT"),
    employee = c("John", "Alice", "Bob")
  )
  write.csv(sample_data, "sample_data.csv", row.names = FALSE)
  
  # Test reading with line numbers
  result <- grep_read("sample_data.csv", "IT", show_line_numbers = TRUE)
  expect_true("line_number" %in% names(result))
  expect_equal(nrow(result), 2)  # Two IT entries
  
  # Cleanup
  unlink("sample_data.csv")
})

test_that("grep_read handles errors gracefully", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  # Test with non-existent file
  expect_error(grep_read("nonexistent.csv"), "grepreaper failed")
  
  # Test with invalid pattern
  expect_error(grep_read("sample_data.csv", pattern = c("a", "b")), 
               "pattern must be a single character string")
  
  # Test with empty files vector
  expect_error(grep_read(character(0)), "'files' must be a non-empty character vector")
})

test_that("grep_read handles progress indicators", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  # Create a large sample file
  large_data <- data.frame(
    department = rep(c("IT", "HR", "Finance"), 1000),
    employee = paste0("Employee", 1:3000),
    salary = sample(50000:100000, 3000)
  )
  write.csv(large_data, "large_data.csv", row.names = FALSE)
  
  # Test with progress indicator
  expect_message(
    grep_read("large_data.csv", show_progress = TRUE),
    "Reading data from 1 file\\(s\\)..."
  )
  
  # Test without progress indicator
  expect_silent(
    grep_read("large_data.csv", show_progress = FALSE)
  )
  
  # Cleanup
  unlink("large_data.csv")
})

test_that("only_matching returns only the matched part of lines", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  # Setup
  temp_dir <- tempfile("test_only_matching")
  dir.create(temp_dir)
  file1_path <- file.path(temp_dir, "file1.txt")
  
  # Write data with a clear pattern
  writeLines(c("id,value", "1,apple-fruit", "2,banana-fruit", "3,carrot-vegetable"), file1_path)
  
  # Test with only_matching = TRUE
  result <- grep_read(files = file1_path, pattern = "[a-z]+-fruit", only_matching = TRUE, header = FALSE)
  
  # Check expectations
  expect_true(data.table::is.data.table(result))
  expect_equal(names(result), "match")
  expect_equal(nrow(result), 2)
  expect_equal(result$match, c("apple-fruit", "banana-fruit"))
  
  # Test with filename included
  result_with_fname <- grep_read(files = file1_path, pattern = "fruit", only_matching = TRUE, header = FALSE, include_filename = TRUE)
  expect_equal(names(result_with_fname), c("source_file", "match"))
  expect_equal(nrow(result_with_fname), 2)
  expect_equal(result_with_fname$match, c("fruit", "fruit"))
  
  # Cleanup
  unlink(temp_dir, recursive = TRUE)
}) 