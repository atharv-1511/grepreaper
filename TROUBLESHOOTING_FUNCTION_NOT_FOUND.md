# Troubleshooting: "could not find function grep_read"

## 🚨 **Problem Description**

After installing the grepreaper package, you get the error:
```
✗ Basic pattern matching ERROR: could not find function "grep_read"
```

## 🔍 **Root Cause**

This happens because:
1. ✅ **Package installed successfully** from GitHub
2. ❌ **Package not loaded** into the R session
3. ❌ **Function not available** for testing

## 🛠️ **Solution Steps**

### **Step 1: Load the Package**
After installation, you MUST load the package:

```r
library(grepreaper)
```

### **Step 2: Verify Function Availability**
Check if the function is now available:

```r
ls("package:grepreaper")
```

You should see `grep_read` in the list.

### **Step 3: Test Function Call**
Try a simple function call:

```r
grep_read(files = "C:\\Users\\Atharv Raskar\\Downloads\\diamonds.csv", 
          pattern = "VVS1", 
          fixed = TRUE)
```

## 🚀 **Recommended Approach**

### **Option A: Use the Robust Installation Script (Recommended)**
```r
source('robust_installation_test.R')
```

This script:
- ✅ Completely removes old package
- ✅ Installs fresh copy
- ✅ Loads package automatically
- ✅ Verifies function availability
- ✅ Tests basic functionality

### **Option B: Manual Fix**
If you prefer manual approach:

```r
# 1. Remove old package
if("grepreaper" %in% rownames(installed.packages())) {
  detach("package:grepreaper", unload = TRUE, character.only = TRUE)
  remove.packages("grepreaper")
}

# 2. Install fresh copy
devtools::install_github("atharv-1511/grepreaper", dependencies = FALSE)

# 3. Load package
library(grepreaper)

# 4. Verify function
ls("package:grepreaper")
```

## 🔧 **Why This Happens**

### **Common Scenarios:**
1. **Package installed but not loaded** - Most common cause
2. **Multiple R sessions** - Package installed in one, used in another
3. **Installation errors** - Package appears installed but is corrupted
4. **Namespace conflicts** - Other packages masking the function

### **Prevention:**
- Always run `library(grepreaper)` after installation
- Use the robust installation script for reliability
- Check function availability before running tests

## 📋 **Verification Checklist**

After installation, verify these steps:

- [ ] Package shows in `installed.packages()`
- [ ] `library(grepreaper)` runs without errors
- [ ] `ls("package:grepreaper")` shows `grep_read`
- [ ] `grep_read` function responds to `args(grep_read)`
- [ ] Basic function call works with test data

## 🎯 **Expected Results**

When working correctly, you should see:

```r
> library(grepreaper)
> ls("package:grepreaper")
[1] "grep_read"
> args(grep_read)
function (files = NULL, path = NULL, file_pattern = NULL, pattern = "", 
    invert = FALSE, ignore_case = TRUE, fixed = FALSE, show_cmd = FALSE, 
    recursive = FALSE, word_match = FALSE, show_line_numbers = FALSE, 
    only_matching = FALSE, count_only = FALSE, nrows = Inf, skip = 0, 
    header = TRUE, col.names = NULL, include_filename = NULL, 
    search_column = NULL, show_progress = FALSE, ...)
```

## 🚨 **If Problem Persists**

If the function is still not found after following these steps:

1. **Restart R session** completely
2. **Check for errors** during package loading
3. **Verify package version** with `packageVersion("grepreaper")`
4. **Use robust installation script** for complete reinstall
5. **Check R console output** for any error messages

## 🔗 **Related Files**

- **`robust_installation_test.R`** - Complete solution script
- **`comprehensive_package_test_final.R`** - Testing after installation
- **`install_grepreaper_simple.R`** - Simple installation backup

---

**Remember: Always load the package with `library(grepreaper)` after installation!**
