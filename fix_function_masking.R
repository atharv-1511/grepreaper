# Fix the function masking issue
cat("=== FIXING FUNCTION MASKING ===\n")

# Remove the masking functions from global environment
cat("Removing masking functions from global environment...\n")
if (exists("grep_read", envir = .GlobalEnv)) {
  rm(grep_read, envir = .GlobalEnv)
  cat("Removed grep_read from global environment\n")
}

if (exists("check_grep_availability", envir = .GlobalEnv)) {
  rm(check_grep_availability, envir = .GlobalEnv)
  cat("Removed check_grep_availability from global environment\n")
}

if (exists("build_grep_cmd", envir = .GlobalEnv)) {
  rm(build_grep_cmd, envir = .GlobalEnv)
  cat("Removed build_grep_cmd from global environment\n")
}

if (exists("grep_lines", envir = .GlobalEnv)) {
  rm(grep_lines, envir = .GlobalEnv)
  cat("Removed grep_lines from global environment\n")
}

# Reload the package
cat("\nReloading package...\n")
detach("package:grepreaper", unload = TRUE)
library(grepreaper)

# Test the package function directly
cat("\n=== TESTING PACKAGE FUNCTION ===\n")
dat_package <- grepreaper::grep_read(files = "test1.csv")
cat("Package function result:\n")
print(head(dat_package, 3))
cat("Column types:\n")
print(sapply(dat_package, class))

# Test the regular function call
cat("\n=== TESTING REGULAR FUNCTION CALL ===\n")
dat_regular <- grep_read(files = "test1.csv")
cat("Regular function result:\n")
print(head(dat_regular, 3))
cat("Column types:\n")
print(sapply(dat_regular, class))

# Compare results
cat("\n=== COMPARISON ===\n")
cat("Package function carat:", dat_package$carat, "\n")
cat("Package function cut:", dat_package$cut, "\n")
cat("Package function color:", dat_package$color, "\n")
cat("Regular function carat:", dat_regular$carat, "\n")
cat("Regular function cut:", dat_regular$cut, "\n")
cat("Regular function color:", dat_regular$color, "\n") 