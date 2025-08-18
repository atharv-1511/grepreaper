## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
library(grepreaper)

## -----------------------------------------------------------------------------
library(grepreaper)

## ----setup_files--------------------------------------------------------------
# Create a temporary CSV file
temp_file <- tempfile(fileext = ".csv")
write.csv(data.frame(
  ID = 1:10,
  Name = c("Alice", "Bob", "Charlie", "David", "Eve", 
           "Frank", "Grace", "Henry", "Ivy", "Jack"),
  Department = c("HR", "IT", "IT", "Marketing", "HR",
                "Finance", "IT", "Marketing", "HR", "Finance"),
  Salary = c(60000, 75000, 90000, 55000, 65000,
             85000, 70000, 62000, 67000, 72000)
), temp_file, row.names = FALSE)

## ----filter_data, eval = grepreaper::check_grep_availability()$available------
# Read rows containing "IT"
it_employees <- grep_read(temp_file, "IT")
print(it_employees)

# Read rows NOT containing "IT" (all other departments)
other_employees <- grep_read(temp_file, "IT", invert = TRUE)
print(other_employees)

## ----fread_params, eval = grepreaper::check_grep_availability()$available-----
# Specify column names
grep_read(temp_file, "IT", col.names = c("EmpID", "EmpName", "Dept", "Compensation"))

## ----multi_file, eval = grepreaper::check_grep_availability()$available-------
# Read data from multiple files
combined_data <- grep_read(c(temp_file, temp_file), "IT")
print(combined_data)

## ----cleanup------------------------------------------------------------------
# Remove temporary files
unlink(temp_file)

