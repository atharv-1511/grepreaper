# Google Summer of Code (GSoC) 2025 – grepreaper

## Project Summary
- Organization: grepreaper (R package)
- Student: Atharv Raskar
- Mentor: David Shilane
- Period: GSoC 2025

`grepreaper` provides efficient, grep-style filtering and reading of large line-oriented files, returning results as `data.table` for downstream analysis. The project refactored a monolithic implementation into a robust, modular, and well-tested package ready for production and future contributions.

---

## Objectives and Outcomes
- Refactor the ~1000-line `grep_read` into small, testable helpers
- Eliminate deep if/else chains and duplicated command-building logic
- Replace row-wise loops and repeated binds with vectorized `data.table`
- Fix counting logic and ensure numeric `count`
- Support Windows reliably (use `fread` + in-R filtering when external `grep` is not ideal)
- Reinstate quality checks (file existence/size, binary detection)
- Provide comprehensive, automated tests and documentation

All objectives were completed. The codebase is modular, lint-free for updated files, and fully covered by two comprehensive test suites.

---

## Architecture and Design

### High-level Flow (grep_read)
1) Validate inputs and prepare files
2) Build grep command string (or return it when `show_cmd = TRUE`)
3) Read data via `fread` (single or multiple files) and perform R-side filtering/cleanup
4) Apply targeted processing: metadata columns, header removal, type restoration
5) Return requested structure (rows, line numbers, filenames, only-matching substrings, counts)

### Key Files
- `R/grep_read.r` (main entry + helpers)
- `R/utils.r` (shared utilities)
- `man/` (documentation)
- `test_comprehensive.R`, `test_complex.R` (runtime test scripts)

### Main Helpers (selection)
- `validate_and_prepare_files()`, `validate_parameters()`
- `check_files_exist()`, `check_file_sizes()`
- `build_grep_command_string()`, `build_grep_command()`
- `read_data_with_grep()`
- `process_count_data()`
- `process_data_with_metadata()` → `process_metadata_columns()`
- `remove_header_rows()`, `restore_data_types()`
- `extract_only_matches()` (for `only_matching = TRUE`)

### Utilities
- `build_grep_cmd()` – constructs grep command with options
- `split.columns()` – fast split of delimited text vectors
- `is_binary_file()`, `check_grep_availability()`, `get_system_info()`

---

## Algorithms and Implementation Notes
- Performance is achieved by avoiding loops and using `data.table` vector operations
- When `only_matching = TRUE`, matches are extracted via compiled regex using `regexpr` on per-row text
- Header removal is targeted and conservative; types are restored using a shallow sample via `fread(nrows = 2)`
- Counting: single file returns a single-row table; multi-file returns per-file counts
- Metadata handling (line numbers, filename) is added only when requested to minimize overhead

---

## Platform Compatibility
- Windows: external `grep` is optional; core logic uses `data.table::fread` and R-side filtering to ensure reliability
- Case-insensitivity, word boundaries, and fixed matching are implemented with portable R regex features

---

## Testing and Verification

### Test Suites
- `test_comprehensive.R` (43 tests):
  - File availability
  - Package structure (functions present, dependencies)
  - Core `grep_read` operations (basic, patterns, counts, line numbers, show_cmd, multi-file)
  - Helper functions (build, split, binary check, grep availability, system info)
  - Edge cases (empty/long patterns, special characters, missing files, invalid params)
  - Performance smoke tests across datasets
  - Advanced features (ignore_case, regex, combined options)
- `test_complex.R` (45 tests):
  - Advanced scenarios (only_matching, word boundaries, invert, nrows/skip, fixed/literal)
  - Dataset-pattern matrix across all files in `data/` (per-file checks: basic read, only-matching, count-only, ignore_case, word boundaries)

### Results
- `test_comprehensive.R`: 43/43 PASS (100%) in ~1s
- `test_complex.R`: 45/45 PASS (100%) in ~1s

---

## Benchmarks (local indicative)
- Small files (<1 MB): <0.1s
- Medium files (1–10 MB): ~0.2–0.6s
- Large file (`diamonds.csv` ~2.4 MB here): ~0.01–0.05s for filtered reads in our environment

Note: Performance depends on I/O and system resources; the design favors scalability via `data.table`.

---

## Installation & Quick Start

1) Dependencies:
```r
install.packages("data.table")
```
2) Run tests:
```r
source("test_comprehensive.R")
source("test_complex.R")
```
3) Usage examples:
```r
# Basic
res <- grep_read(files = "data/diamonds.csv", pattern = "Ideal")

# Counts
cnt <- grep_read(files = "data/diamonds.csv", pattern = "Ideal", count_only = TRUE)

# Only matched substring
mt <- grep_read(files = "data/diamonds.csv", pattern = "Ideal", only_matching = TRUE)

# Column-specific
res_col <- grep_read(files = "data/small_diamonds.csv", pattern = "Ideal", search_column = "cut")
```

---

## Limitations and Edge Cases
- `only_matching` extracts first match per row; multiple-match extraction could be added later
- When data contain embedded delimiters or unusual encodings, behavior depends on `fread` parsing
- Very large binary or compressed files are not automatically handled

---

## Future Work
- Optional multi-match extraction for `only_matching`
- Native streaming from external grep when available (with cross-platform abstraction)
- CRAN-style automated tests under `tests/testthat`
- Additional vignettes for complex pipelines and log formats

---

## Evaluation Checklist
- GSoC attribution present in `README.md` and this report
- Refactor aligns with mentor feedback (modularity, no deep if/else, vectorized ops)
- Quality checks and correctness (counts, types) implemented
- Cross-dataset tests: all green with comprehensive coverage
- Lint: updated files pass linting

---

## Timeline (High-Level)
- Week 1–2: Discovery, baseline testing, mentor feedback analysis
- Week 3–5: Full refactor into helpers; fix quality checks and counting
- Week 6–7: Windows compatibility path (fread + R filtering)
- Week 8–9: Comprehensive and complex test suites
- Week 10: Documentation updates (README, vignettes alignment)
- Week 11–12: Final polish, lint checks, report preparation

---

## Acknowledgment
Many thanks to mentor David Shilane for targeted feedback that substantially improved modularity, performance, and reliability; and to GSoC for the opportunity to contribute.
