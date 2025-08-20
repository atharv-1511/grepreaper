# Test the actual function's environment
library(grepreaper)

cat("=== TEST 1: Check if the actual function is working ===\n")
# Let's try a simple test first
dat1 <- grep_read(files = "test1.csv")
cat("Actual function result:\n")
print(head(dat1, 3))

cat("\n=== TEST 2: Check if the issue is in the package loading ===\n")
# Let's try reloading the package
detach("package:grepreaper", unload = TRUE)
library(grepreaper)
dat2 <- grep_read(files = "test1.csv")
cat("After reloading:\n")
print(head(dat2, 3))

cat("\n=== TEST 3: Check if the issue is in the function definition ===\n")
# Let's check if there's a difference in the function definition
cat("Function definition length:", length(grep_read), "\n")
cat("Function parameters:", names(formals(grep_read)), "\n")

cat("\n=== TEST 4: Compare with our working debug function ===\n")
source("debug_grep_read_exact_match.R")

cat("\n=== COMPARISON ===\n")
cat("Actual function carat:", dat1$carat, "\n")
cat("Actual function cut:", dat1$cut, "\n")
cat("Actual function color:", dat1$color, "\n")
cat("Debug function carat:", dat$carat, "\n")
cat("Debug function cut:", dat$cut, "\n")
cat("Debug function color:", dat$color, "\n") 