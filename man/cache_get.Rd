\name{cache_get}
\alias{cache_get}
\title{Search for data in a chosen backend}
\usage{
cache_get(cache, key, backend, path, db)
}
\arguments{
  \item{cache}{Logical}

  \item{key}{Key from url + args}

  \item{backend}{One of local, redis, couchdb, mongodb,
  sqlite.}

  \item{path}{An optional path to store data in. Only
  applicable for X and Y.}

  \item{db}{Database name for CouchDB or SQLlite}
}
\description{
Search for data in a chosen backend
}

