# Cross-Device Testing Guide for grepreaper Package

## Overview
This guide provides instructions for testing the grepreaper package across different platforms and environments to ensure compatibility and reliability.

## Prerequisites

### Required Software
- R (version 4.0.0 or higher)
- RStudio (recommended)
- Git (for cloning the repository)

### Required R Packages
```r
install.packages(c("devtools", "data.table"))
```

## Testing Instructions

### Step 1: Clone the Repository
```bash
git clone https://github.com/atharv-1511/grepreaper.git
cd grepreaper
```

### Step 2: Run Cross-Device Test
```r
# In R or RStudio
source("CROSS_DEVICE_TEST.R")
```

### Step 3: Manual Testing (Optional)
```r
# Load the package
library(devtools)
load_all()

# Test basic functionality
result <- grep_read(files = "data/diamonds.csv", pattern = "Ideal", nrows = 5)
print(result)

# Test counting
count_result <- grep_count(files = "data/diamonds.csv", pattern = "Ideal")
print(count_result)
```

## Platforms to Test

### Windows
- **Windows 10/11**
- **R 4.0+**
- **PowerShell/Command Prompt**

### Linux
- **Ubuntu 20.04+**
- **CentOS/RHEL 8+**
- **R 4.0+**

### macOS
- **macOS 10.15+**
- **R 4.0+**
- **Terminal**

## What to Test

### Core Functionality
1. **Function Availability**: All functions (`grep_read`, `grep_count`, `split.columns`, `build_grep_cmd`) should be available
2. **Basic Operations**: Reading and filtering data should work
3. **Pattern Matching**: Both regex and fixed string matching
4. **Edge Cases**: Empty results, no matches, invalid inputs

### Performance
1. **Speed**: Functions should complete within reasonable time
2. **Memory**: Should handle datasets without excessive memory usage
3. **Scalability**: Should work with different dataset sizes

### Platform Compatibility
1. **File Paths**: Different path formats should work
2. **Character Encoding**: UTF-8 support
3. **System Commands**: grep command execution should work

## Expected Results

### Successful Test Output
```
=== GREPREAPER CROSS-DEVICE TESTING ===
Testing grepreaper package functionality
Date: 2024-01-XX
Platform: x86_64-w64-mingw32
R Version: R version 4.3.2 (2023-10-31)

✅ All required packages available

Loading grepreaper package...
✅ Package loaded successfully

=== TEST 1: FUNCTION AVAILABILITY ===
✅ grep_read function available
✅ grep_count function available
✅ split.columns function available
✅ build_grep_cmd function available

=== TEST 2: BASIC FUNCTIONALITY ===
Testing grep_count...
✅ grep_count works - Result: 1 rows
Testing grep_read...
✅ grep_read works - Result: 3 rows
   Columns: carat, cut, color, clarity, depth, table, price, x, y, z

=== TEST 3: EDGE CASES ===
Testing no matches scenario...
✅ No matches handled correctly - Result: 0 rows
Testing empty pattern...
✅ Empty pattern handled correctly - Result: 3 rows

=== TEST 4: PERFORMANCE TEST ===
Testing performance with larger dataset...
✅ Performance test passed - Duration: 0.123 seconds
   Processed 100 rows

=== TEST 5: PLATFORM-SPECIFIC TESTS ===
Testing file path handling...
✅ Path format data/diamonds.csv works
✅ Path format ./data/diamonds.csv works

=== TEST 6: DATA TYPE PRESERVATION ===
✅ Data types preserved
   Column types: numeric, character, character, character, numeric, numeric, integer, numeric, numeric, numeric

=== TEST 7: MULTIPLE FILES TEST ===
Testing multiple files: 2 files available
✅ Multiple files test passed - Result: 5 rows

=== TESTING SUMMARY ===
Platform: x86_64-w64-mingw32
R Version: R version 4.3.2 (2023-10-31)
Package Version: 0.1.0
Test Date: 2024-01-XX
Test Time: 14:30:25

Cross-device testing completed!
Please share these results with the development team.
If any tests failed, please include the error messages.
```

## Troubleshooting

### Common Issues

#### 1. Package Loading Failed
```r
# Solution: Install missing dependencies
install.packages(c("devtools", "data.table"))
```

#### 2. Function Not Found
```r
# Solution: Ensure package is loaded
library(devtools)
load_all()
```

#### 3. File Not Found
```r
# Solution: Check working directory
getwd()
list.files("data")
```

#### 4. Permission Issues (Linux/macOS)
```bash
# Solution: Ensure proper permissions
chmod +x CROSS_DEVICE_TEST.R
```

## Reporting Results

### What to Include
1. **Platform Information**: OS, R version, architecture
2. **Test Results**: Success/failure for each test
3. **Error Messages**: Any error messages encountered
4. **Performance Metrics**: Execution times
5. **Screenshots**: If visual issues occur

### Where to Report
- **GitHub Issues**: Create an issue with test results
- **Email**: Send results to the development team
- **Documentation**: Update this guide with new findings

## Continuous Testing

### Automated Testing
- Set up CI/CD pipelines for automated testing
- Test on multiple platforms automatically
- Generate reports for each test run

### Manual Testing
- Test on new platforms as they become available
- Test with new R versions
- Test with updated dependencies

## Success Criteria

### Minimum Requirements
- ✅ All core functions available
- ✅ Basic functionality works
- ✅ No critical errors
- ✅ Reasonable performance

### Optimal Results
- ✅ All tests pass
- ✅ Fast execution times
- ✅ Consistent behavior across platforms
- ✅ No warnings or errors

## Support

### Getting Help
- **GitHub Issues**: Report bugs and request features
- **Documentation**: Check package documentation
- **Community**: R community forums

### Contributing
- **Testing**: Help test on different platforms
- **Documentation**: Improve testing guides
- **Code**: Contribute improvements and fixes
