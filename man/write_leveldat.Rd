% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/leveldat.R
\name{write_leveldat}
\alias{write_leveldat}
\title{Write data from a world's level.dat file.}
\usage{
write_leveldat(path, value, old = FALSE, version = 8L)
}
\arguments{
\item{path}{The path to a world folder. If the path does not exist, it is 
assumed to be the base name of a world folder in the local minecraftWorlds
directory.}

\item{value}{NBT data to be written to level.dat. It will be wrapped in a COMPOUND tag before writing.}

\item{old}{If TRUE, `read_leveldat` will open level.dat_old instead.}

\item{version}{The level.dat format version for the file header.}
}
\value{
A list containing nbt data read from level.dat.
}
\description{
Write data from a world's level.dat file.
}
