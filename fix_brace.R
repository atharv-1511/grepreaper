# Fix missing closing brace in grep_read.r
library(readr)

# Read the file
file_path <- "R/grep_read.r"
content <- readLines(file_path)

# Find the line with the comment about closing the else block
else_block_line <- which(grepl("Close the else block for pattern", content))

if (length(else_block_line) > 0) {
  # Insert the missing closing brace after the comment
  insert_line <- else_block_line[1] + 1
  
  # Create new content with the missing brace
  new_content <- c(
    content[1:(insert_line-1)],
    "  }",  # Add the missing closing brace
    content[insert_line:length(content)]
  )
  
  # Write back to file
  writeLines(new_content, file_path)
  cat("Fixed missing closing brace in", file_path, "\n")
} else {
  cat("Could not find the else block comment line\n")
}
