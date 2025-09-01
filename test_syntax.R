# Test script to validate syntax of refactored grep_read function
# This script will help identify any syntax errors without needing to run the full function

# Test basic syntax by sourcing the file
tryCatch({
  source("R/grep_read.r")
  cat("✅ Syntax check passed! No obvious syntax errors found.\n")
}, error = function(e) {
  cat("❌ Syntax error found:\n")
  cat("Error: ", e$message, "\n")
  cat("Location: ", e$call, "\n")
})

# Test if helper functions are defined
cat("\n🔍 Checking if helper functions are defined:\n")

# List of expected helper functions
expected_functions <- c(
  "handle_search_column",
  "build_grep_command_string", 
  "validate_and_prepare_files",
  "validate_parameters",
  "check_files_exist",
  "check_file_sizes",
  "build_grep_command",
  "read_data_with_grep",
  "process_count_data",
  "process_data_with_metadata",
  "process_metadata_columns",
  "remove_header_rows",
  "restore_data_types"
)

# Check each function
for (func_name in expected_functions) {
  if (exists(func_name)) {
    cat("✅ ", func_name, " - defined\n")
  } else {
    cat("❌ ", func_name, " - NOT defined\n")
  }
}

cat("\n🎯 Main function check:\n")
if (exists("grep_read")) {
  cat("✅ grep_read function is defined\n")
  cat("   Function length: ", length(deparse(grep_read)), " lines\n")
} else {
  cat("❌ grep_read function is NOT defined\n")
}

cat("\n📦 Package structure validation complete!\n")
