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
#' dois <- searchplos(terms="*:*", fields='id', toquery='doc_type:full', limit=25)
#' dois <- do.call(c, dois[,1])
#' 
#' # Using local storage
#' foo(doi = dois, apikey="WQcDSXml2VSWx3P")
#' 
#' # Using local storage, the default, 1st run with cache=TRUE same as cache=FALSE, then 2nd time faster
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=FALSE) )
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE) )
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE) )
#' 
#' # Using redis, redis should be a little bit faster
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P") )
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="redis") )
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="redis") )
#' 
#' # Using sqlite, quite a bit slower than local and redis
#' dbCreate("foodb", type = "SQLite")
#' db <- dbInit("foodb", type = "SQLite")
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P") )
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="sqlite") )
#' system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="sqlite") )

foo <- function(doi, apikey, cache=FALSE, backend='local')
{
  # get api query ready
  url <- 'http://alm.plos.org/api/v3/articles'
  args <- compact(list(api_key = apikey, ids = paste(doi, collapse=",")))
  
  # create a key
  cachekey <- makeKey(url, args)
  
  # if cache=TRUE, check for data in backend using key, if cache=FALSE, returns NULL
  out <- suppressWarnings(goCache(cache, cachekey, backend))
  
  # if out=NULL, proceed to make call to web
  if(!is.null(out)){ out } else
  {  
    tt <- GET(url, query=args)
    stop_for_status(tt)
    temp <- content(tt)
    # If cache=TRUE, cache key and value in chosen backend
    goSave(cache, cachekey, temp, backend)
    temp
  }
}


#' Search for data in a chosen backend
#' @param cache Logical
#' @param key Key from url + args 
#' @param backend One of local, redis, couchdb, mongodb, sqlite.
#' @export
goCache <- function(cache, key, backend)
{
  backend <- match.arg(backend, choices=c('local', 'redis', 'couchdb', 'mongodb', 'sqlite'))
  switch(backend,
         local = goLocal(cache, key),
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
goSave <- function(cache, key, obj, backend)
{
  if(cache){
    backend <- match.arg(backend, choices=c('local', 'redis', 'couchdb', 'mongodb', 'sqlite'))
    switch(backend,
           local = local(obj, key),
           redis = redisSet(key, obj),
           sqlite = sqlite(obj, key),
           couchdb = suppressWarnings(couch(obj, key)),
           mongodb = "y")
  } else { NULL }
}

#' Save results to chosen backend
#' @param x asd
#' @param y asdf
#' @export
couch <- function(x, y)
{
  sofa_createdb("cachecall")
  sofa_writedoc(dbname="cachecall", doc=sprintf('{"data": %s}', toJSON(x)), docid=y)
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
    tmp <- sofa_getdoc(dbname="cachecall", docid=key)
    if(any(names(tmp) %in% 'error')){ NULL } else
      { tmp }
  } else
  { NULL }
}

#' Get value from redis based on key
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
# assign(as.character(meta[,1]), dir2, envir = rsnps:::rsnpsCache)
# cache <- mget(ls(rsnps:::rsnpsCache), envir=rsnps:::rsnpsCache)