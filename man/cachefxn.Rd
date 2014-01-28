\name{cachefxn}
\alias{cachefxn}
\title{Example function to demonstrate how webcache works.}
\usage{
cachefxn(q = "*:*", db = NULL, cache = FALSE, backend = "local", path)
}
\arguments{
  \item{doi}{Logical}

  \item{key}{API key}

  \item{cache}{Logical, defaults to FALSE}

  \item{backend}{One of local, redis, couchdb, mongodb,
  sqlite.}
}
\description{
Example function to demonstrate how webcache works.
}
\examples{
\dontrun_{
# Define query
q="theory"

# local storage via digest::digest, the default, 1st run with cache=TRUE same as cache=FALSE, then 2nd time faster
system.time( cachefxn(cache=FALSE) )
system.time( cachefxn(q=q, cache=TRUE, path="~/scottscache/") )
system.time( cachefxn(q=q, cache=TRUE, path="~/scottscache/") )

# Using local storage via R.cache
system.time( cachefxn(q=q, cache=TRUE, backend="rcache") )
system.time( cachefxn(q=q, cache=TRUE, backend="rcache") )

# Using redis, redis should be a little bit faster
# NOTE: startup redis in your shell first
system.time( cachefxn(q=q, cache=TRUE, backend="redis") )
system.time( cachefxn(q=q, cache=TRUE, backend="redis") )

# Using sqlite, quite a bit slower than local and redis
library(filehashSQLite)
dbCreate("foodb", type = "SQLite") # or skip if database already created
sqldb <- dbInit("foodb", type = "SQLite")
system.time( cachefxn(q=q, cache=TRUE, backend="sqlite", db=sqldb) )
system.time( cachefxn(q=q, cache=TRUE, backend="sqlite", db=sqldb) )

# Using couchdb, slower than local and redis, about same speed as sqlite
# NOTE: startup couchdb in your shell first
sofa_createdb("cachecall")
cdb <- "cachecall"
system.time( cachefxn(q=q, cache=TRUE, backend="couchdb", db=cdb) )
system.time( cachefxn(q=q, cache=TRUE, backend="couchdb", db=cdb) )

# All methods
library(microbenchmark)
microbenchmark(
 local=cachefxn(q=q, cache=TRUE, path="~/scottscache/"),
 rcache=cachefxn(q=q, cache=TRUE, backend="rcache"),
 redis=cachefxn(q=q, cache=TRUE, backend="redis"),
 sqlite=cachefxn(q=q, cache=TRUE, backend="sqlite", db=sqldb),
 couchdb=cachefxn(q=q, cache=TRUE, backend="couchdb", db=cdb),
 times=50
)
}
}

