# 🔬 Advanced Complex Tests for grepreaper
cat("🔬 RUNNING ADVANCED COMPLEX TESTS FOR GREPREAPER\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

# Load dependencies and package functions
suppressWarnings({
  if (requireNamespace("data.table", quietly = TRUE)) library(data.table)
})

load_ok <- TRUE
if (file.exists("R/utils.r")) {
  tryCatch(source("R/utils.r"), error = function(e) { load_ok <<- FALSE; cat("❌ Failed to source R/utils.r:", e$message, "\n") })
} else { load_ok <- FALSE; cat("❌ R/utils.r not found\n") }
if (file.exists("R/grep_read.r")) {
  tryCatch(source("R/grep_read.r"), error = function(e) { load_ok <<- FALSE; cat("❌ Failed to source R/grep_read.r:", e$message, "\n") })
} else { load_ok <- FALSE; cat("❌ R/grep_read.r not found\n") }
if (!load_ok) stop("Required R files could not be loaded.")

ok <- function(name) cat("  ✅", name, "- PASS\n")
fail <- function(name, msg) cat("  ❌", name, "- FAIL:", msg, "\n")
warn <- function(name, msg) cat("  ⚠️", name, "- WARN:", msg, "\n")

results <- list(total=0, pass=0, fail=0, warn=0)
log_pass <- function(){results$total<<-results$total+1;results$pass<<-results$pass+1}
log_fail <- function(){results$total<<-results$total+1;results$fail<<-results$fail+1}
log_warn <- function(){results$total<<-results$total+1;results$warn<<-results$warn+1}

# Helper: safe call
safe <- function(expr, on_ok, on_fail){
  tryCatch({ expr; on_ok() }, error=function(e){ on_fail(e$message) })
}

# Paths
files_all <- c(
  "data/sample_data.csv",
  "data/small_diamonds.csv",
  "data/diabetes.csv",
  "data/diamonds.csv",
  "data/Employers_data.csv",
  "data/academic Stress level - maintainance 1.csv",
  "data/Hearing well-being Survey Report.csv"
)
files_exist <- files_all[file.exists(files_all)]

cat("📁 Files available:", length(files_exist), "of", length(files_all), "\n\n")

# 1) Multi-file, combined, metadata columns
cat("1) Multi-file with metadata columns (filename + line numbers)\n")
safe({
  res <- grep_read(files=files_exist, pattern="", include_filename=TRUE, show_line_numbers=TRUE, nrows=100)
  stopifnot(is.data.frame(res), nrow(res) >= 1, all(c("source_file","line_number") %in% names(res)))
}, function(){ ok("Multi-file metadata"); log_pass() }, function(m){ fail("Multi-file metadata", m); log_fail() })

# 2) Column-specific search on diamonds (cut == "Ideal")
if (file.exists("data/small_diamonds.csv")) {
  cat("2) Column-specific search: cut == 'Ideal' on small_diamonds\n")
  safe({
    res <- grep_read(files="data/small_diamonds.csv", pattern="Ideal", search_column="cut", include_filename=TRUE)
    stopifnot(is.data.frame(res), nrow(res) >= 1)
    if ("cut" %in% names(res)) {
      stopifnot(all(grepl("Ideal", as.character(res$cut), fixed=TRUE)))
    }
  }, function(){ ok("search_column=\"cut\""); log_pass() }, function(m){ fail("search_column=\"cut\"", m); log_fail() })
} else { warn("search_column test", "small_diamonds.csv not found"); log_warn() }

# 3) only_matching TRUE returns includes 'match' column
cat("3) only_matching=TRUE extracts matches in 'match' column\n")
safe({
  res <- grep_read(files="data/sample_data.csv", pattern="test", only_matching=TRUE)
  stopifnot(is.data.frame(res), "match" %in% names(res))
  if (nrow(res) == 0) warn("only_matching", "no matches found in sample_data for 'test'") else ok("only_matching")
}, function(){ log_pass() }, function(m){ fail("only_matching", m); log_fail() })

# 4) Word-boundary vs non-word-boundary
cat("4) word_match effect (\\btest\\b vs test)\n")
safe({
  res_word <- grep_read(files="data/sample_data.csv", pattern="test", word_match=TRUE)
  res_any  <- grep_read(files="data/sample_data.csv", pattern="test", word_match=FALSE)
  stopifnot(is.data.frame(res_word), is.data.frame(res_any))
  stopifnot(nrow(res_any) >= nrow(res_word))
}, function(){ ok("word_match"); log_pass() }, function(m){ fail("word_match", m); log_fail() })

# 5) invert TRUE
cat("5) invert=TRUE excludes pattern\n")
safe({
  res_all <- grep_read(files="data/sample_data.csv", pattern="")
  res_not <- grep_read(files="data/sample_data.csv", pattern="test", invert=TRUE)
  stopifnot(nrow(res_not) <= nrow(res_all))
}, function(){ ok("invert"); log_pass() }, function(m){ fail("invert", m); log_fail() })

# 6) Count-only across multiple files
cat("6) count_only across multiple files\n")
safe({
  res <- grep_read(files=files_exist, pattern="Ideal|diabetes|stress", ignore_case=TRUE, count_only=TRUE)
  stopifnot(is.data.frame(res), all(c("source_file","count") %in% names(res)))
  stopifnot(all(res$count >= 0))
}, function(){ ok("count_only multi-file"); log_pass() }, function(m){ fail("count_only multi-file", m); log_fail() })

# 7) nrows and skip
cat("7) nrows and skip on diamonds\n")
if (file.exists("data/diamonds.csv")) {
  safe({
    r1 <- grep_read(files="data/diamonds.csv", pattern="", nrows=10)
    r2 <- grep_read(files="data/diamonds.csv", pattern="", nrows=10, skip=10)
    stopifnot(nrow(r1) == 10, nrow(r2) == 10)
  }, function(){ ok("nrows/skip"); log_pass() }, function(m){ fail("nrows/skip", m); log_fail() })
} else { warn("nrows/skip", "diamonds.csv not found"); log_warn() }

# 8) fixed=TRUE literal matching should not interpret regex
cat("8) fixed=TRUE literal matching\n")
safe({
  res_regex <- grep_read(files="data/sample_data.csv", pattern=".")
  res_fixed <- grep_read(files="data/sample_data.csv", pattern=".", fixed=TRUE)
  stopifnot(nrow(res_regex) >= nrow(res_fixed))
}, function(){ ok("fixed literal"); log_pass() }, function(m){ fail("fixed literal", m); log_fail() })

# 9) show_cmd returns a command string
cat("9) show_cmd returns command string\n")
safe({
  cmd <- grep_read(files=files_exist[1], pattern="test", show_cmd=TRUE)
  stopifnot(is.character(cmd), length(cmd) == 1, nchar(cmd) > 0)
}, function(){ ok("show_cmd"); log_pass() }, function(m){ fail("show_cmd", m); log_fail() })

# 10) Performance smoke on large file
cat("10) Performance smoke test (large file if present)\n")
if (file.exists("data/diamonds.csv")) {
  t0 <- Sys.time()
  safe({
    res <- grep_read(files="data/diamonds.csv", pattern="Ideal|Premium|Good", ignore_case=TRUE)
    stopifnot(is.data.frame(res))
  }, function(){
    dt <- round(as.numeric(difftime(Sys.time(), t0, units="secs")), 3)
    ok(paste0("performance (", dt, "s)")); log_pass()
  }, function(m){ fail("performance", m); log_fail() })
} else { warn("performance", "diamonds.csv not found"); log_warn() }

# 11) Dataset-pattern matrix across all available files
cat("\n11) Dataset-pattern matrix across available datasets\n")
# Generic patterns that should work across many files
matrix_patterns <- list(
  basic = "",               # baseline read
  dot = ".",                # any single character (for only_matching)
  any = ".*",               # any content
  digits = "[0-9]",         # digits if present
  alpha = "[A-Za-z]"        # letters if present
)

for (f in files_exist) {
  cat("   → File:", f, "\n")
  # Basic read should always return a data.frame
  safe({
    r <- grep_read(files=f, pattern=matrix_patterns$basic)
    stopifnot(is.data.frame(r))
  }, function(){ ok(paste0("matrix basic [", basename(f), "]")); log_pass() }, function(m){ fail(paste0("matrix basic [", basename(f), "]"), m); log_fail() })

  # only_matching with dot '.' should return a match column, may be empty on empty files
  safe({
    r <- grep_read(files=f, pattern=matrix_patterns$dot, only_matching=TRUE)
    stopifnot(is.data.frame(r), "match" %in% names(r))
    if (nrow(r) == 0) warn(paste0("matrix only_matching [", basename(f), "]"), "no matches for '.' (file may be empty or parsed structurally)") else ok(paste0("matrix only_matching [", basename(f), "]"))
  }, function(){ log_pass() }, function(m){ fail(paste0("matrix only_matching [", basename(f), "]"), m); log_fail() })

  # count_only with any pattern
  safe({
    r <- grep_read(files=f, pattern=matrix_patterns$any, count_only=TRUE)
    stopifnot(is.data.frame(r), all(c("source_file","count") %in% names(r)))
  }, function(){ ok(paste0("matrix count_only [", basename(f), "]")); log_pass() }, function(m){ fail(paste0("matrix count_only [", basename(f), "]"), m); log_fail() })

  # case-insensitive search; shouldn't error
  safe({
    r <- grep_read(files=f, pattern="A", ignore_case=TRUE)
    stopifnot(is.data.frame(r))
  }, function(){ ok(paste0("matrix ignore_case [", basename(f), "]")); log_pass() }, function(m){ fail(paste0("matrix ignore_case [", basename(f), "]"), m); log_fail() })

  # word boundary test on a generic token 'the' – downgrade to warn if 0 rows
  safe({
    r <- grep_read(files=f, pattern="the", word_match=TRUE)
    stopifnot(is.data.frame(r))
    if (nrow(r) == 0) warn(paste0("matrix word_match [", basename(f), "]"), "no whole-word 'the' occurrences") else ok(paste0("matrix word_match [", basename(f), "]"))
  }, function(){ log_pass() }, function(m){ fail(paste0("matrix word_match [", basename(f), "]"), m); log_fail() })
}

# Final summary
cat("\n📊 COMPLEX TEST SUMMARY\n")
cat(paste(rep("-", 80), collapse = ""), "\n")
cat("Total:", results$total, " Pass:", results$pass, " Fail:", results$fail, " Warn:", results$warn, "\n")
if (results$fail == 0) {
  cat("✅ All complex tests passed or warned appropriately. Ready for mentor review.\n")
} else {
  cat("❌ Some complex tests failed. Please review before mentor submission.\n")
}
