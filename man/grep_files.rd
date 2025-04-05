\name{grep_files}
\alias{grep_files}
\title{Find files containing pattern matches}

\description{
This function identifies which files contain lines that match the given pattern.
It returns only file names rather than the actual matching content, which is useful
for quickly identifying relevant files in a large collection.
}

\usage{
grep_files(files, pattern, invert = FALSE, ignore_case = FALSE, 
          fixed = FALSE, show_cmd = FALSE, recursive = FALSE,
          word_match = FALSE, one_per_file = FALSE)
}

\arguments{
  \item{files}{Character vector of file paths.}
  \item{pattern}{Pattern to search for.}
  \item{invert}{Logical; if TRUE, find files that don't contain the pattern.}
  \item{ignore_case}{Logical; if TRUE, perform case-insensitive matching.}
  \item{fixed}{Logical; if TRUE, pattern is a fixed string, not a regular expression.}
  \item{show_cmd}{Logical; if TRUE, print the grep command used.}
  \item{recursive}{Logical; if TRUE, search recursively through directories.}
  \item{word_match}{Logical; if TRUE, match only whole words.}
  \item{one_per_file}{Logical; if TRUE, return only the first match per file and don't compute match counts.}
}

\value{
Character vector of file paths containing matches. The vector includes an attribute named "counts"
that provides the number of matches in each file (unless one_per_file=TRUE).
If \code{show_cmd=TRUE}, returns a list with the commands that would be executed.
}

\examples{
\dontrun{
# Find files containing "IT"
it_files <- grep_files(c("data/file1.csv", "data/file2.csv"), "IT")

# Find files that don't contain "IT"
non_it_files <- grep_files(c("data/file1.csv", "data/file2.csv"), "IT", invert = TRUE)

# Get the match counts
match_counts <- attr(it_files, "counts")

# Search recursively in a directory
all_csv_files <- grep_files("data/", "pattern", recursive = TRUE)

# Show the commands that would be executed
grep_files(c("data/file1.csv", "data/file2.csv"), "IT", show_cmd = TRUE)
}
}

\seealso{
\code{\link{grep_count}}, \code{\link{grep_read}}, \code{\link{grep_context}}
} 