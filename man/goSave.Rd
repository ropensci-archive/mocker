\name{goSave}
\alias{goSave}
\title{Save results to chosen backend}
\usage{
  goSave(cache, key, obj, backend, path, ...)
}
\arguments{
  \item{cache}{Logical}

  \item{key}{Key from url + args}

  \item{obj}{Object to save}

  \item{backend}{One of local, redis, memcached, couchdb,
  mongodb.}
}
\description{
  Save results to chosen backend
}

