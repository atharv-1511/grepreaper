# grepreaper

> Efficient, practical grep-powered reading for CSV-like data using data.table


[!IMPORTANT] This project was developed as part of Google Summer of Code (GSoC) 2025.

- GSoC Report: see `GSOC_REPORT.md` (summary, changes, testing, how to evaluate)
- Comprehensive tests: `test_comprehensive.R` and `test_complex.R`

## Overview

`grepreaper` provides a fast, flexible way to filter and read large, line-oriented data files using a grep-like approach, then loads results via `data.table::fread` for downstream processing.

## Key Features

- Construct-and-read workflow: build command → read efficiently → targeted cleanup
- Column targeting, counts, line numbers, file names, word boundaries, case-insensitivity, literals
- Windows-friendly: uses `fread` + in-R filtering when external grep is not available
- Robust quality checks: file existence, size hints, binary detection

## Installation

```r
# from a local checkout
# install.packages("devtools")
# devtools::install()
```

## Usage

Basic filtering:

```r
res <- grep_read(files = "data/diamonds.csv", pattern = "Ideal")
```

Counts only:

```r
cnt <- grep_read(files = "data/diamonds.csv", pattern = "Ideal", count_only = TRUE)
```

Only the matched substring:

```r
mt <- grep_read(files = "data/diamonds.csv", pattern = "Ideal", only_matching = TRUE)
```

Column-specific search:

```r
res <- grep_read(files = "data/small_diamonds.csv", pattern = "Ideal", search_column = "cut")
```

## Development Notes

- Core entry point: `R/grep_read.r`
- Utilities: `R/utils.r`
- Clean `NAMESPACE`, `DESCRIPTION`
- Comprehensive tests: run

```r
source("test_comprehensive.R")
source("test_complex.R")
```

## Acknowledgments

This work was completed under Google Summer of Code (GSoC) 2025 with mentor guidance focused on modularity, performance, and robust testing. Thank you!