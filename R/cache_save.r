#' Save results to chosen backend
#' 
#' @param cache Logical
#' @param key Key from url + args 
#' @param obj Object to save
#' @param backend One of local, redis, couchdb.
#' @param path Path for local storage. Only used when backend='local'
#' @param db Database name for CouchDB or SQLlite
#' @export
cache_save <- function(cache, key, obj, backend, path, db)
{
  if(cache){
    backend <- match.arg(backend, choices=c('local', 'rcache', 'redis', 'sqlite', 'couchdb'))
    switch(backend,
           local = save_local(obj, key, path),
           rcache = save_rcache(obj, key),
           redis = save_redis(key, obj),
           sqlite = save_sqlite(db=db, obj, key),
           couchdb = save_couch(obj, key, db=db)
    )
  } else { NULL }
}

#' Save results locally
#' @import digest
#' @param x Output from API call
#' @param y Cache key
#' @export
#' @keywords internal
save_local <- function(x, y, path="~/")
{
  hash <- digest::digest(y)
  filepath <- paste(path, hash, ".rds", sep="")
  saveRDS(object=x, file=filepath)
}

#' Save locally using R.cache
#' @import R.cache
#' @param x Output from API call
#' @param y Cache key
#' @export
#' @keywords internal
save_rcache <- function(x, y){
  saveCache(object=x, key=list(y))
}

#' Save results to Redis backend
#' @import rredis
#' @param x key
#' @param y object
#' @export
#' @keywords internal
save_redis <- function(x, y){
  tt <- suppressWarnings(tryCatch(redisConnect(), error=function(e) e))
  if(is(tt, "simpleError")){
    stop("Start redis. Go to your terminal/shell and type redis-server, then hit enter")
  } else
  {
    redisSet(x, y)
    redisClose()
  }
}

#' Save results to chosen backend
#' @import filehashSQLite
#' @param db a database name
#' @param x Object to save
#' @param y Key to save on
#' @export
#' @keywords internal
save_sqlite <- function(db, x, y) dbInsert(db, key=y, value=x)

#' Save results to CoucDB backend
#' @import sofa rjson
#' @param x Object
#' @param y Document ID
#' @param db Database name
#' @export
#' @keywords internal
save_couch <- function(x, y, db)
{
  sofa_writedoc(dbname=db, doc=sprintf('{"data": %s}', toJSON(x)), docid=digest::digest(y))
}