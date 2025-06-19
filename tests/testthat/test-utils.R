test_that("check_grep_availability returns correct structure", {
  result <- check_grep_availability()
  
  # Check structure
  expect_type(result, "list")
  expect_named(result, c("available", "version", "path", "error"))
  expect_type(result$available, "logical")
  expect_type(result$version, "character")
  expect_type(result$path, "character")
  expect_type(result$error, "character")
})

test_that("check_grep_availability handles system info correctly", {
  sys_info <- get_system_info()
  result <- check_grep_availability()
  
  # Check platform-specific behavior
  if (sys_info$is_windows) {
    expect_true(is.null(result$error) || grepl("Windows", result$error))
  } else if (sys_info$os_name == "Darwin") {
    expect_true(is.null(result$error) || grepl("MacOS", result$error))
  } else {
    expect_true(is.null(result$error) || grepl("Unix", result$error))
  }
})

test_that("check_grep_availability provides installation instructions", {
  # Mock system info to test different platforms
  mock_sys_info <- function(os_type, os_name) {
    list(
      os_type = os_type,
      os_name = os_name,
      is_windows = os_type == "windows",
      is_unix = os_type == "unix"
    )
  }
  
  # Test Windows instructions
  with_mock(
    get_system_info = function() mock_sys_info("windows", "Windows"),
    {
      result <- check_grep_availability()
      expect_true(grepl("Git Bash", result$error) || 
                 grepl("MSYS2", result$error) || 
                 grepl("WSL", result$error))
    }
  )
  
  # Test MacOS instructions
  with_mock(
    get_system_info = function() mock_sys_info("unix", "Darwin"),
    {
      result <- check_grep_availability()
      expect_true(grepl("Homebrew", result$error) || 
                 grepl("MacPorts", result$error))
    }
  )
  
  # Test Linux instructions
  with_mock(
    get_system_info = function() mock_sys_info("unix", "Linux"),
    {
      result <- check_grep_availability()
      expect_true(grepl("apt-get", result$error) || 
                 grepl("yum", result$error) || 
                 grepl("pacman", result$error))
    }
  )
})

test_that("build_grep_cmd handles grep availability check", {
  # Test when grep is available
  with_mock(
    check_grep_availability = function() list(available = TRUE, error = NULL),
    {
      cmd <- build_grep_cmd("test", "file.txt")
      expect_type(cmd, "character")
      expect_true(grepl("grep", cmd))
    }
  )
  
  # Test when grep is not available
  with_mock(
    check_grep_availability = function() list(
      available = FALSE,
      error = "grep not found"
    ),
    {
      expect_error(build_grep_cmd("test", "file.txt"), "grep not found")
    }
  )
}) 