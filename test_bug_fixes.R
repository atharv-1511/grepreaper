# Comprehensive test script for bug fixes
# Set PATH to include Git's grep utility (Windows specific)
Sys.setenv(PATH = paste("C:/Program Files/Git/usr/bin", Sys.getenv("PATH"), sep=";"))

library(data.table)
library(grepreaper)

cat("=== TESTING BUG FIXES ===\n\n")

# Test 1: split.columns fix - should return character vectors, not lists
cat("=== Test 1: split.columns fix ===\n")
test_data <- c("file1:line1:data:with:colons", "file2:line2:simple", "file3:line3:more:data:here")
result <- split.columns(test_data, c("file", "line", "data"), resulting.columns = 3)
cat("Column types:\n")
print(sapply(result, class))
cat("First few values:\n")
print(head(result, 2))
if (all(sapply(result, function(x) is.character(x) && !is.list(x)))) {
  cat("✅ PASS: split.columns returns character vectors\n")
} else {
  cat("❌ FAIL: split.columns still returns list columns\n")
}

cat("\n", paste(rep("=", 50), collapse = ""), "\n\n")

# Test 2: Input validation
cat("=== Test 2: Input validation ===\n")

# Test conflicting parameters
tryCatch({
  grep_read(files = "data/diamonds.csv", count_only = TRUE, only_matching = TRUE)
  cat("❌ FAIL: Should have caught conflicting parameters\n")
}, error = function(e) {
  cat("✅ PASS: Caught conflicting parameters:", e$message, "\n")
})

# Test invalid nrows
tryCatch({
  grep_read(files = "data/diamonds.csv", nrows = -1)
  cat("❌ FAIL: Should have caught negative nrows\n")
}, error = function(e) {
  cat("✅ PASS: Caught negative nrows:", e$message, "\n")
})

cat("\n", paste(rep("=", 50), collapse = ""), "\n\n")

# Test 3: Multiple files without filename (our main fix)
cat("=== Test 3: Multiple files without filename ===\n")
tryCatch({
  result <- grep_read(
    files = c("data/diamonds.csv", "data/diamonds.csv"), 
    show_line_numbers = FALSE, 
    include_filename = FALSE
  )
  
  cat("Result shape:", nrow(result), "rows x", ncol(result), "columns\n")
  cat("Column names:", names(result), "\n")
  
  if ("carat" %in% names(result)) {
    na_count <- sum(is.na(result$carat))
    cat("NA count in carat:", na_count, "\n")
    cat("First few carat values:", head(result$carat, 5), "\n")
    
    if (na_count == 0) {
      cat("✅ PASS: No NA values in carat column\n")
    } else {
      cat("❌ FAIL: Still has NA values in carat column\n")
    }
  } else {
    cat("❌ FAIL: No 'carat' column found\n")
  }
}, error = function(e) {
  cat("❌ ERROR:", e$message, "\n")
})

cat("\n", paste(rep("=", 50), collapse = ""), "\n\n")

# Test 4: Build command security
cat("=== Test 4: Command building security ===\n")
tryCatch({
  # Test with potentially dangerous input
  cmd <- build_grep_cmd("normal pattern", "data/diamonds.csv", "-n")
  cat("✅ Normal command built successfully\n")
  
  # Test input validation
  build_grep_cmd("", "data/diamonds.csv")
  cat("❌ FAIL: Should have caught empty pattern\n")
}, error = function(e) {
  cat("✅ PASS: Caught invalid input:", e$message, "\n")
})

cat("\n", paste(rep("=", 50), collapse = ""), "\n\n")

# Test 5: Memory and performance
cat("=== Test 5: Performance test ===\n")
start_time <- Sys.time()
result <- grep_read(
  files = c("data/diamonds.csv", "data/diamonds.csv"), 
  show_line_numbers = TRUE, 
  include_filename = FALSE
)
end_time <- Sys.time()

cat("Processing time:", as.numeric(end_time - start_time), "seconds\n")
cat("Memory usage for result:", object.size(result), "bytes\n")
cat("Rows processed:", nrow(result), "\n")

if (as.numeric(end_time - start_time) < 10) {
  cat("✅ PASS: Processing completed in reasonable time\n")
} else {
  cat("⚠️  WARNING: Processing took longer than expected\n")
}

cat("\n=== BUG FIX TESTING COMPLETE ===\n")
cat("Check the results above for any remaining issues.\n")
