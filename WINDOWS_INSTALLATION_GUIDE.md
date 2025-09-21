# Windows Installation Guide for grepreaper Package

## Prerequisites Setup

### Step 1: Set Git PATH (Required for Windows)
```r
# Run this command first in R/RStudio
Sys.setenv(PATH = paste("C:/Program Files/Git/usr/bin", Sys.getenv("PATH"),sep=";"))
```

### Step 2: Verify Git is Available
```r
# Check if git is now accessible
system("git --version")
# Should output: git version 2.x.x
```

## Installation Steps

### Step 3: Install Required R Packages
```r
# Install essential packages
install.packages(c("devtools", "data.table"))

# Verify installation
library(devtools)
library(data.table)
```

### Step 4: Clone the Repository
```r
# Method 1: Using R (recommended)
devtools::install_git("https://github.com/atharv-1511/grepreaper.git")

# Method 2: Using system command
system("git clone https://github.com/atharv-1511/grepreaper.git")
```

### Step 5: Navigate to Package Directory
```r
# Set working directory
setwd("grepreaper")

# Verify you're in the right directory
list.files()
# Should show: DESCRIPTION, NAMESPACE, R/, data/, etc.
```

### Step 6: Load the Package
```r
# Load the package for development
devtools::load_all()

# Verify functions are available
exists("grep_read")
exists("grep_count")
```

## Testing Steps

### Step 7: Run Quick Test
```r
# Run the quick test
source("quick_test.R")
```

### Step 8: Run Comprehensive Test
```r
# Run the full cross-device test
source("CROSS_DEVICE_TEST.R")
```

### Step 9: Manual Function Testing
```r
# Test grep_read function
result1 <- grep_read(files = "data/diamonds.csv", pattern = "Ideal", nrows = 5)
print(result1)

# Test grep_count function
result2 <- grep_count(files = "data/diamonds.csv", pattern = "Ideal")
print(result2)

# Test with different patterns
result3 <- grep_read(files = "data/diamonds.csv", pattern = "Premium", nrows = 3)
print(result3)
```

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Git Command Not Found
```r
# Solution: Check Git installation path
system("where git")
# If not found, install Git from: https://git-scm.com/download/win
```

#### Issue 2: Package Loading Failed
```r
# Solution: Check dependencies
install.packages(c("devtools", "data.table"))
# Then retry
devtools::load_all()
```

#### Issue 3: File Not Found
```r
# Solution: Check working directory
getwd()
list.files()
# Ensure you're in the grepreaper directory
```

#### Issue 4: Permission Denied
```r
# Solution: Run R as Administrator
# Or change directory permissions
```

## Expected Results

### Successful Installation Output
```
> devtools::load_all()
Loading grepreaper
> exists("grep_read")
[1] TRUE
> exists("grep_count")
[1] TRUE
```

### Successful Test Output
```
=== GREPREAPER QUICK TEST ===
Platform: x86_64-w64-mingw32
R Version: R version 4.3.2 (2023-10-31)

Testing functions...
grep_read available: TRUE
grep_count available: TRUE
Testing basic functionality...
grep_read result: 3 rows
grep_count result: 1 rows
✅ All tests passed!
Test completed!
```

## Alternative Installation Methods

### Method 1: Direct GitHub Installation
```r
# Install directly from GitHub
devtools::install_github("atharv-1511/grepreaper")
```

### Method 2: Local Package Installation
```r
# If you have the package files locally
devtools::install(".")
```

### Method 3: Manual Download
```r
# Download ZIP from GitHub
# Extract to local directory
# Set working directory to extracted folder
setwd("path/to/grepreaper")
devtools::load_all()
```

## Verification Checklist

- [ ] Git PATH set correctly
- [ ] Required packages installed (devtools, data.table)
- [ ] Repository cloned successfully
- [ ] Working directory set to grepreaper folder
- [ ] Package loaded without errors
- [ ] All functions available (grep_read, grep_count, split.columns, build_grep_cmd)
- [ ] Quick test passes
- [ ] Comprehensive test passes
- [ ] Manual function tests work

## Support

If you encounter any issues:
1. Check the troubleshooting section above
2. Verify all prerequisites are installed
3. Ensure you're following the steps in order
4. Check the console output for error messages
5. Contact the development team with specific error details
