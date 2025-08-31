# ============================================================================
# SIMPLE GREPREAPER INSTALLATION SCRIPT
# ============================================================================
# This script installs grepreaper from GitHub in the most reliable way
# ============================================================================

cat("=== GREPREAPER INSTALLATION ===\n\n")

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

# Step 2: Install dependencies
cat("\nStep 2: Installing dependencies...\n")
if (!require(data.table, quietly = TRUE)) {
  install.packages("data.table")
  cat("✅ data.table installed\n")
} else {
  cat("✅ data.table already available\n")
}

# Step 3: Download and install grepreaper
cat("\nStep 3: Downloading grepreaper from GitHub...\n")

# Create temporary directory
temp_dir <- tempdir()
zip_file <- file.path(temp_dir, "grepreaper.zip")
download_url <- "https://github.com/atharv-1511/grepreaper/archive/refs/heads/main.zip"

cat("Downloading from:", download_url, "\n")

# Download the ZIP file
tryCatch({
  download.file(download_url, zip_file, mode = "wb")
  cat("✅ Download completed\n")
  
  # Extract the ZIP file
  cat("Extracting files...\n")
  unzip(zip_file, exdir = temp_dir)
  cat("✅ Extraction completed\n")
  
  # Find the extracted directory
  extracted_dirs <- list.dirs(temp_dir, full.names = TRUE)
  grepreaper_dir <- extracted_dirs[grepl("grepreaper", extracted_dirs)][1]
  
  if (is.na(grepreaper_dir)) {
    stop("Could not find grepreaper directory in extracted files")
  }
  
  cat("Found directory:", grepreaper_dir, "\n")
  
  # Check if DESCRIPTION file exists
  if (!file.exists(file.path(grepreaper_dir, "DESCRIPTION"))) {
    stop("DESCRIPTION file not found in extracted directory")
  }
  
  # Install the package
  cat("Installing package...\n")
  install.packages(grepreaper_dir, repos = NULL, type = "source")
  cat("✅ Installation completed\n")
  
  # Clean up
  unlink(zip_file)
  unlink(grepreaper_dir, recursive = TRUE)
  cat("✅ Cleanup completed\n")
  
}, error = function(e) {
  cat("❌ ERROR:", e$message, "\n")
  cat("\nTroubleshooting:\n")
  cat("1. Check internet connection\n")
  cat("2. Verify R version (R 4.0+ recommended)\n")
  cat("3. Check write permissions\n")
  cat("4. Try manual download from:", download_url, "\n")
  
  # Clean up on error
  if (file.exists(zip_file)) unlink(zip_file)
  if (exists("grepreaper_dir") && dir.exists(grepreaper_dir)) {
    unlink(grepreaper_dir, recursive = TRUE)
  }
  
  stop("Installation failed")
})

# Step 4: Test installation
cat("\nStep 4: Testing installation...\n")
tryCatch({
  library(grepreaper)
  cat("✅ Package loaded successfully\n")
  
  if (exists("grep_read")) {
    cat("✅ grep_read function available\n")
  } else {
    cat("❌ grep_read function not found\n")
  }
  
}, error = function(e) {
  cat("❌ ERROR loading package:", e$message, "\n")
})

cat("\n=== INSTALLATION COMPLETE ===\n")
cat("If you see this message, the script ran completely!\n")
cat("Check the output above for any errors.\n")
