library(data.table)
library(ggplot2)

# Load the diamonds dataset
data(diamonds)

# First, write the diamonds data to a CSV file
temp_file <- tempfile(fileext = ".csv")
fwrite(diamonds, temp_file)

# Method 1: Using data.table's fread with a grep command
message("Method 1 - Using data.table::fread with grep command:")
cmd <- sprintf("grep 'VS' %s", temp_file)
matched_data <- fread(cmd = cmd)

message("Number of rows: ", nrow(matched_data))
message("Preview of the data:")
print(head(matched_data, 3))

# Method 2: Using grepreaper's grep_read
library(grepreaper)
message("\nMethod 2 - Using grepreaper::grep_read:")
matched_data2 <- grep_read(temp_file, "VS")

message("Number of rows: ", nrow(matched_data2))
message("Preview of the data:")
print(head(matched_data2, 3))

# Differences between the approaches
message("\nAdvantages of grepreaper:")
message("1. Simplified syntax - no need to construct grep command")
message("2. Additional parameters like invert, ignore_case, etc.")
message("3. Consistent handling of multiple files")

# Clean up
unlink(temp_file)
