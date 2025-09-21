# Windows Setup Script for grepreaper Package
# Run this script step by step in R/RStudio

cat("=== WINDOWS SETUP FOR GREPREAPER PACKAGE ===\n\n")

# Step 1: Set Git PATH (REQUIRED FIRST)
cat("Step 1: Setting Git PATH...\n")
Sys.setenv(PATH = paste("C:/Program Files/Git/usr/bin", Sys.getenv("PATH"),sep=";"))
cat("✅ Git PATH set\n\n")

# Step 2: Verify Git is Available
cat("Step 2: Verifying Git availability...\n")
git_check <- tryCatch({
  system("git --version", intern = TRUE)
}, error = function(e) {
  "Git not found"
})

if (grepl("git version", git_check)) {
  cat("✅ Git is available:", git_check, "\n\n")
} else {
  cat("❌ Git not found. Please install Git from: https://git-scm.com/download/win\n")
  cat("After installation, restart R and run this script again.\n")
  stop("Git installation required")
}

# Step 3: Install Required Packages
cat("Step 3: Installing required packages...\n")
required_packages <- c("devtools", "data.table")
missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]

if (length(missing_packages) > 0) {
  cat("Installing missing packages:", paste(missing_packages, collapse = ", "), "\n")
  install.packages(missing_packages)
}

# Load packages
library(devtools)
library(data.table)
cat("✅ Required packages loaded\n\n")

# Step 4: Clone Repository
cat("Step 4: Cloning repository...\n")
if (!dir.exists("grepreaper")) {
  system("git clone https://github.com/atharv-1511/grepreaper.git")
  cat("✅ Repository cloned\n\n")
} else {
  cat("✅ Repository already exists\n\n")
}

# Step 5: Navigate to Package Directory
cat("Step 5: Setting working directory...\n")
setwd("grepreaper")
cat("✅ Working directory set to:", getwd(), "\n\n")

# Step 6: Load Package
cat("Step 6: Loading package...\n")
tryCatch({
  devtools::load_all()
  cat("✅ Package loaded successfully\n\n")
}, error = function(e) {
  cat("❌ Package loading failed:", e$message, "\n")
  stop("Package loading failed")
})

# Step 7: Verify Functions
cat("Step 7: Verifying functions...\n")
functions_to_check <- c("grep_read", "grep_count", "split.columns", "build_grep_cmd")
all_functions_available <- TRUE

for (func in functions_to_check) {
  if (exists(func)) {
    cat("✅", func, "available\n")
  } else {
    cat("❌", func, "NOT available\n")
    all_functions_available <- FALSE
  }
}

if (all_functions_available) {
  cat("\n✅ All functions available!\n\n")
} else {
  cat("\n❌ Some functions missing. Check package loading.\n")
  stop("Function verification failed")
}

# Step 8: Quick Test
cat("Step 8: Running quick test...\n")
tryCatch({
  # Test grep_read
  result1 <- grep_read(files = "data/diamonds.csv", pattern = "Ideal", nrows = 3)
  cat("✅ grep_read test passed -", nrow(result1), "rows\n")
  
  # Test grep_count
  result2 <- grep_count(files = "data/diamonds.csv", pattern = "Ideal")
  cat("✅ grep_count test passed -", nrow(result2), "rows\n")
  
  cat("\n🎉 ALL TESTS PASSED! Package is ready to use.\n")
  
}, error = function(e) {
  cat("❌ Test failed:", e$message, "\n")
  cat("Check that data files exist and package is loaded correctly.\n")
})

cat("\n=== SETUP COMPLETE ===\n")
cat("You can now use the grepreaper package!\n")
cat("Try: grep_read(files = 'data/diamonds.csv', pattern = 'Ideal', nrows = 5)\n")
