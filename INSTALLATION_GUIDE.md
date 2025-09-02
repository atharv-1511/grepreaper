# 📦 Installation Guide for Grepreaper Package

## 🚨 **Common Installation Issues & Solutions**

### **Issue 1: Rtools Compatibility Error**
```
WARNING: Rtools is required to build R packages, but no version of Rtools compatible with R 4.3.2 was found.
```

**Solution**: Install the correct version of Rtools for your R version:
- **For R 4.3.x**: Download and install [Rtools 4.3](https://cran.r-project.org/bin/windows/Rtools/)
- **For R 4.4.x**: Download and install [Rtools 4.4](https://cran.r-project.org/bin/windows/Rtools/)
- **For R 4.5.x**: Download and install [Rtools 4.5](https://cran.r-project.org/bin/windows/Rtools/)

### **Issue 2: NAMESPACE File Error**
```
Error in if (any(r == "")) stop(gettextf("empty name in directive '%s' in 'NAMESPACE' file"
```

**Solution**: This has been fixed! The NAMESPACE file has been cleaned up and simplified.

## 🚀 **Installation Methods**

### **Method 1: Install from Local Directory (Recommended)**

```r
# Step 1: Install required dependencies
install.packages(c("devtools", "data.table"))

# Step 2: Load devtools
library(devtools)

# Step 3: Install from local directory
# Replace with your actual path to the grepreaper folder
devtools::install("C:\\Users\\YourUsername\\Desktop\\grepreaper")

# Step 4: Load the package
library(grepreaper)
```

### **Method 2: Install from GitHub (Alternative)**

```r
# Install directly from GitHub
devtools::install_github("yourusername/grepreaper")

# Load the package
library(grepreaper)
```

### **Method 3: Manual Installation (If devtools fails)**

```r
# Step 1: Set working directory to package folder
setwd("C:\\Users\\YourUsername\\Desktop\\grepreaper")

# Step 2: Build the package
system("R CMD build .")

# Step 3: Install the built package
install.packages("grepreaper_0.1.0.tar.gz", repos = NULL, type = "source")

# Step 4: Load the package
library(grepreaper)
```

### **Method 4: Source Functions Directly (Quick Test)**

If installation continues to fail, you can source the functions directly:

```r
# Step 1: Set working directory to the package folder
setwd("C:\\Users\\YourUsername\\Desktop\\grepreaper")

# Step 2: Source the functions directly
source("R/utils.r")
source("R/grep_read.r")

# Step 3: Install data.table if not already installed
if (!require(data.table)) {
  install.packages("data.table")
  library(data.table)
}

# Step 4: Test the function
result <- grep_read(files = "path/to/your/test/file.csv", pattern = "test")
```

## 🔧 **Troubleshooting Steps**

### **Step 1: Check R Version**
```r
R.version.string
```
Ensure you have R 4.0.0 or higher.

### **Step 2: Check Rtools Installation**
```r
# Check if Rtools is installed
system("where Rtools")
# or
system("Rtools --version")
```

### **Step 3: Check Package Dependencies**
```r
# Install required packages
install.packages(c("data.table", "devtools", "utils", "stats"))
```

### **Step 4: Clean Installation**
```r
# Remove existing package if installed
if ("grepreaper" %in% installed.packages()) {
  remove.packages("grepreaper")
}

# Clear R environment
rm(list = ls())

# Restart R session
.rs.restartR()  # In RStudio
# or restart R completely
```

### **Step 5: Verify Package Structure**
Ensure your package folder contains:
```
grepreaper/
├── DESCRIPTION
├── NAMESPACE
├── LICENSE
├── R/
│   ├── grep_read.r
│   └── utils.r
├── man/
├── data/
└── vignettes/
```

## 🧪 **Testing Installation**

### **Quick Test**
```r
# Load the package
library(grepreaper)

# Test basic functionality
if (exists("grep_read")) {
  cat("✅ grep_read function loaded successfully!\n")
} else {
  cat("❌ grep_read function not found!\n")
}

# Test helper functions
helper_functions <- c("build_grep_cmd", "split.columns", "is_binary_file", 
                     "check_grep_availability", "get_system_info")

for (func in helper_functions) {
  if (exists(func)) {
    cat("✅", func, "function loaded successfully!\n")
  } else {
    cat("❌", func, "function not found!\n")
  }
}
```

### **Comprehensive Test**
```r
# Run the comprehensive test suite
source("COMPREHENSIVE_PACKAGE_TEST.R")
```

## 🌍 **Platform-Specific Instructions**

### **Windows**
1. Install Rtools for your R version
2. Ensure Rtools is in your PATH
3. Use Method 1 (devtools::install) for best results

### **macOS**
1. Install Xcode command line tools: `xcode-select --install`
2. Use Method 1 (devtools::install)

### **Linux**
1. Install build essentials: `sudo apt-get install build-essential`
2. Use Method 1 (devtools::install)

## 📞 **Getting Help**

If you continue to have installation issues:

1. **Check the error messages** - they often contain helpful information
2. **Verify file paths** - ensure they match your system
3. **Check R version compatibility** - ensure R 4.0.0+
4. **Review package dependencies** - ensure all required packages are installed
5. **Try Method 4** (sourcing functions directly) as a workaround

## 🎯 **Expected Results**

After successful installation:
- ✅ Package loads without errors
- ✅ All functions are available
- ✅ Comprehensive test suite passes
- ✅ Ready for production use

---

**🚀 Happy coding with the refactored grepreaper package! 🚀**
