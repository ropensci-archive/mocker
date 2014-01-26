\name{foo}
\alias{foo}
\title{Example function with caching.}
\usage{
  foo(doi, apikey, cache = FALSE, backend = "local", path)
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
library(rplos)
dois <- searchplos(terms="*:*", fields='id', toquery='doc_type:full', limit=25)
dois <- dois[,1]

# Using local storage
foo(doi = dois, apikey="WQcDSXml2VSWx3P")

# Using local storage, the default, 1st run with cache=TRUE same as cache=FALSE, then 2nd time faster
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=FALSE) )
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, path="~/scottscache/") )
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, path="~/scottscache/") )

# Using redis, redis should be a little bit faster
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P") )
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="redis") )
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="redis") )

# Using sqlite, quite a bit slower than local and redis
dbCreate("foodb", type = "SQLite")
db <- dbInit("foodb", type = "SQLite")
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P") )
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="sqlite") )
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="sqlite") )

# Using couchdb, slower than local and redis, about same speed as sqlite
sofa_createdb("cachecall")
db <- "cachecall"
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", db="cachecall") )
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="couchdb") )
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="couchdb") )
}

