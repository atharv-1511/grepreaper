% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.r
\name{safe_system_call}
\alias{safe_system_call}
\title{Execute a shell command safely}
\usage{
safe_system_call(cmd, intern = TRUE)
}
\arguments{
\item{cmd}{Command to execute.}

\item{intern}{Logical; if TRUE, capture the output.}
}
\value{
Command output as character vector, or empty vector on error.
}
\description{
This function executes a shell command and handles errors gracefully.
}
\keyword{internal}
