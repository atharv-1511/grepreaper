# ============================================================================
# DIAGNOSE PACKAGE ISSUE SCRIPT
# ============================================================================
# This script diagnoses why grep_read function is not found after loading
# ============================================================================
# Author: AI Assistant
# Date: 2025-01-28
# Purpose: Diagnose package loading and function availability issues
# ============================================================================

cat("=== DIAGNOSING GREPREAPER PACKAGE ISSUE ===\n")
cat("Investigating why grep_read function is not found\n\n")

# ============================================================================
# STEP 1: CHECK CURRENT PACKAGE STATUS
# ============================================================================

cat("=== STEP 1: Current Package Status ===\n\n")

# Check if package is installed
cat("1. Checking if grepreaper is installed...\n")
if ("grepreaper" %in% rownames(installed.packages())) {
  cat("✓ grepreaper is installed\n")
  cat("  Version:", as.character(packageVersion("grepreaper")), "\n")
  cat("  Location:", find.package("grepreaper"), "\n")
} else {
  cat("✗ grepreaper is NOT installed\n")
  stop("Package not installed - run installation first")
}

# Check if package is loaded
cat("\n2. Checking if grepreaper is loaded...\n")
if ("grepreaper" %in% loadedNamespaces()) {
  cat("✓ grepreaper is loaded\n")
} else {
  cat("ℹ grepreaper is NOT loaded\n")
}

cat("\n")

# ============================================================================
# STEP 2: ATTEMPT TO LOAD PACKAGE
# ============================================================================

cat("=== STEP 2: Loading Package ===\n\n")

# Try to load the package
cat("1. Attempting to load grepreaper...\n")
tryCatch({
  library(grepreaper)
  cat("✓ Package loaded successfully\n")
}, error = function(e) {
  cat("✗ Failed to load package:", e$message, "\n")
  stop("Package loading failed - cannot proceed")
})

# Verify package is now loaded
cat("\n2. Verifying package is loaded...\n")
if ("grepreaper" %in% loadedNamespaces()) {
  cat("✓ Package is now loaded\n")
} else {
  cat("✗ Package failed to load properly\n")
  stop("Package loading verification failed")
}

cat("\n")

# ============================================================================
# STEP 3: INVESTIGATE PACKAGE CONTENTS
# ============================================================================

cat("=== STEP 3: Investigating Package Contents ===\n\n")

# Check what's in the package namespace
cat("1. Checking package namespace...\n")
tryCatch({
  namespace_contents <- ls("package:grepreaper")
  cat("✓ Namespace contents found\n")
  cat("  Functions/objects:", paste(namespace_contents, collapse = ", "), "\n")
  
  if (length(namespace_contents) == 0) {
    cat("⚠ WARNING: Package namespace is empty!\n")
  }
}, error = function(e) {
  cat("✗ Error accessing package namespace:", e$message, "\n")
})

# Check package exports
cat("\n2. Checking package exports...\n")
tryCatch({
  exports <- getNamespaceExports("grepreaper")
  cat("✓ Package exports found\n")
  cat("  Exported functions:", paste(exports, collapse = ", "), "\n")
  
  if (length(exports) == 0) {
    cat("⚠ WARNING: Package has no exports!\n")
  }
}, error = function(e) {
  cat("✗ Error accessing package exports:", e$message, "\n")
})

# Check if grep_read exists anywhere
cat("\n3. Searching for grep_read function...\n")
tryCatch({
  # Check in global environment
  if (exists("grep_read")) {
    cat("✓ grep_read found in global environment\n")
    cat("  Type:", class(get("grep_read")), "\n")
  } else {
    cat("ℹ grep_read not in global environment\n")
  }
  
  # Check in grepreaper namespace
  if (exists("grep_read", where = "package:grepreaper")) {
    cat("✓ grep_read found in grepreaper package\n")
  } else {
    cat("✗ grep_read NOT found in grepreaper package\n")
  }
  
  # Check in grepreaper environment
  if (exists("grep_read", where = asNamespace("grepreaper"))) {
    cat("✓ grep_read found in grepreaper namespace\n")
  } else {
    cat("✗ grep_read NOT found in grepreaper namespace\n")
  }
}, error = function(e) {
  cat("✗ Error searching for grep_read:", e$message, "\n")
})

cat("\n")

# ============================================================================
# STEP 4: CHECK PACKAGE STRUCTURE
# ============================================================================

cat("=== STEP 4: Checking Package Structure ===\n\n")

