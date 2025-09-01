# Test script for refactored grep_read function on real datasets
# This will test various functionality with actual data files

cat("🧪 Testing refactored grep_read function on real datasets...\n\n")

# Source the required files - utils.r contains helper functions like build_grep_cmd
cat("📦 Loading required functions...\n")
source("R/utils.r")
source("R/grep_read.r")
cat("✅ All functions loaded successfully\n\n")

# Test 1: Basic functionality with sample_data.csv
cat("📊 Test 1: Basic functionality with sample_data.csv\n")
cat("File size:", file.size("data/sample_data.csv"), "bytes\n")

tryCatch({
  # Test basic read
  result1 <- grep_read(files = "data/sample_data.csv", pattern = "", show_cmd = FALSE)
  cat("✅ Basic read successful - Rows:", nrow(result1), "Columns:", ncol(result1), "\n")
  cat("   Column names:", paste(names(result1), collapse = ", "), "\n")
}, error = function(e) {
  cat("❌ Basic read failed:", e$message, "\n")
})

# Test 2: Pattern matching
cat("\n🔍 Test 2: Pattern matching\n")
tryCatch({
  # Test with a pattern that should exist
  result2 <- grep_read(files = "data/sample_data.csv", pattern = "test", show_cmd = FALSE)
  cat("✅ Pattern 'test' search successful - Rows:", nrow(result2), "\n")
}, error = function(e) {
  cat("❌ Pattern search failed:", e$message, "\n")
})

# Test 3: Count only mode
cat("\n🔢 Test 3: Count only mode\n")
tryCatch({
  result3 <- grep_read(files = "data/sample_data.csv", pattern = "test", count_only = TRUE)
  cat("✅ Count only mode successful - Count:", result3$count, "\n")
}, error = function(e) {
  cat("❌ Count only mode failed:", e$message, "\n")
})

# Test 4: Line numbers
cat("\n📝 Test 4: Line numbers\n")
tryCatch({
  result4 <- grep_read(files = "data/sample_data.csv", pattern = "", show_line_numbers = TRUE)
  cat("✅ Line numbers mode successful - Rows:", nrow(result4), "\n")
  if ("line_number" %in% names(result4)) {
    cat("   Line number column present\n")
  }
}, error = function(e) {
  cat("❌ Line numbers mode failed:", e$message, "\n")
})

# Test 5: Larger dataset - small_diamonds.csv
cat("\n💎 Test 5: Larger dataset (small_diamonds.csv)\n")
cat("File size:", file.size("data/small_diamonds.csv"), "bytes\n")

tryCatch({
  result5 <- grep_read(files = "data/small_diamonds.csv", pattern = "", show_cmd = FALSE)
  cat("✅ Large dataset read successful - Rows:", nrow(result5), "Columns:", ncol(result5), "\n")
  cat("   First few column names:", paste(head(names(result5), 5), collapse = ", "), "\n")
}, error = function(e) {
  cat("❌ Large dataset read failed:", e$message, "\n")
})

# Test 6: Pattern search in larger dataset
cat("\n🔍 Test 6: Pattern search in diamonds data\n")
tryCatch({
  result6 <- grep_read(files = "data/small_diamonds.csv", pattern = "Ideal", show_cmd = FALSE)
  cat("✅ Pattern 'Ideal' search successful - Rows:", nrow(result6), "\n")
}, error = function(e) {
  cat("❌ Pattern search in diamonds failed:", e$message, "\n")
})

# Test 7: Multiple files
cat("\n📁 Test 7: Multiple files\n")
tryCatch({
  result7 <- grep_read(files = c("data/sample_data.csv", "data/small_diamonds.csv"), 
                       pattern = "", show_cmd = FALSE)
  cat("✅ Multiple files read successful - Rows:", nrow(result7), "Columns:", ncol(result7), "\n")
}, error = function(e) {
  cat("❌ Multiple files read failed:", e$message, "\n")
})

# Test 8: Show command mode
cat("\n⚙️ Test 8: Show command mode\n")
tryCatch({
  cmd <- grep_read(files = "data/sample_data.csv", pattern = "test", show_cmd = TRUE)
  cat("✅ Command generation successful\n")
  cat("   Generated command:", substr(cmd, 1, 100), "...\n")
}, error = function(e) {
  cat("❌ Command generation failed:", e$message, "\n")
})

# Test 9: Column-specific search
cat("\n🎯 Test 9: Column-specific search\n")
tryCatch({
  # First check what columns exist
  sample_data <- read.csv("data/sample_data.csv")
  cat("   Available columns:", paste(names(sample_data), collapse = ", "), "\n")
  
  if (ncol(sample_data) > 0) {
    first_col <- names(sample_data)[1]
    result9 <- grep_read(files = "data/sample_data.csv", 
                         pattern = as.character(sample_data[1, 1]), 
                         search_column = first_col)
    cat("✅ Column-specific search successful - Rows:", nrow(result9), "\n")
  }
}, error = function(e) {
  cat("❌ Column-specific search failed:", e$message, "\n")
})

# Test 10: Performance test with larger file
cat("\n⚡ Test 10: Performance test with diabetes.csv\n")
cat("File size:", file.size("data/diabetes.csv"), "bytes\n")

tryCatch({
  start_time <- Sys.time()
  result10 <- grep_read(files = "data/diabetes.csv", pattern = "", show_cmd = FALSE)
  end_time <- Sys.time()
  
  cat("✅ Performance test successful - Rows:", nrow(result10), "Columns:", ncol(result10), "\n")
  cat("   Time taken:", round(as.numeric(difftime(end_time, start_time, units = "secs")), 3), "seconds\n")
}, error = function(e) {
  cat("❌ Performance test failed:", e$message, "\n")
})

cat("\n🎉 All tests completed! Check results above for any issues.\n")
cat("📊 Summary: The refactored grep_read function should handle real datasets efficiently.\n")
