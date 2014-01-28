\name{cache_save}
\alias{cache_save}
\title{Save results to chosen backend}
\usage{
cache_save(cache, key, obj, backend, path, db)
}
\arguments{
  \item{cache}{Logical}

  \item{key}{Key from url + args}

  \item{obj}{Object to save}

  \item{backend}{One of local, redis, couchdb.}

  \item{path}{Path}

  \item{db}{Database name for CouchDB or SQLlite}
}
\description{
Save results to chosen backend
}

