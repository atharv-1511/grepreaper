# 🚀 Quick Cross-Device Setup for Grepreaper Package Testing
# This script helps you quickly set up and test the grepreaper package on another device

cat("🚀 QUICK CROSS-DEVICE SETUP FOR GREPREAPER\n")
cat(paste(rep("=", 60), collapse = ""), "\n\n")

# Step 1: Check if we're in the right directory
cat("📁 Step 1: Checking directory structure...\n")
current_dir <- getwd()
cat("   Current directory:", current_dir, "\n")

# Check for R files
r_files_exist <- file.exists(c("R/utils.r", "R/grep_read.r"))
if (all(r_files_exist)) {
  cat("   ✅ R files found in R/ directory\n")
} else {
  cat("   ❌ R files not found. Please ensure you're in the grepreaper package directory\n")
  cat("   Expected files:\n")
  cat("     - R/utils.r\n")
  cat("     - R/grep_read.r\n")
  cat("   Please copy these files to the current directory and try again.\n")
  stop("R files not found")
}

# Step 2: Install required packages
cat("\n📦 Step 2: Installing required packages...\n")
if (!requireNamespace("data.table", quietly = TRUE)) {
  cat("   Installing data.table...\n")
  install.packages("data.table")
} else {
  cat("   ✅ data.table already installed\n")
}

# Step 3: Load the package functions
cat("\n📦 Step 3: Loading package functions...\n")
tryCatch({
  # Source the utility functions first
  source("R/utils.r")
  cat("   ✅ utils.r loaded successfully\n")
  
  # Source the main function
  source("R/grep_read.r")
  cat("   ✅ grep_read.r loaded successfully\n")
  
  # Load data.table
  library(data.table)
  cat("   ✅ data.table loaded successfully\n")
}, error = function(e) {
  cat("   ❌ Error loading functions:", e$message, "\n")
  stop("Failed to load package functions")
})

# Step 4: Verify functions are loaded
cat("\n🔍 Step 4: Verifying functions are loaded...\n")
main_function <- exists("grep_read")
helper_functions <- c("build_grep_cmd", "split.columns", "is_binary_file", 
                     "check_grep_availability", "get_system_info")
helper_functions_exist <- sapply(helper_functions, exists)

if (main_function) {
  cat("   ✅ grep_read function loaded\n")
} else {
  cat("   ❌ grep_read function not loaded\n")
}

for (i in seq_along(helper_functions)) {
  if (helper_functions_exist[i]) {
    cat("   ✅", helper_functions[i], "function loaded\n")
  } else {
    cat("   ❌", helper_functions[i], "function not loaded\n")
  }
}

# Step 5: Quick test with available files
cat("\n🧪 Step 5: Quick functionality test...\n")

# Check for test files
test_files <- c(
  "C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv",
  "C:\\Users\\Atharv Raskar\\Downloads\\Amusement_Parks_Rides_Registered.csv", 
  "C:\\Users\\Atharv Raskar\\Downloads\\academic Stress level - maintainance 1.csv",
  "C:\\Users\\Atharv Raskar\\Downloads\\pima-indians-diabetes.csv"
)

available_files <- test_files[file.exists(test_files)]

if (length(available_files) > 0) {
  cat("   Found", length(available_files), "test files\n")
  
  # Test with first available file
  test_file <- available_files[1]
  cat("   Testing with:", basename(test_file), "\n")
  
  tryCatch({
    # Basic read test
    result <- grep_read(files = test_file, pattern = "", show_cmd = FALSE)
    cat("   ✅ Basic read successful - Rows:", nrow(result), "Columns:", ncol(result), "\n")
    
    # Pattern search test
    result <- grep_read(files = test_file, pattern = "test", show_cmd = FALSE)
    cat("   ✅ Pattern search successful - Found", nrow(result), "matches\n")
    
    cat("   🎉 Package is working correctly!\n")
  }, error = function(e) {
    cat("   ❌ Test failed:", e$message, "\n")
  })
} else {
  cat("   ⚠️ No test files found in Downloads folder\n")
  cat("   Expected files:\n")
  for (file in test_files) {
    cat("     -", file, "\n")
  }
}

# Step 6: Run comprehensive test if requested
cat("\n📊 Step 6: Ready for comprehensive testing\n")
cat("   To run the full comprehensive test:\n")
cat("   source('COMPREHENSIVE_PACKAGE_TEST.R')\n")
cat("   \n")
cat("   Or run from command line:\n")
cat("   Rscript COMPREHENSIVE_PACKAGE_TEST.R\n")

cat("\n🎉 Setup complete! The grepreaper package is ready for testing.\n")
cat("📝 If you encounter any issues, check:\n")
cat("   1. R files are in the R/ directory\n")
cat("   2. Test files are in the Downloads folder\n")
cat("   3. data.table package is installed\n")
cat("   4. You're running R from the grepreaper package directory\n")
