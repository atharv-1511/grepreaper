# Test suite for grep_read()
library(testthat)
library(data.table)
library(grepreaper)

test_that("Type restoration for all major R types (values only, not strict types)", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  tmp <- tempfile(fileext = ".csv")
  df <- data.frame(
    int_col = 1:3,
    num_col = c(1.1, 2.2, 3.3),
    log_col = c(TRUE, FALSE, TRUE),
    char_col = c("a", "b", "c"),
    fac_col = factor(c("x", "y", "x")),
    date_col = as.Date(c("2020-01-01", "2020-01-02", "2020-01-03")),
    time_col = as.POSIXct(c("2020-01-01 12:00:00", "2020-01-02 13:00:00", "2020-01-03 14:00:00")),
    complex_col = c(1+1i, 2+2i, 3+3i),
    stringsAsFactors = FALSE
  )
  fwrite(df, tmp)
  res <- grep_read(files = tmp)
  print(res)
  str(res)
  # Check that values are correct as character
  expect_equal(as.character(res$fac_col), as.character(df$fac_col))
  expect_equal(as.character(res$date_col), as.character(df$date_col))
  expect_equal(as.character(res$complex_col), as.character(df$complex_col))
  expect_equal(as.character(res$int_col), as.character(df$int_col))
  expect_equal(as.character(res$num_col), as.character(df$num_col))
  expect_equal(as.character(res$log_col), as.character(df$log_col))
  expect_equal(as.character(res$char_col), as.character(df$char_col))
})

test_that("Duplicate header rows are removed, no data loss", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  tmp <- tempfile(fileext = ".csv")
  df <- data.frame(a = 1:2, b = c("x", "y"))
  fwrite(df, tmp)
  files <- rep(tmp, 2)
  res <- grep_read(files = files)
  print(res)
  str(res)
  expect_equal(nrow(res), 4)
  # Check that header row is not present by value
  expect_false(any(res$a == "a" & res$b == "b"))
})

test_that("No spurious NA row appears", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  tmp <- tempfile(fileext = ".csv")
  df <- data.frame(a = 1:2, b = c("x", "y"))
  fwrite(df, tmp)
  files <- rep(tmp, 2)
  res <- grep_read(files = files)
  print(res)
  str(res)
  expect_false(any(apply(res, 1, function(x) all(is.na(x)))))
})

test_that("Line number column is named 'line_number' and only present when show_line_numbers = TRUE", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  tmp <- tempfile(fileext = ".csv")
  df <- data.frame(a = 1:2, b = c("x", "y"))
  fwrite(df, tmp)
  res1 <- grep_read(files = tmp, show_line_numbers = TRUE)
  print(res1)
  str(res1)
  expect_true("line_number" %in% names(res1))
  res2 <- grep_read(files = tmp, show_line_numbers = FALSE)
  print(res2)
  str(res2)
  expect_false("line" %in% names(res2))
})

test_that("Reading single and multiple files works with correct types and no header duplication", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  tmp1 <- tempfile(fileext = ".csv")
  tmp2 <- tempfile(fileext = ".csv")
  df1 <- data.frame(a = 1:2, b = c("x", "y"))
  df2 <- data.frame(a = 3:4, b = c("z", "w"))
  fwrite(df1, tmp1)
  fwrite(df2, tmp2)
  res <- grep_read(files = c(tmp1, tmp2))
  print(res)
  str(res)
  expect_equal(nrow(res), 4)
  expect_equal(sort(as.numeric(res$a)), 1:4)
  expect_false(any(res$a == "a" & res$b == "b"))
})

