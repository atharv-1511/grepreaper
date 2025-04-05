\name{grep_read}
\alias{grep_read}
\title{Read and filter data from one or more files using grep}

\description{
This function reads data from one or more files after filtering it with grep.
It allows for flexible pattern matching and leverages data.table's fread for efficient data import.
When reading from multiple files with the same structure, it can automatically combine the results.
}

\usage{
grep_read(files, pattern, invert = FALSE, ignore_case = FALSE, 
         fixed = FALSE, show_cmd = FALSE, recursive = FALSE,
         word_match = FALSE, nrows = Inf, skip = 0, 
         header = TRUE, col.names = NULL, ...)
}

\arguments{
  \item{files}{Character vector of file paths.}
  \item{pattern}{Pattern to search for.}
  \item{invert}{Logical; if TRUE, return non-matching lines.}
  \item{ignore_case}{Logical; if TRUE, perform case-insensitive matching.}
  \item{fixed}{Logical; if TRUE, pattern is a fixed string, not a regular expression.}
  \item{show_cmd}{Logical; if TRUE, print the grep command used.}
  \item{recursive}{Logical; if TRUE, search recursively through directories.}
  \item{word_match}{Logical; if TRUE, match only whole words.}
  \item{nrows}{Integer; maximum number of rows to read, passed to fread.}
  \item{skip}{Integer; number of rows to skip, passed to fread.}
  \item{header}{Logical; indicates if the data has a header row, passed to fread.}
  \item{col.names}{Character vector of column names, passed to fread.}
  \item{...}{Additional arguments passed to data.table::fread.}
}

\value{
A data.table containing the matched data. When reading from multiple files, 
a source_file column is added to indicate which file each row came from.
If \code{show_cmd=TRUE}, returns the command string instead.
}

\examples{
\dontrun{
# Read lines containing "IT" from sample_data.csv
it_employees <- grep_read("data/sample_data.csv", "IT")

# Read lines not containing "IT"
non_it_employees <- grep_read("data/sample_data.csv", "IT", invert = TRUE)

# Read from multiple files with the same structure
all_data <- grep_read(c("data/file1.csv", "data/file2.csv"), "pattern")

# Read only specific lines with header control
top_rows <- grep_read("data/sample_data.csv", "pattern", nrows = 10, header = TRUE)

# Case-insensitive search
grep_read("data/sample_data.csv", "it", ignore_case = TRUE)
}
}

\seealso{
\code{\link{grep_count}}, \code{\link{grep_files}}, \code{\link{grep_context}}
}
