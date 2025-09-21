# Quick cross-device test for grepreaper package
cat("=== GREPREAPER QUICK TEST ===\n")
cat("Platform:", R.version$platform, "\n")
cat("R Version:", R.version$version.string, "\n\n")

# Load package
library(devtools)
load_all()

# Test functions
cat("Testing functions...\n")
cat("grep_read available:", exists("grep_read"), "\n")
cat("grep_count available:", exists("grep_count"), "\n")

# Quick functionality test
if (exists("grep_read") && exists("grep_count")) {
  cat("Testing basic functionality...\n")
  
  # Test grep_read
  result1 <- grep_read(files = "data/diamonds.csv", pattern = "Ideal", nrows = 3)
  cat("grep_read result:", nrow(result1), "rows\n")
  
  # Test grep_count
  result2 <- grep_count(files = "data/diamonds.csv", pattern = "Ideal")
  cat("grep_count result:", nrow(result2), "rows\n")
  
  cat("✅ All tests passed!\n")
} else {
  cat("❌ Functions not available\n")
}

cat("Test completed!\n")
