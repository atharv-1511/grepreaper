# Simple test to understand grep output
library(grepreaper)

# Test 1: Single file
cat("=== Single file ===\n")
cmd1 <- grep_read(files = "data/diamonds.csv", show_cmd = TRUE)
print(cmd1)

# Test 2: Multiple files, no filename, no line numbers
cat("\n=== Multiple files, no filename, no line numbers ===\n")
cmd2 <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                  show_line_numbers = FALSE, 
                  include_filename = FALSE, 
                  show_cmd = TRUE)
print(cmd2)

# Test 3: Multiple files, with line numbers, no filename
cat("\n=== Multiple files, with line numbers, no filename ===\n")
cmd3 <- grep_read(files = c("data/diamonds.csv", "data/diamonds.csv"), 
                  show_line_numbers = TRUE, 
                  include_filename = FALSE, 
                  show_cmd = TRUE)
print(cmd3)
