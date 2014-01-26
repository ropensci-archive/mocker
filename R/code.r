# library(cachecall); library(rredis); library(alm); library(plyr); library(rplos); library(httr); library(filehashSQLite); library(digest); library(sofa)

#' Example function with caching.
#' @import rredis plyr httr sofa RMongo 
#' @param doi Logical
#' @param key API key
#' @param cache Logical, defaults to FALSE
#' @param backend One of local, redis, couchdb, mongodb, sqlite.
#' @export
#' @examples 
#' # Get some DOIs via rplos
#' library(rplos)
#' dois <- searchplos(terms="*:*", fields='id', toquery='doc_type:full', limit=25)
#' dois <- dois[,1]
#' 
#' # Using local storage
#' foo(doi = dois, apikey="WQcDSXml2VSWx3P")
#' 
#' # Using local storage via digest::digest, the default, 1st run with cache=TRUE same as cache=FALSE, then 2nd time faster
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=FALSE) )
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, path="~/scottscache/") )
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, path="~/scottscache/") )
#' 
#' # Using local storage via R.cache
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="rcache") )
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="rcache") )
#' 
#' # Using redis, redis should be a little bit faster
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="redis") )
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="redis") )
#' 
#' # Using sqlite, quite a bit slower than local and redis
#' dbCreate("foodb", type = "SQLite")
#' db <- dbInit("foodb", type = "SQLite")
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="sqlite") )
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="sqlite") )
#' 
#' # Using couchdb, slower than local and redis, about same speed as sqlite
#' sofa_createdb("cachecall")
#' db <- "cachecall"
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", db="cachecall") )
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="couchdb") )
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="couchdb") )

foo <- function(doi, apikey, cache=FALSE, backend='local', path)
{
  # get api query ready
  url <- 'http://alm.plos.org/api/v3/articles'
  args <- compact(list(api_key = apikey, ids = paste(doi, collapse=",")))
  
  # create a key
  cachekey <- makeKey(url, args)
  
  # if cache=TRUE, check for data in backend using key, if cache=FALSE, returns NULL
  out <- suppressWarnings(goCache(cache, cachekey, backend, path))
  
  # if out=NULL, proceed to make call to web
  if(!is.null(out)){ out } else
  {  
    tt <- GET(url, query=args)
    stop_for_status(tt)
    temp <- content(tt)
    # If cache=TRUE, cache key and value in chosen backend
    goSave(cache, cachekey, temp, backend, path)
    temp
  }
}


#' Search for data in a chosen backend
#' @param cache Logical
#' @param key Key from url + args 
#' @param backend One of local, redis, couchdb, mongodb, sqlite.
#' @export
goCache <- function(cache, key, backend, path)
{
  backend <- match.arg(backend, choices=c('local', 'rcache', 'redis', 'couchdb', 'mongodb', 'sqlite'))
  switch(backend,
         local = goLocal2(cache, key, path),
         rcache = goRcache(cache, key),
         redis = goRedis(cache, key),
         sqlite = goSqlite(cache, key),
         couchdb = goCouch(cache, key),
         mongodb = "y")
}

#' Save results to chosen backend
#' @param cache Logical
#' @param key Key from url + args 
#' @param obj Object to save
#' @param backend One of local, redis, memcached, couchdb, mongodb.
#' @export
goSave <- function(cache, key, obj, backend, path, ...)
{
  if(cache){
    backend <- match.arg(backend, choices=c('local', 'rcache', 'redis', 'couchdb', 'mongodb', 'sqlite'))
    switch(backend,
           local = local2(obj, key, path),
           rcache = Rcache(obj, key),
           redis = redis_save(key, obj),
           sqlite = sqlite(obj, key),
           couchdb = couch(obj, key, db=db),
           mongodb = "y")
  } else { NULL }
}

