\name{foo}
\alias{foo}
\title{Example function with caching.}
\usage{
  foo(doi, apikey, cache = FALSE, backend = "local")
}
\arguments{
  \item{doi}{Logical}

  \item{key}{API key}

  \item{cache}{Logical, defaults to FALSE}

  \item{backend}{One of local, redis, couchdb, mongodb,
  sqlite.}
}
\description{
  Example function with caching.
}
\examples{
# Get some DOIs via rplos
dois <- searchplos(terms="*:*", fields='id', toquery='doc_type:full', limit=25)
dois <- do.call(c, dois[,1])

# Using local storage
foo(doi = dois, apikey="WQcDSXml2VSWx3P")

# Using local storage, the default, 1st run with cache=TRUE same as cache=FALSE, then 2nd time faster
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=FALSE) )
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE) )
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE) )

# Using redis, redis should be a little bit faster
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P") )
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="sqlite") )
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="sqlite") )

# Using sqlite, quite a bit slower than local and redis
dbCreate("mydb", type = "SQLite")
db <- dbInit("mydb", type = "SQLite")
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P") )
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="sqlite") )
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="sqlite") )
}

