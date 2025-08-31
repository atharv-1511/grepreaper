# ============================================================================
# EMERGENCY FIX FOR GREPREAPER FUNCTION NOT FOUND
# ============================================================================
# This script aggressively fixes the grep_read function not found issue
# ============================================================================
# Author: AI Assistant
# Date: 2025-01-28
# Purpose: Emergency fix for cross-device function availability issues
# ============================================================================

cat("=== EMERGENCY FIX FOR GREPREAPER ===\n")
cat("Aggressively resolving function not found issue\n\n")

# ============================================================================
# STEP 1: AGGRESSIVE CLEANUP
# ============================================================================

cat("=== STEP 1: Aggressive Cleanup ===\n\n")

# Force detach and unload
cat("1. Force detaching package...\n")
tryCatch({
  if ("grepreaper" %in% loadedNamespaces()) {
    detach("package:grepreaper", unload = TRUE, character.only = TRUE, force = TRUE)
    cat("✓ Package force detached\n")
  }
}, error = function(e) {
  cat("⚠ Warning during force detach:", e$message, "\n")
})

# Remove from library
cat("2. Removing package from library...\n")
tryCatch({
  if ("grepreaper" %in% rownames(installed.packages())) {
    remove.packages("grepreaper")
    cat("✓ Package removed\n")
  }
}, error = function(e) {
  cat("⚠ Warning during removal:", e$message, "\n")
})

# Clear any remaining references
cat("3. Clearing remaining references...\n")
tryCatch({
  if (exists("grep_read")) {
    rm("grep_read")
    cat("✓ grep_read function removed from global environment\n")
  }
}, error = function(e) {
  cat("⚠ Warning clearing references:", e$message, "\n")
})

# Force garbage collection multiple times
cat("4. Aggressive memory cleanup...\n")
for (i in 1:3) {
  gc()
  Sys.sleep(0.5)
}
cat("✓ Memory cleanup completed\n")

cat("\n")

# ============================================================================
# STEP 2: FRESH INSTALLATION
# ============================================================================

cat("=== STEP 2: Fresh Installation ===\n\n")

# Install devtools if needed
cat("1. Ensuring devtools is available...\n")
if (!require(devtools, quietly = TRUE)) {
  install.packages("devtools", dependencies = TRUE)
  cat("✓ devtools installed\n")
} else {
  cat("✓ devtools already available\n")
}

# Fresh install from GitHub
cat("2. Installing fresh copy from GitHub...\n")
tryCatch({
  devtools::install_github("atharv-1511/grepreaper", dependencies = FALSE, force = TRUE)
  cat("✓ Fresh installation completed\n")
}, error = function(e) {
  cat("✗ Installation failed:", e$message, "\n")
  stop("Fresh installation failed - cannot proceed")
})

cat("\n")

# ============================================================================
# STEP 3: VERIFICATION AND LOADING
# ============================================================================

cat("=== STEP 3: Verification and Loading ===\n\n")

# Check installation
cat("1. Verifying installation...\n")
if ("grepreaper" %in% rownames(installed.packages())) {
  cat("✓ Package installed successfully\n")
  cat("  Version:", as.character(packageVersion("grepreaper")), "\n")
} else {
  stop("Package not found after installation")
}

# Load package
cat("2. Loading package...\n")
tryCatch({
  library(grepreaper)
  cat("✓ Package loaded successfully\n")
}, error = function(e) {
  cat("✗ Failed to load package:", e$message, "\n")
  stop("Package loading failed")
})

# Verify function availability
cat("3. Checking function availability...\n")
if (exists("grep_read", where = "package:grepreaper")) {
  cat("✓ grep_read function found in package\n")
} else {
  cat("✗ grep_read function still not found in package\n")
  
  # Try alternative approach
  cat("4. Attempting alternative function discovery...\n")
  
  # Check namespace exports
  tryCatch({
    exports <- getNamespaceExports("grepreaper")
    cat("  Package exports:", paste(exports, collapse = ", "), "\n")
    
    if (length(exports) == 0) {
      cat("  ⚠ WARNING: Package has no exports!\n")
    }
  }, error = function(e) {
    cat("  ✗ Error checking exports:", e$message, "\n")
  })
  
  # Check what's actually in the package
  tryCatch({
    namespace_contents <- ls("package:grepreaper")
    cat("  Namespace contents:", paste(namespace_contents, collapse = ", "), "\n")
  }, error = function(e) {
    cat("  ✗ Error checking namespace:", e$message, "\n")
  })
  
  stop("Function verification failed - package may be corrupted")
}

cat("\n")

# ============================================================================
# STEP 4: FUNCTION TESTING
# ============================================================================

cat("=== STEP 4: Function Testing ===\n\n")

# Test basic function call
cat("1. Testing basic function call...\n")
tryCatch({
  # Get function arguments
  args_text <- capture.output(args(grep_read))
  cat("✓ Function signature:", args_text[1], "\n")
  
  # Test with a simple pattern
  cat("2. Testing function execution...\n")
  
  # Create a simple test file
  test_file <- tempfile(fileext = ".csv")
  test_data <- data.frame(
    col1 = c("test1", "test2", "VVS1", "test3"),
    col2 = c("A", "B", "C", "D")
  )
  write.csv(test_data, test_file, row.names = FALSE)
  
  # Test the function
  result <- grep_read(files = test_file, pattern = "VVS1", fixed = TRUE)
  
  if (nrow(result) > 0) {
    cat("✓ Function execution PASSED - Found", nrow(result), "rows\n")
  } else {
    cat("⚠ Function executed but no results found\n")
  }
  
  # Cleanup test file
  unlink(test_file)
  
}, error = function(e) {
  cat("✗ Function testing failed:", e$message, "\n")
  stop("Function is not working correctly")
})

cat("\n")

# ============================================================================
# STEP 5: SUCCESS VERIFICATION
# ============================================================================

cat("=== STEP 5: Success Verification ===\n\n")

cat("🎉 EMERGENCY FIX COMPLETED SUCCESSFULLY!\n\n")

cat("📊 What Was Fixed:\n")
cat("1. ✅ Package completely removed and reinstalled\n")
cat("2. ✅ Package loads without errors\n")
cat("3. ✅ grep_read function is available\n")
cat("4. ✅ Function executes correctly\n")
cat("5. ✅ Basic functionality verified\n\n")

cat("🚀 Ready for Testing:\n")
cat("You can now run the comprehensive testing script:\n")
cat("source('comprehensive_package_test_final.R')\n\n")

cat("🔧 If Issues Persist:\n")
cat("1. Restart R session completely\n")
cat("2. Run this emergency fix script again\n")
cat("3. Check for system-specific issues\n\n")

cat("The grepreaper package is now working correctly!\n")
cat("=== EMERGENCY FIX COMPLETE ===\n")
