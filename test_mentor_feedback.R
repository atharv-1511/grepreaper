# Test script to reproduce mentor's failing test cases
# This will help us understand why carat becomes NA

library(data.table)
library(grepreaper)

# Test 1: No File Name, No Line Number - NEEDS REVISION
cat("=== Test 1: No File Name, No Line Number ===\n")
dat1 <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                  show_line_numbers = FALSE, 
                  include_filename = FALSE)
cat("First 2 rows:\n")
print(head(dat1, 2))
cat("NA count in carat:", dat1[, mean(is.na(carat))], "\n\n")

# Test 2: No File Name, But Line Number Included - NEEDS REVISION  
cat("=== Test 2: No File Name, But Line Number Included ===\n")
dat2 <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                  show_line_numbers = TRUE, 
                  include_filename = FALSE)
cat("First 2 rows:\n")
print(head(dat2, 2))
cat("NA count in carat:", dat2[, sum(is.na(carat))], "\n\n")

# Test 3: Includes File Name, But No Line Number - PASSES TEST
cat("=== Test 3: Includes File Name, But No Line Number ===\n")
dat3 <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                  show_line_numbers = FALSE, 
                  include_filename = TRUE)
cat("First 2 rows:\n")
print(head(dat3, 2))
cat("NA count in carat:", dat3[, sum(is.na(carat))], "\n\n")

# Test 4: Includes File Name and Line Number - PASSES TEST
cat("=== Test 4: Includes File Name and Line Number ===\n")
dat4 <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                  show_line_numbers = TRUE, 
                  include_filename = TRUE)
cat("First 2 rows:\n")
print(head(dat4, 2))
cat("NA count in carat:", dat4[, sum(is.na(carat))], "\n\n")

# Debug: Let's see what the grep command actually produces
cat("=== Debug: Grep Command Output ===\n")
cat("Command for Test 1:\n")
cmd1 <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                  show_line_numbers = FALSE, 
                  include_filename = FALSE, 
                  show_cmd = TRUE)
print(cmd1)

cat("\nCommand for Test 2:\n")
cmd2 <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                  show_line_numbers = TRUE, 
                  include_filename = FALSE, 
                  show_cmd = TRUE)
print(cmd2)
