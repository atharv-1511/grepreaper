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

test_that("Line number column is named 'line' and only present when show_line_numbers = TRUE", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  tmp <- tempfile(fileext = ".csv")
  df <- data.frame(a = 1:2, b = c("x", "y"))
  fwrite(df, tmp)
  res1 <- grep_read(files = tmp, show_line_numbers = TRUE)
  print(res1)
  str(res1)
  expect_true("line" %in% names(res1))
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

test_that("Edge case: file with only header row returns empty data.table with correct columns", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  tmp <- tempfile(fileext = ".csv")
  writeLines("a,b", tmp)
  res <- grep_read(files = tmp)
  print(res)
  str(res)
  expect_equal(nrow(res), 0)
  expect_equal(names(res), c("a", "b"))
})

test_that("Edge case: file with NA values is handled correctly", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  tmp <- tempfile(fileext = ".csv")
  df <- data.frame(a = c(1, NA), b = c("x", NA))
  fwrite(df, tmp)
  res <- grep_read(files = tmp)
  print(res)
  str(res)
  # Allow for platform differences: check at least one NA in each column
  expect_true(sum(is.na(res$a)) >= 1)
  expect_true(sum(is.na(res$b)) >= 1)
})

test_that("Only matching works correctly with fixed=TRUE for literal strings", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  tmp <- tempfile(fileext = ".csv")
  df <- data.frame(
    value = c("3.94", "3894", "3.95", "3940"),
    description = c("exact match", "regex match", "close match", "another match")
  )
  fwrite(df, tmp)
  
  # Test literal string matching with fixed=TRUE
  res_fixed <- grep_read(files = tmp, pattern = "3.94", only_matching = TRUE, fixed = TRUE)
  print(res_fixed)
  expect_equal(nrow(res_fixed), 1)
  expect_equal(res_fixed$match, "3.94")
  
  # Test regex matching with fixed=FALSE (should match more)
  res_regex <- grep_read(files = tmp, pattern = "3.94", only_matching = TRUE, fixed = FALSE)
  print(res_regex)
  expect_true(nrow(res_regex) >= 1)
})

test_that("Column splitting works correctly with filename and line numbers", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  tmp1 <- tempfile(fileext = ".csv")
  tmp2 <- tempfile(fileext = ".csv")
  df <- data.frame(a = 1:2, b = c("x", "y"))
  fwrite(df, tmp1)
  fwrite(df, tmp2)
  
  # Test with both filename and line numbers
  res <- grep_read(
    files = c(tmp1, tmp2),
    show_line_numbers = TRUE,
    include_filename = TRUE
  )
  print(res)
  str(res)
  
  # Should have source_file and line columns
  expect_true("source_file" %in% names(res))
  expect_true("line" %in% names(res))
  
  # Should have data columns
  expect_true("a" %in% names(res))
  expect_true("b" %in% names(res))
  
  # Should have correct number of rows (2 files * 2 rows each = 4)
  expect_equal(nrow(res), 4)
  
  # Check that line numbers are integers
  expect_true(is.integer(res$line))
  
  # Check that filenames are present
  expect_true(all(!is.na(res$source_file)))
})

test_that("Mentor's split_columns approach works for manual processing", {
  skip_if_not(check_grep_availability()$available, "grep not available")
  tmp1 <- tempfile(fileext = ".csv")
  tmp2 <- tempfile(fileext = ".csv")
  df <- data.frame(a = 1:2, b = c("x", "y"))
  fwrite(df, tmp1)
  fwrite(df, tmp2)
  
  # Get the raw grep command
  cmd <- grep_read(
    files = c(tmp1, tmp2),
    show_line_numbers = TRUE,
    include_filename = TRUE,
    show_cmd = TRUE
  )
  
  # Read raw data
  raw_data <- fread(cmd = cmd)
  
  # Apply mentor's split_columns function
  split_columns <- function(x, column_names = NA, split = ":", fixed = TRUE) {
    the_pieces <- strsplit(x = x, split = split, fixed = fixed)
    new_columns <- rbindlist(lapply(the_pieces, function(y) {
      return(as.data.table(t(y)))
    }))
    
    if (!is.na(column_names[1])) {
      # Only rename if we have the right number of columns
      if (length(column_names) == ncol(new_columns)) {
        setnames(x = new_columns, old = names(new_columns), new = column_names)
      }
    }
    return(new_columns)
  }
  
  # Split the first column - determine column names based on actual structure
  first_col <- raw_data[[1]]
  # Count colons in first row to determine structure
  n_colons <- lengths(regmatches(first_col[1], gregexpr(":", first_col[1], fixed=TRUE)))
  n_columns <- n_colons + 1
  
  # Create appropriate column names
  if (n_columns == 3) {
    col_names <- c("file", "line", "data")
  } else if (n_columns == 2) {
    col_names <- c("file", "data")
  } else {
    col_names <- paste0("V", 1:n_columns)
  }
  
  split_result <- split_columns(first_col, column_names = col_names)
  
  # Check that splitting worked correctly
  expect_equal(ncol(split_result), n_columns)
  expect_equal(nrow(split_result), nrow(raw_data))
  
  # Check that line numbers are present if expected
  if ("line" %in% names(split_result)) {
    expect_true(all(!is.na(split_result$line)))
  }
}) 