# New test cases for empty files and different encodings
test_that("Empty files are handled gracefully", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  # Test completely empty file
  empty_file <- tempfile(fileext = ".csv")
  file.create(empty_file)
  res1 <- grep_read(files = empty_file)
  expect_equal(nrow(res1), 0)
  
  # Test file with only header
  header_only <- tempfile(fileext = ".csv")
  writeLines("col1,col2", header_only)
  res2 <- grep_read(files = header_only)
  expect_equal(nrow(res2), 0)
  expect_equal(names(res2), c("col1", "col2"))
  
  # Test file with header and empty lines
  empty_lines <- tempfile(fileext = ".csv")
  writeLines(c("col1,col2", "", "", ""), empty_lines)
  res3 <- grep_read(files = empty_lines)
  expect_equal(nrow(res3), 0)
  expect_equal(names(res3), c("col1", "col2"))
})

test_that("Different file encodings are handled correctly", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  # UTF-8 file with BOM
  utf8_bom <- tempfile(fileext = ".csv")
  con <- file(utf8_bom, "wb")
  writeBin(charToRaw("\xEF\xBB\xBF"), con)  # Write BOM
  writeLines(c("col1,col2", "value1,value2"), con, useBytes = TRUE)
  close(con)
  res1 <- grep_read(files = utf8_bom)
  expect_equal(nrow(res1), 1)
  expect_equal(res1$col1, "value1")
  
  # UTF-8 file with special characters
  utf8_file <- tempfile(fileext = ".csv")
  writeLines(enc2utf8(c("col1,col2", "value1,value2")), utf8_file)
  res2 <- grep_read(files = utf8_file)
  expect_equal(nrow(res2), 1)
  expect_equal(res2$col1, "value1")
  
  # File with special characters
  special_chars <- tempfile(fileext = ".csv")
  special_data <- data.frame(
    name = c("José", "François", "Σωκράτης"),
    value = 1:3,
    stringsAsFactors = FALSE
  )
  fwrite(special_data, special_chars)
  res3 <- grep_read(files = special_chars)
  expect_equal(nrow(res3), 3)
  expect_equal(res3$name, special_data$name)
})

test_that("Header handling works correctly with line numbers", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  tmp <- tempfile(fileext = ".csv")
  df <- data.frame(a = 1:3, b = letters[1:3])
  fwrite(df, tmp)
  
  # Test with line numbers
  res1 <- grep_read(files = tmp, show_line_numbers = TRUE)
  expect_equal(nrow(res1), 3)
  expect_equal(res1$line_number, 1:3)  # Should start from 1 after header removal
  expect_false(any(res1$a == "a" & res1$b == "b"))  # Header should be removed
  
  # Test with multiple files and line numbers
  files <- rep(tmp, 2)
  res2 <- grep_read(files = files, show_line_numbers = TRUE)
  expect_equal(nrow(res2), 6)
  expect_equal(res2$line_number, rep(1:3, 2))  # Each file should start from 1
  expect_false(any(res2$a == "a" & res2$b == "b"))  # Headers should be removed
})

test_that("Column splitting works correctly with complex data", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  tmp <- tempfile(fileext = ".csv")
  df <- data.frame(
    text = c("contains:colon", "no colon here", "another:split"),
    value = 1:3,
    stringsAsFactors = FALSE
  )
  write.csv(df, tmp, row.names = FALSE)
  
  # Test with line numbers and filename
  res <- grep_read(
    files = tmp,
    show_line_numbers = TRUE,
    include_filename = TRUE
  )
  
  # Check structure
  expect_true(all(c("source_file", "line_number", "text", "value") %in% names(res)))
  
  # Check data
  expect_equal(nrow(res), nrow(df))
  expect_equal(sort(as.character(res$text)), sort(as.character(df$text)))
  expect_equal(sort(as.numeric(res$value)), sort(df$value))
  
  # Check line numbers
  expect_equal(res$line_number, seq_len(nrow(df)))
  
  # Check source file
  expect_true(all(!is.na(res$source_file)))
  expect_true(all(res$source_file == basename(tmp)))
  
  # Test without metadata
  res2 <- grep_read(files = tmp)
  expect_equal(names(res2), c("text", "value"))
  expect_equal(nrow(res2), nrow(df))
})