# Check package directory structure
cat("1. Checking package directory structure...\n")
tryCatch({
  pkg_dir <- find.package("grepreaper")
  cat("✓ Package directory:", pkg_dir, "\n")
  
  # List R directory contents
  r_dir <- file.path(pkg_dir, "R")
  if (dir.exists(r_dir)) {
    r_files <- list.files(r_dir, pattern = "\\.r$|\\.R$", full.names = FALSE)
    cat("  R files:", paste(r_files, collapse = ", "), "\n")
  } else {
    cat("✗ R directory not found\n")
  }
  
  # Check NAMESPACE file
  namespace_file <- file.path(pkg_dir, "NAMESPACE")
  if (file.exists(namespace_file)) {
    cat("✓ NAMESPACE file exists\n")
    namespace_content <- readLines(namespace_file)
    cat("  NAMESPACE content:\n")
    for (line in namespace_content) {
      cat("    ", line, "\n")
    }
  } else {
    cat("✗ NAMESPACE file not found\n")
  }
}, error = function(e) {
  cat("✗ Error checking package structure:", e$message, "\n")
})

cat("\n")

# ============================================================================
# STEP 5: ATTEMPT FUNCTION RECOVERY
# ============================================================================

cat("=== STEP 5: Attempting Function Recovery ===\n\n")

# Try to find and load the function manually
cat("1. Attempting manual function recovery...\n")
tryCatch({
  # Check if function exists in R files
  pkg_dir <- find.package("grepreaper")
  r_dir <- file.path(pkg_dir, "R")
  
  if (dir.exists(r_dir)) {
    r_files <- list.files(r_dir, pattern = "\\.r$|\\.R$", full.names = TRUE)
    
    for (r_file in r_files) {
      cat("  Checking file:", basename(r_file), "\n")
      
      # Read file content
      file_content <- readLines(r_file)
      
      # Look for grep_read function definition
      grep_read_lines <- grep("grep_read\\s*<-", file_content, value = TRUE)
      if (length(grep_read_lines) > 0) {
        cat("    ✓ Found grep_read function definition\n")
        cat("    ", grep_read_lines[1], "\n")
        
        # Try to source the file
        cat("    Attempting to source file...\n")
        tryCatch({
          source(r_file)
          cat("    ✓ File sourced successfully\n")
          
          # Check if function is now available
          if (exists("grep_read")) {
            cat("    ✓ grep_read function is now available!\n")
            break
          } else {
            cat("    ✗ Function still not available after sourcing\n")
          }
        }, error = function(e) {
          cat("    ✗ Error sourcing file:", e$message, "\n")
        })
      } else {
        cat("    ℹ No grep_read function found in this file\n")
      }
    }
  }
}, error = function(e) {
  cat("✗ Error during function recovery:", e$message, "\n")
})

cat("\n")

# ============================================================================
# STEP 6: FINAL VERIFICATION
# ============================================================================

cat("=== STEP 6: Final Verification ===\n\n")

# Check if grep_read is now available
cat("1. Final check for grep_read function...\n")
if (exists("grep_read")) {
  cat("✓ SUCCESS: grep_read function is now available!\n")
  
  # Test the function
  cat("\n2. Testing grep_read function...\n")
  tryCatch({
    # Get function arguments
    args_text <- capture.output(args(grep_read))
    cat("✓ Function signature:", args_text[1], "\n")
    
    # Try a simple test
    cat("✓ Function appears to be working\n")
  }, error = function(e) {
    cat("⚠ Warning: Function exists but may have issues:", e$message, "\n")
  })
} else {
  cat("✗ FAILURE: grep_read function is still not available\n")
  
  cat("\n2. Summary of investigation:\n")
  cat("   - Package is installed and loaded\n")
  cat("   - Function is not exported or defined\n")
  cat("   - This suggests a package build/export issue\n")
  cat("   - Package may need to be rebuilt or reinstalled\n")
}

cat("\n")

# ============================================================================
# STEP 7: RECOMMENDATIONS
# ============================================================================

cat("=== STEP 7: Recommendations ===\n\n")

if (exists("grep_read")) {
  cat("🎉 PROBLEM RESOLVED!\n\n")
  cat("The grep_read function is now available and working.\n")
  cat("You can proceed with testing:\n")
  cat("source('comprehensive_package_test_final.R')\n\n")
} else {
  cat("🚨 PROBLEM PERSISTS\n\n")
  cat("The grep_read function is still not available.\n\n")
  
  cat("🔧 IMMEDIATE ACTIONS:\n")
  cat("1. Restart R session completely\n")
  cat("2. Run: source('robust_installation_test.R')\n")
  cat("3. If that fails, manually reinstall:\n")
  cat("   - detach('package:grepreaper', unload=TRUE)\n")
  cat("   - remove.packages('grepreaper')\n")
  cat("   - devtools::install_github('atharv-1511/grepreaper')\n")
  cat("   - library(grepreaper)\n\n")
  
  cat("📋 DIAGNOSTIC INFO COLLECTED:\n")
  cat("- Package installation status\n")
  cat("- Package loading status\n")
  cat("- Namespace contents\n")
  cat("- Package structure\n")
  cat("- Function availability\n\n")
  
  cat("Please share this output with the developer for further investigation.\n")
}

cat("=== DIAGNOSIS COMPLETE ===\n")
