# Tests for grep_read() parameters
library(testthat)
library(grepreaper)

context("grep_read() parameter coverage")

test_file <- "data/sample_data.csv"

# 1. Basic usage: read all lines
test_that("Basic usage reads all lines", {
  res <- grep_read(files = test_file)
  expect_s3_class(res, "data.table")
  expect_true(nrow(res) > 0)
})

# 2. pattern parameter
test_that("Pattern filters lines", {
  res <- grep_read(files = test_file, pattern = "a")
  expect_true(all(grepl("a", do.call(paste, res), fixed = TRUE)))
})

# 3. invert parameter
test_that("Invert returns non-matching lines", {
  res <- grep_read(files = test_file, pattern = "a", invert = TRUE)
  expect_true(all(!grepl("a", do.call(paste, res), fixed = TRUE)))
})

# 4. ignore_case parameter
test_that("ignore_case matches case-insensitively", {
  res1 <- grep_read(files = test_file, pattern = "A", ignore_case = FALSE)
  res2 <- grep_read(files = test_file, pattern = "A", ignore_case = TRUE)
  expect_true(nrow(res2) >= nrow(res1))
})

# 5. fixed parameter
test_that("fixed matches literal strings", {
  res <- grep_read(files = test_file, pattern = ".", fixed = TRUE)
  expect_true(nrow(res) > 0)
})

# 6. show_cmd parameter
test_that("show_cmd returns command string", {
  cmd <- grep_read(files = test_file, pattern = "a", show_cmd = TRUE)
  expect_type(cmd, "character")
  expect_true(grepl("grep", cmd))
})

# 7. recursive and path parameters
test_that("path and recursive find files", {
  res <- grep_read(path = "data", pattern = "a", recursive = TRUE)
  expect_s3_class(res, "data.table")
})

# 8. file_pattern parameter
test_that("file_pattern filters files", {
  res <- grep_read(path = "data", file_pattern = "sample_data.csv", pattern = "a")
  expect_s3_class(res, "data.table")
})

# 9. word_match parameter
test_that("word_match matches whole words", {
  res <- grep_read(files = test_file, pattern = "the", word_match = TRUE)
  expect_true(all(grepl("\\bthe\\b", do.call(paste, res))))
})

# 10. show_line_numbers parameter
test_that("show_line_numbers includes line numbers", {
  res <- grep_read(files = test_file, pattern = "a", show_line_numbers = TRUE)
  expect_true("line_number" %in% names(res))
})

# 11. only_matching parameter
test_that("only_matching returns only matches", {
  res <- grep_read(files = test_file, pattern = "[a-z]+", only_matching = TRUE)
  expect_true("match" %in% names(res))
})

# 12. count_only parameter
test_that("count_only returns counts", {
  res <- grep_read(files = test_file, pattern = "a", count_only = TRUE)
  expect_true("count" %in% names(res))
})

# 13. nrows and skip parameters
test_that("nrows and skip limit rows", {
  res1 <- grep_read(files = test_file, nrows = 2)
  res2 <- grep_read(files = test_file, skip = 1, nrows = 2)
  expect_true(nrow(res1) <= 2)
  expect_true(nrow(res2) <= 2)
})

# 14. header and col.names parameters
test_that("header and col.names set column names", {
  res <- grep_read(files = test_file, header = TRUE)
  expect_true(!is.null(names(res)))
  res2 <- grep_read(files = test_file, header = FALSE, col.names = c("A", "B", "C"))
  expect_true(all(c("A", "B", "C") %in% names(res2)))
})

# 15. include_filename parameter
test_that("include_filename adds source_file column", {
  res <- grep_read(files = test_file, pattern = "a", include_filename = TRUE)
  expect_true("source_file" %in% names(res))
})

# 16. show_progress parameter
test_that("show_progress does not error", {
  res <- grep_read(files = test_file, show_progress = TRUE)
  expect_s3_class(res, "data.table")
}) 