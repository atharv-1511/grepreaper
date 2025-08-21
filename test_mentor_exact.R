# Test script that reproduces the mentor's exact failing test cases
# This will help us see what's still going wrong with our fix

library(data.table)
library(grepreaper)

cat("=== MENTOR'S FAILING TEST CASES ===\n\n")

# Test 1: No File Name, No Line Number -- NEEDS REVISION
cat("=== Test 1: No File Name, No Line Number -- NEEDS REVISION ===\n")
cat("Running: grep_read(files = c('data/diamonds.csv', 'data/diamonds.csv'), show_line_numbers = F, include_filename = F)\n")

tryCatch({
  dat1 <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                    show_line_numbers = FALSE, 
                    include_filename = FALSE)
  
  cat("Result:\n")
  print(head(dat1, 2))
  
  if ("carat" %in% names(dat1)) {
    cat("NA count in carat:", dat1[, mean(is.na(carat))], "\n")
    cat("First few carat values:", head(dat1$carat, 5), "\n")
  } else {
    cat("No 'carat' column found. Column names:", names(dat1), "\n")
  }
}, error = function(e) {
  cat("Error:", e$message, "\n")
})

cat("\n", paste(rep("=", 80), collapse = ""), "\n\n")

# Test 2: No File Name, But Line Number Included -- NEEDS REVISION
cat("=== Test 2: No File Name, But Line Number Included -- NEEDS REVISION ===\n")
cat("Running: grep_read(files = c('data/diamonds.csv', 'data/diamonds.csv'), show_line_numbers = T, include_filename = F)\n")

tryCatch({
  dat2 <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                    show_line_numbers = TRUE, 
                    include_filename = FALSE)
  
  cat("Result:\n")
  print(head(dat2, 2))
  
  if ("carat" %in% names(dat2)) {
    cat("NA count in carat:", dat2[, sum(is.na(carat))], "\n")
    cat("First few carat values:", head(dat2$carat, 5), "\n")
  } else {
    cat("No 'carat' column found. Column names:", names(dat2), "\n")
  }
}, error = function(e) {
  cat("Error:", e$message, "\n")
})

cat("\n", paste(rep("=", 80), collapse = ""), "\n\n")

# Test 3: Includes File Name, But No Line Number Included -- PASSES TEST
cat("=== Test 3: Includes File Name, But No Line Number Included -- PASSES TEST ===\n")
cat("Running: grep_read(files = c('data/diamonds.csv', 'data/diamonds.csv'), show_line_numbers = F, include_filename = T)\n")

tryCatch({
  dat3 <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                    show_line_numbers = FALSE, 
                    include_filename = TRUE)
  
  cat("Result:\n")
  print(head(dat3, 2))
  
  if ("carat" %in% names(dat3)) {
    cat("NA count in carat:", dat3[, sum(is.na(carat))], "\n")
    cat("First few carat values:", head(dat3$carat, 5), "\n")
  } else {
    cat("No 'carat' column found. Column names:", names(dat3), "\n")
  }
}, error = function(e) {
  cat("Error:", e$message, "\n")
})

cat("\n", paste(rep("=", 80), collapse = ""), "\n\n")

# Test 4: Includes File Name and Line Number -- PASSES TEST
cat("=== Test 4: Includes File Name and Line Number -- PASSES TEST ===\n")
cat("Running: grep_read(files = c('data/diamonds.csv', 'data/diamonds.csv'), show_line_numbers = T, include_filename = T)\n")

tryCatch({
  dat4 <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                    show_line_numbers = TRUE, 
                    include_filename = TRUE)
  
  cat("Result:\n")
  print(head(dat4, 2))
  
  if ("carat" %in% names(dat4)) {
    cat("NA count in carat:", dat4[, sum(is.na(carat))], "\n")
    cat("First few carat values:", head(dat4$carat, 5), "\n")
  } else {
    cat("No 'carat' column found. Column names:", names(dat4), "\n")
  }
}, error = function(e) {
  cat("Error:", e$message, "\n")
})

cat("\n=== SUMMARY ===\n")
cat("If Tests 1 and 2 still show NA values in carat, our fix didn't work.\n")
cat("We need to investigate further what's going wrong.\n")
