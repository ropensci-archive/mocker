\name{get_local}
\alias{get_local}
\title{Get value from local storage based on key}
\usage{
get_local(cache, key, path = "~/")
}
\arguments{
  \item{cache}{Logical}

  \item{key}{Key from url + args}
}
\description{
Get value from local storage based on key
}
\examples{
\dontrun{
key = "http://api.plos.org/search?q=author:Ethan\%20White&rows=1&wt=json"
path = "~/scottscache"
golocal2(TRUE, key, path)
}
}
\keyword{internal}

