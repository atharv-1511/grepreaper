# ============================================================================
# SIMPLE GREPREAPER INSTALLATION SCRIPT
# ============================================================================
# Backup installation script for comprehensive testing
# ============================================================================

cat("=== SIMPLE GREPREAPER INSTALLATION ===\n\n")

# Step 1: Remove existing package
cat("Step 1: Removing existing grepreaper package...\n")
tryCatch({
  if ("grepreaper" %in% installed.packages()[,"Package"]) {
    remove.packages("grepreaper")
    cat("✅ Package removed\n")
  } else {
    cat("ℹ️  Package not found\n")
  }
}, error = function(e) {
  cat("⚠️  Warning:", e$message, "\n")
})

# Step 2: Install devtools if needed
cat("\nStep 2: Installing devtools...\n")
if (!require(devtools, quietly = TRUE)) {
  install.packages("devtools")
  cat("✅ devtools installed\n")
} else {
  cat("✅ devtools already available\n")
}

# Step 3: Install grepreaper from GitHub
cat("\nStep 3: Installing grepreaper from GitHub...\n")
tryCatch({
  devtools::install_github("atharv-1511/grepreaper", dependencies = FALSE)
  cat("✅ grepreaper installed successfully\n")
}, error = function(e) {
  cat("❌ Installation failed:", e$message, "\n")
  cat("Please check your internet connection and try again.\n")
  stop("Installation failed")
})

# Step 4: Load and verify package
cat("\nStep 4: Loading and verifying package...\n")
library(grepreaper)
cat("✅ Package loaded successfully\n")
cat("✅ Package version:", as.character(packageVersion("grepreaper")), "\n\n")

cat("🎉 Installation completed successfully!\n")
cat("You can now run the comprehensive testing script.\n")
