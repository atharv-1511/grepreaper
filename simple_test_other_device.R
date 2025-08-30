# ============================================================================
# SIMPLE TEST FOR GREPREAPER PACKAGE - OTHER DEVICE VERSION
# ============================================================================
# This is a simplified test script that's easier to run and debug
# ============================================================================

cat("=== SIMPLE GREPREAPER TEST ===\n")
cat("Testing grepreaper package installation and basic functionality\n\n")

# ============================================================================
# STEP 1: PACKAGE MANAGEMENT
# ============================================================================

cat("=== STEP 1: PACKAGE MANAGEMENT ===\n")

# Remove existing package if installed
tryCatch({
  if ("grepreaper" %in% installed.packages()[,"Package"]) {
    cat("Removing existing grepreaper package...\n")
    remove.packages("grepreaper")
    cat("✅ Package removed successfully\n\n")
  } else {
    cat("ℹ️  grepreaper package not found in installed packages\n\n")
  }
}, error = function(e) {
  cat("⚠️  Warning: Could not remove package:", e$message, "\n\n")
})

# Install required dependencies
cat("Installing required dependencies...\n")
required_packages <- c("data.table")
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("Installing", pkg, "...\n")
    install.packages(pkg, dependencies = TRUE)
  }
}

# ============================================================================
# STEP 2: INSTALL GREPREAPER
# ============================================================================

cat("=== STEP 2: INSTALLING GREPREAPER ===\n")

# Method 1: Try direct GitHub download and install
cat("Method 1: Direct GitHub download...\n")
tryCatch({
  temp_dir <- tempdir()
  download_url <- "https://github.com/atharv-1511/grepreaper/archive/refs/heads/main.zip"
  zip_file <- file.path(temp_dir, "grepreaper.zip")
  
  cat("Downloading from:", download_url, "\n")
  download.file(download_url, zip_file, mode = "wb")
  cat("Download completed. Extracting...\n")
  
  unzip(zip_file, exdir = temp_dir)
  
  # Find the extracted directory
  extracted_dir <- list.dirs(temp_dir, full.names = TRUE)
  grepreaper_dir <- extracted_dir[grepl("grepreaper", extracted_dir)][1]
  
  cat("Found extracted directory:", grepreaper_dir, "\n")
  
  if (!is.na(grepreaper_dir) && file.exists(file.path(grepreaper_dir, "DESCRIPTION"))) {
    cat("Installing from downloaded source...\n")
    install.packages(grepreaper_dir, repos = NULL, type = "source")
    cat("✅ grepreaper installed successfully from downloaded source\n\n")
  } else {
    stop("Could not find grepreaper source in downloaded files")
  }
  
  # Clean up
  unlink(zip_file)
  unlink(grepreaper_dir, recursive = TRUE)
  
}, error = function(e) {
  cat("❌ Method 1 failed:", e$message, "\n")
  cat("Trying Method 2...\n\n")
  
  # Method 2: Try to install from CRAN-like URL
  tryCatch({
    cat("Method 2: CRAN-style installation...\n")
    install.packages("https://github.com/atharv-1511/grepreaper/archive/refs/heads/main.zip", 
                     repos = NULL, 
                     type = "source")
    cat("✅ grepreaper installed successfully via CRAN method\n\n")
  }, error = function(e2) {
    cat("❌ Method 2 failed:", e2$message, "\n")
    cat("All installation methods failed. Please check:\n")
    cat("1. Internet connection\n")
    cat("2. R version compatibility\n")
    cat("3. Write permissions\n")
    stop("Cannot install grepreaper package")
  })
})

# ============================================================================
# STEP 3: LOAD AND TEST
# ============================================================================

cat("=== STEP 3: LOADING AND TESTING ===\n")

# Load the package
cat("Loading grepreaper package...\n")
tryCatch({
  library(grepreaper)
  cat("✅ grepreaper package loaded successfully\n\n")
}, error = function(e) {
  cat("❌ Error loading grepreaper:", e$message, "\n")
  stop("Cannot load grepreaper package")
})

# ============================================================================
# STEP 4: BASIC FUNCTIONALITY TEST
# ============================================================================

cat("=== STEP 4: BASIC FUNCTIONALITY TEST ===\n")

# Test if grep_read function exists
if (exists("grep_read")) {
  cat("✅ grep_read function found\n")
  
  # Test with a simple example
  cat("Testing basic functionality...\n")
  
  # Create a simple test file
  test_file <- tempfile(fileext = ".csv")
  test_data <- data.frame(
    col1 = c("test1", "test2", "test3"),
    col2 = c("data1", "data2", "data3")
  )
  write.csv(test_data, test_file, row.names = FALSE)
  
  cat("Created test file:", test_file, "\n")
  
  # Test grep_read
  tryCatch({
    result <- grep_read(files = test_file, show_line_numbers = FALSE, include_filename = FALSE)
    cat("✅ Basic test PASSED\n")
    cat("Result has", nrow(result), "rows and", ncol(result), "columns\n")
    
    # Clean up test file
    unlink(test_file)
    
  }, error = function(e) {
    cat("❌ Basic test FAILED:", e$message, "\n")
    unlink(test_file)
  })
  
} else {
  cat("❌ grep_read function not found\n")
}

cat("\n=== TEST COMPLETION ===\n")
cat("If you see this message, the script ran completely!\n")
cat("Check the output above for any errors.\n")
