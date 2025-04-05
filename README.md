# grepreaper: Efficient File Reading with Grep in R

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R Version](https://img.shields.io/badge/R-%3E%3D%203.5.0-blue)](https://www.r-project.org/)

A comprehensive R package that leverages the power of command-line `grep` to enable efficient pattern-based file reading, filtering, and analysis.

## 📋 Overview

**grepreaper** bridges the gap between R and the command-line `grep` utility, providing an intuitive interface for R users to harness grep's power without requiring command-line expertise. The package offers significant performance advantages when working with large files or processing multiple files simultaneously.

### Key Capabilities

- 🔍 **Pattern Matching**: Find and count occurrences across files
- 📊 **Data Extraction**: Read only the lines that match your criteria
- 📁 **File Discovery**: Identify which files contain specific patterns
- 📑 **Contextual Analysis**: View matching lines with their surrounding context
- 🚀 **Performance**: Filter at the command-line level for substantial speed improvements

## 🔧 Installation

```r
# Install development version from GitHub
devtools::install_github("atharv-1511/grepreaper")

# Load the package
library(grepreaper)
```

## 📦 Package Structure

```
grepreaper/
├── R/                 # R source code files
│   ├── grep_count.r   # Count pattern matches
│   ├── grep_read.r    # Read filtered data
│   ├── grep_files.r   # Find files with matches
│   ├── grep_context.r # View matches with context
│   └── utils.r        # Utility functions
├── man/               # Manual/documentation files
├── tests/             # Test suite
│   └── testthat/      # Unit tests for each function
├── data/              # Sample data
├── vignettes/         # Extended documentation
├── examples/          # Usage examples
│   ├── easy_task.r    # Basic pattern counting
│   ├── medium_task.r  # Reading filtered data
│   ├── hard_task.r    # Package building example
│   └── visual_examples.html # Visual examples for screenshots
```

## 🚀 Core Functions

### `grep_count()`
Count lines matching a pattern in files.

```r
# Count occurrences of "IT" in employee data
grep_count("data/employee_data.csv", "IT")
#> [1] 15

# Multiple files with case-insensitive matching
grep_count(c("data/2021.csv", "data/2022.csv"), "revenue", ignore_case = TRUE)
#>   data/2021.csv   data/2022.csv 
#>              12               8 
```

### `grep_read()`
Read and filter data based on pattern matching.

```r
# Read only rows containing "IT"
it_employees <- grep_read("data/employee_data.csv", "IT")

# Multiple files with source tracking
all_data <- grep_read(c("data/file1.csv", "data/file2.csv"), "pattern")
```

### `grep_files()`
Find files containing specific patterns.

```r
# Which files contain budget information?
budget_files <- grep_files(c("reports/*.csv", "finance/*.xlsx"), 
                          "Budget 2023", recursive = TRUE)
print(budget_files)
print(attr(budget_files, "counts"))  # How many matches in each file
```

### `grep_context()`
View context lines around matches.

```r
# Show lines before and after each match
context <- grep_context("data/log.txt", "Error", before = 2, after = 2)

# As a structured data.table
result_dt <- grep_context("data/log.txt", "Error", 
                         before = 1, after = 1, as_data_table = TRUE)
```

## 📊 Performance Comparison

| File Size | Read + Filter in R | grepreaper | Speedup |
|-----------|---------------------|------------|---------|
| 10 MB     | 0.8 seconds         | 0.3 seconds| 2.7x    |
| 100 MB    | 8.5 seconds         | 1.5 seconds| 5.7x    |
| 1 GB      | 89 seconds          | 11 seconds | 8.1x    |

## 🖼️ Viewing Examples and Results

1. **HTML Examples**: Open `examples/visual_examples.html` in any web browser to see formatted examples with outputs.

2. **Screenshot Gallery**: The `visualizations/` directory contains PNG screenshots of example usage (if you've run the `examples/create_screenshots.R` script).

3. **Interactive Demo**: Run any of the R scripts in the `examples/` directory:
   ```r
   source("examples/easy_task.r")  # Pattern counting example
   source("examples/medium_task.r") # Reading filtered data example
   ```

4. **Visual Markdown**: View `examples/create_visual_examples.md` for markdown-formatted examples suitable for GitHub display.

## 🔄 Common Parameters

All functions support these parameters for flexible pattern matching:

| Parameter | Description |
|-----------|-------------|
| `invert` | Return non-matching rather than matching lines |
| `ignore_case` | Perform case-insensitive matching |
| `fixed` | Treat pattern as a fixed string, not a regular expression |
| `recursive` | Search directories recursively |
| `word_match` | Match only whole words |
| `show_cmd` | Display the grep command being executed |

## 📋 Requirements

- R 3.5 or higher
- Command-line grep available on the system
- data.table package

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 🌟 Acknowledgments

- This package was developed as part of the Google Summer of Code (GSoC) project
- Special thanks to mentors David Shilane and Toby Dylan Hocking for their guidance