redis_save <- function(x, y){
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
#' @param x Object
#' @param y Document ID
#' @param db Database name
#' @export
couch <- function(x, y, db)
{
#   sofa_createdb("cachecall")
  sofa_writedoc(dbname=db, doc=sprintf('{"data": %s}', toJSON(x)), docid=y)
}

#' Save results to chosen backend
#' @param x asd
#' @param y asdf
#' @export
mongo <- function(x, y)
{
  NULL
}

#' Save results to chosen backend
#' @param x asd
#' @param y asdf
#' @export
sqlite <- function(x, y) dbInsert(db, key=y, value=x)

#' Save results to chosen backend
#' @param x Output from API call
#' @param y Cache key
#' @export
local <- function(x, y)
{
  path <- tempfile(pattern="", fileext=".rda")
  assign(y, path, envir = cachecall:::cachecallCache)
  nn <- strsplit(strsplit(path, '/')[[1]][length(strsplit(path, '/')[[1]])], '\\.')[[1]][[1]]
  assign(nn, x)
#   save(list=nn, file=path)
  saveRDS(object=eval(parse(text=nn)), file=path)
}
          
#' goredis
#' @param cache Logical
#' @param key Key from url + args 
#' @export
#' @keywords internal
goRedis <- function(cache, key)
{
  if(cache){
    tt <- suppressWarnings(tryCatch(redisConnect(), error=function(e) e))
    if(is(tt, "simpleError")){
      stop("You need to start redis. Go to your terminal/shell and type redis-server, then hit enter")
    } else
    {
      nn <- redisGet(key)
      redisClose()
      if(!is.null(nn)){ nn } else
      { NULL }
    }
  } else
  { NULL }
}

#' Get value from local storage based on key
#' @param cache Logical
#' @param key Key from url + args
#' @export
#' @keywords internal
goLocal <- function(cache, key)
{
  if(cache){
    # Look for key in cachecall environment
#     tmp <- mget(ls(cachecall:::cachecallCache), envir=cachecall:::cachecallCache)
    tmp <- ls(cachecall:::cachecallCache)
    if(length(tmp) == 0){ NULL } else
    { 
      tt <- tmp[tmp %in% key]
      if(identical(tt, character(0))){
        NULL
      } else
      {
        filepath <- get(tt, envir=cachecall:::cachecallCache)
        nn <- strsplit(strsplit(filepath, '/')[[1]][length(strsplit(filepath, '/')[[1]])], '\\.')[[1]][[1]]
#         load(filepath, envir=.GlobalEnv)
#         eval(parse(text=nn))
        temp <- readRDS(filepath)
        temp
      }
    }
  } else
    { NULL }
}

#' Get value from SQlite storage based on key
#' @param cache Logical
#' @param key Key from url + args
#' @export
#' @keywords internal
goSqlite <- function(cache, key)
{
  if(cache){
    dbExists(db, key)
    tmp <- tryCatch(dbFetch(db, key), error = function(e) e)
    if(grepl('subscript out of bounds', as.character(tmp))){ NULL } else
      { tmp }
  } else
  { NULL }
}

#' Get value from SQlite storage based on key
#' @param cache Logical
#' @param key Key from url + args
#' @export
#' @keywords internal
goCouch <- function(cache, key)
{
  if(cache){
    tmp <- sofa_getdoc(dbname=db, docid=key)
    if(any(names(tmp) %in% 'error')){ NULL } else
      { tmp }
  } else
  { NULL }
}

#' Make a key from a API call (base url for call, plus arguments).
#' @param url base url for an API
#' @param args A list with named arguments
#' @export
#' @keywords internal
makeKey <- function(url, args)
{
  tmp <- parse_url(url)
  tmp$query <- args
  build_url(tmp)
}

# cachecall environment
cachecallCache <- new.env(hash=TRUE)


#' Save results locally
#' @import digest
#' @param x Output from API call
#' @param y Cache key
#' @export
local2 <- function(x, y, path="~/")
{
  hash <- digest::digest(y)
  filepath <- paste(path, hash, ".rds", sep="")
  saveRDS(object=x, file=filepath)
}

#' Get value from local storage based on key
#' @import digest
#' @param cache Logical
#' @param key Key from url + args
#' @examples \dontrun{
#' key = "http://api.plos.org/search?q=author:Ethan%20White&rows=1&wt=json"
#' path = "~/scottscache"
#' goLocal2(TRUE, key, path)
#' }
#' @export
goLocal2 <- function(cache, key, path="~/")
{
  if(cache){
    hash <- digest::digest(key)
    stored_hashes <- list.files(path, full.names=TRUE, pattern=".rds")
    getname <- function(x) strsplit(x, "/")[[1]][length(strsplit(x, "/")[[1]])]
    stored_hashes_match <- gsub("\\.rds", "", sapply(stored_hashes, getname, USE.NAMES=FALSE))
    if(length(stored_hashes) == 0){
      NULL 
    } else
    {  
      tt <- stored_hashes[stored_hashes_match %in% hash]
      if(identical(tt, character(0))){ NULL } else {
        tmp <- readRDS(tt)
        return( tmp )
      }
    }
  } else { NULL }
}

#' Save locally using R.cache
#' @import R.cache
#' @param x Output from API call
#' @param y Cache key
#' @export
Rcache <- function(x, y){
  key
  saveCache(object=x, key=y)
}

#' Get local results using R.cache
#' @import R.cache
#' @param cache Logical
#' @param key Key from url + args
#' @export
goRcache <- function(cache, key){
  if(cache){
    tmp <- loadCache(key)
    if(!is.null(tmp)){ NULL } else {
      return( tmp )
    }
  } else { NULL }
}