library(ggplot2)
library(data.table)

# Load the diamonds dataset
data(diamonds)

# Using base R's grep to find rows with 'VS' clarity
matched_rows <- grep("VS", diamonds$clarity)
# Count the number of matching rows
message("Method 1 - Using base R grep():")
message("Number of rows with 'VS' clarity: ", length(matched_rows))

# Using grepreaper with a data.frame
# First, write the diamonds data to a temporary CSV file
temp_file <- tempfile(fileext = ".csv")
fwrite(diamonds, temp_file)

# Now use grepreaper to count matching rows
library(grepreaper)
message("\nMethod 2 - Using grepreaper grep_count():")
vs_count <- grep_count(temp_file, "VS")
message("Number of rows with 'VS' clarity: ", vs_count)

# Cleanup
unlink(temp_file)
