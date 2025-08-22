# Test script to verify the fixes
library(data.table)

# Set PATH for Windows users (Git grep utility)
if (Sys.info()["sysname"] == "Windows") {
  Sys.setenv(PATH = paste("C:/Program Files/Git/usr/bin", Sys.getenv("PATH"), sep=";"))
}

# Test 1: Multiple files without filename (should have 0 NA values)
cat("=== Test 1: Multiple files without filename ===\n")
tryCatch({
  library(grepreaper)
  
  result <- grep_read(
    files = c("data/diamonds.csv", "data/diamonds.csv"), 
    pattern = "",  # Empty pattern to read entire files
    show_line_numbers = FALSE, 
    include_filename = FALSE
  )
  
  cat("Result dimensions:", paste(dim(result), collapse="x"), "\n")
  cat("Result columns:", paste(names(result), collapse=", "), "\n")
  
  # Check for NA values in key columns
  na_check <- sapply(result, function(x) sum(is.na(x)))
  has_na_issues <- any(na_check > 0)
  
  cat("NA values per column:\n")
  print(na_check)
  cat("Has NA issues:", has_na_issues, "\n")
  
  if (!has_na_issues) {
    cat("✅ SUCCESS: No NA values detected\n")
  } else {
    cat("❌ FAILURE: NA values found in columns:", names(na_check[na_check > 0]), "\n")
  }
  
}, error = function(e) {
  cat("❌ ERROR:", e$message, "\n")
})

# Test 2: Data type preservation (should preserve all types)
cat("\n=== Test 2: Data type preservation ===\n")
tryCatch({
  result2 <- grep_read(files = "data/diamonds.csv", pattern = "")
  
  cat("Result dimensions:", paste(dim(result2), collapse="x"), "\n")
  cat("Data types:\n")
  print(sapply(result2, class))
  
  # Check expected data types
  expected_types <- c(
    carat = "numeric",
    cut = "character", 
    color = "character",
    clarity = "character",
    depth = "numeric",
    table = "numeric",
    price = "integer",  # Price is naturally integer (whole numbers)
    x = "numeric",
    y = "numeric",
    z = "numeric"
  )
  
  type_check <- sapply(names(expected_types), function(col) {
    if (col %in% names(result2)) {
      actual_type <- class(result2[[col]])[1]
      expected_type <- expected_types[col]
      return(actual_type == expected_type)
    }
    return(FALSE)
  })
  
  all_types_correct <- all(type_check)
  cat("Correct types:", sum(type_check), "/", length(type_check), "\n")
  
  if (all_types_correct) {
    cat("✅ SUCCESS: All data types preserved correctly\n")
  } else {
    cat("❌ FAILURE: Some types not preserved correctly\n")
    for (col in names(type_check)) {
      if (col %in% names(result2)) {
        cat("   ", col, ":", class(result2[[col]])[1], "(expected:", expected_types[col], ")\n")
      }
    }
  }
  
}, error = function(e) {
  cat("❌ ERROR:", e$message, "\n")
})
