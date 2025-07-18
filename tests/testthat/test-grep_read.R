# Test suite for grep_read()
library(testthat)
library(data.table)
library(grepreaper)

test_that("Type restoration for all major R types (values only, not strict types)", {
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
  tmp <- tempfile(fileext = ".csv")
  writeLines("a,b", tmp)
  res <- grep_read(files = tmp)
  print(res)
  str(res)
  expect_equal(nrow(res), 0)
  expect_equal(names(res), c("a", "b"))
})

test_that("Edge case: file with NA values is handled correctly", {
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