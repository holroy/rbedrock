% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/rbedrock.R
\name{create_chunk_key}
\alias{create_chunk_key}
\title{Create a database key from chunk information.}
\usage{
create_chunk_key(x, z, d, tag, subtag = NA)
}
\arguments{
\item{x}{Chunk x-coordinate.}

\item{z}{Chunk z-coordinate.}

\item{d}{Chunk dimension.}

\item{tag}{The type of information the key holds.}

\item{subtag}{The subchunk the key refers to. (Only used if \code{tag==47}).}
}
\value{
The database key corresponding to the inputs.
}
\description{
Create a database key from chunk information.
}
\examples{
create_chunk_key(0, 0, 0, 47, 1)
}
