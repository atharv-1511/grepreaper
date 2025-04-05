\name{grep_count}
\alias{grep_count}
\title{Count occurrences matching a pattern in one or more files}

\description{
This function counts the number of lines in one or more files that match a given pattern.
It leverages the command-line grep utility for efficient pattern matching.
}

\usage{
grep_count(files, pattern, invert = FALSE, ignore_case = FALSE, 
          fixed = FALSE, show_cmd = FALSE, recursive = FALSE,
          word_match = FALSE)
}

\arguments{
  \item{files}{Character vector of file paths.}
  \item{pattern}{Pattern to search for.}
  \item{invert}{Logical; if TRUE, count non-matching lines.}
  \item{ignore_case}{Logical; if TRUE, perform case-insensitive matching.}
  \item{fixed}{Logical; if TRUE, pattern is a fixed string, not a regular expression.}
  \item{show_cmd}{Logical; if TRUE, print the grep command used.}
  \item{recursive}{Logical; if TRUE, search recursively through directories.}
  \item{word_match}{Logical; if TRUE, match only whole words.}
}

\value{
When searching a single file, returns an integer count of matching lines.
When searching multiple files, returns a named integer vector with counts for each file.
If \code{show_cmd=TRUE}, returns the command string instead.
}

\examples{
\dontrun{
# Count occurrences of "IT" in sample_data.csv
grep_count("data/sample_data.csv", "IT")

# Count non-matching lines (those not containing "IT")
grep_count("data/sample_data.csv", "IT", invert = TRUE)

# Search in multiple files
grep_count(c("data/file1.csv", "data/file2.csv"), "pattern")

# Show the command that would be executed
grep_count("data/sample_data.csv", "IT", show_cmd = TRUE)
}
}

\seealso{
\code{\link{grep_read}}, \code{\link{grep_files}}, \code{\link{grep_context}}
}