# Troubleshooting Guide for Grepreaper Test Scripts

## Common Issues and Solutions

### 1. R Console Stuck in "+" Mode

**Problem**: The R console shows `+` instead of `>` and waits for input.

**Causes**:
- Incomplete R commands or syntax errors
- Missing closing braces `}` or parentheses `)`
- Unclosed quotes or strings

**Solutions**:
1. **Press Ctrl+C** to cancel the current command
2. **Check for syntax errors** in the script
3. **Use the simple test script** first: `simple_test_other_device.R`

### 2. Package Installation Fails

**Problem**: Cannot install grepreaper from GitHub.

**Solutions**:
1. **Check internet connection**
2. **Verify R version compatibility** (R 4.0+ recommended)
3. **Check write permissions** to R library directory
4. **Try the simple test script** which has multiple fallback methods

### 3. Script Hangs or Freezes

**Problem**: Script runs but doesn't complete.

**Solutions**:
1. **Use Ctrl+C** to interrupt
2. **Run in smaller sections** by commenting out parts
3. **Check R console for error messages**
4. **Use the simple test script** for basic functionality

## Recommended Testing Order

1. **Start with installation script**: `install_grepreaper.R`
2. **If successful**, try the simple test: `simple_test_other_device.R`
3. **If successful**, try the comprehensive test: `comprehensive_test_other_device.R`
4. **If issues persist**, use the installation script first

## Running the Installation Script

```r
# Copy the script to your device
# Run in R console:
source('install_grepreaper.R')
```

## Running the Simple Test

```r
# Copy the script to your device
# Update file paths if needed
# Run in R console:
source('simple_test_other_device.R')
```

## Manual Installation Steps

If automatic installation fails:

1. **Download manually** from: https://github.com/atharv-1511/grepreaper/archive/refs/heads/main.zip
2. **Extract the ZIP file**
3. **In R console**:
   ```r
   install.packages("path/to/extracted/grepreaper", repos = NULL, type = "source")
   ```

## Getting Help

1. **Check R console output** for specific error messages
2. **Verify R version**: `R.version.string`
3. **Check available packages**: `installed.packages()`
4. **Test basic R functionality**: `1 + 1`

## File Paths

**Important**: Update the file paths in the scripts to match your system:
- Windows: `C:\\Users\\YourName\\Downloads\\filename.csv`
- Mac/Linux: `/Users/YourName/Downloads/filename.csv`

## Expected Output

Successful execution should show:
- ✅ Package removed successfully
- ✅ grepreaper installed successfully
- ✅ grepreaper package loaded successfully
- ✅ Basic test PASSED
- === TEST COMPLETION ===
