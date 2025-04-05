\name{grep_context}
\alias{grep_context}
\title{Search for pattern with context lines}

\description{
This function searches for a pattern in files and returns matches with context lines
before and after each match, similar to grep -A and -B options. This provides better 
understanding of the context in which the pattern appears.
}

\usage{
grep_context(files, pattern, before = 0, after = 0, invert = FALSE, 
            ignore_case = FALSE, fixed = FALSE, show_cmd = FALSE, 
            recursive = FALSE, word_match = FALSE, as_data_table = FALSE)
}

\arguments{
  \item{files}{Character vector of file paths.}
  \item{pattern}{Pattern to search for.}
  \item{before}{Integer; number of lines to show before each match.}
  \item{after}{Integer; number of lines to show after each match.}
  \item{invert}{Logical; if TRUE, show non-matching lines.}
  \item{ignore_case}{Logical; if TRUE, perform case-insensitive matching.}
  \item{fixed}{Logical; if TRUE, pattern is a fixed string, not a regular expression.}
  \item{show_cmd}{Logical; if TRUE, print the grep command used.}
  \item{recursive}{Logical; if TRUE, search recursively through directories.}
  \item{word_match}{Logical; if TRUE, match only whole words.}
  \item{as_data_table}{Logical; if TRUE, return a data.table instead of character vector.}
}

\value{
If \code{as_data_table=FALSE}, returns a character vector of matched lines with context.
If \code{as_data_table=TRUE}, returns a data.table with columns: file, line_num, content, and match_type.
The match_type column indicates whether each line is a match, before context, after context, or separator.
If \code{show_cmd=TRUE}, returns the command string instead.
}

\examples{
\dontrun{
# Search for "IT" with 2 lines before and after each match
grep_context("data/sample_data.csv", "IT", before = 2, after = 2)

# Return results as a data.table with source and line information
result_dt <- grep_context("data/sample_data.csv", "IT", 
                         before = 1, after = 1, as_data_table = TRUE)
                         
# Use case-insensitive matching
grep_context("data/sample_data.csv", "it", ignore_case = TRUE, 
            before = 1, after = 1)
            
# Show the command that would be executed
grep_context("data/sample_data.csv", "IT", before = 2, after = 2, show_cmd = TRUE)
}
}

\seealso{
\code{\link{grep_count}}, \code{\link{grep_read}}, \code{\link{grep_files}}
} 