# Example of building and testing a complete R package
# (Not run interactively - just a demonstration of the process)

# 1. Create package structure
# usethis::create_package("grepreaper")
message("1. Creating a new package structure with usethis::create_package()")

# 2. Set up git repository
# usethis::use_git()
message("2. Setting up git repository with usethis::use_git()")

# 3. Set up MIT license
# usethis::use_mit_license("Your Name")
message("3. Adding license with usethis::use_mit_license()")

# 4. Set up package dependencies
# usethis::use_package("data.table", "Imports")
message("4. Adding package dependencies with usethis::use_package()")

# 5. Set up testthat for testing
# usethis::use_testthat()
message("5. Setting up testing infrastructure with usethis::use_testthat()")

# 6. Add function files
message("6. Creating R function files")

# Create utility functions file
# write_utils_file <- function() {
#   usethis::use_r("utils")
#   # Add utility functions
# }

# Create main functions
# write_functions <- function() {
#   usethis::use_r("grep_count")
#   # Add grep_count function
#   
#   usethis::use_r("grep_read")
#   # Add grep_read function
#   
#   usethis::use_r("grep_files")
#   # Add grep_files function
#   
#   usethis::use_r("grep_context")
#   # Add grep_context function
# }

# 7. Set up documentation with roxygen
# usethis::use_roxygen_md()
message("7. Setting up roxygen documentation")

# 8. Add vignette
# usethis::use_vignette("grepreaper_intro", "Introduction to grepreaper")
message("8. Adding vignette")

# 9. Add README
# usethis::use_readme_md()
message("9. Creating README.md")

# 10. Set up continuous integration
# usethis::use_github_actions()
# usethis::use_github_action_check_standard()
message("10. Setting up CI/CD with GitHub Actions")

# 11. Build and check the package
# devtools::document()
# devtools::check()
message("11. Building documentation and checking package")

# 12. Install the package
# devtools::install()
message("12. Installing the package")

# 13. Submit to CRAN (when ready)
# devtools::release()
message("13. Prepare for CRAN submission")

# Demonstration of package usage
message("\nExample Package Usage:")
message('
library(grepreaper)

# Count lines matching a pattern
grep_count("data.csv", "pattern")

# Read filtered data
data <- grep_read("data.csv", "pattern")

# Find files with matching patterns
files <- grep_files(c("file1.csv", "file2.csv"), "pattern")

# View matches with context
context <- grep_context("data.csv", "pattern", before = 1, after = 1)
')
