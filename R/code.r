#' Example function to demonstrate how webcache works.
#' 
#' @import plyr httr
#' @param doi Logical
#' @param key API key
#' @param cache Logical, defaults to FALSE
#' @param backend One of local, redis, couchdb, mongodb, sqlite.
#' @export
#' @examples \dontrun_{
#' # Define query
#' q="theory"
#' 
#' # local storage via digest::digest, the default, 1st run with cache=TRUE same as cache=FALSE, then 2nd time faster
#' system.time( cachefxn(cache=FALSE) )
#' system.time( cachefxn(q=q, cache=TRUE, path="~/scottscache/") )
#' system.time( cachefxn(q=q, cache=TRUE, path="~/scottscache/") )
#' 
#' # Using local storage via R.cache
#' system.time( cachefxn(q=q, cache=TRUE, backend="rcache") )
#' system.time( cachefxn(q=q, cache=TRUE, backend="rcache") )
#' 
#' # Using redis, redis should be a little bit faster
#' # NOTE: startup redis in your shell first
#' system.time( cachefxn(q=q, cache=TRUE, backend="redis") )
#' system.time( cachefxn(q=q, cache=TRUE, backend="redis") )
#' 
#' # Using sqlite, quite a bit slower than local and redis
#' library(filehashSQLite)
#' dbCreate("foodb", type = "SQLite") # or skip if database already created
#' sqldb <- dbInit("foodb", type = "SQLite")
#' system.time( cachefxn(q=q, cache=TRUE, backend="sqlite", db=sqldb) )
#' system.time( cachefxn(q=q, cache=TRUE, backend="sqlite", db=sqldb) )
#' 
#' # Using couchdb, slower than local and redis, about same speed as sqlite
#' # NOTE: startup couchdb in your shell first
#' sofa_createdb("cachecall")
#' cdb <- "cachecall"
#' system.time( cachefxn(q=q, cache=TRUE, backend="couchdb", db=cdb) )
#' system.time( cachefxn(q=q, cache=TRUE, backend="couchdb", db=cdb) )
#' 
#' # All methods
#' library(microbenchmark)
#' microbenchmark(
#'  local=cachefxn(q=q, cache=TRUE, path="~/scottscache/"),
#'  rcache=cachefxn(q=q, cache=TRUE, backend="rcache"),
#'  redis=cachefxn(q=q, cache=TRUE, backend="redis"),
#'  sqlite=cachefxn(q=q, cache=TRUE, backend="sqlite", db=sqldb),
#'  couchdb=cachefxn(q=q, cache=TRUE, backend="couchdb", db=cdb),
#'  times=50
#' )
#' }

cachefxn <- function(q="*:*", db=NULL, cache=FALSE, backend='local', path)
{
  # get api query ready
  url = "http://api.plos.org/search"
  args <- list(q=q, fl='id,author,abstract', fq='doc_type:full', wt='json', limit=100)
  
  # create a key
  cachekey <- make_key(url, args)
  
  # if cache=TRUE, check for data in backend using key, if cache=FALSE, returns NULL
  out <- suppressWarnings(cache_get(cache, cachekey, backend, path, db=db))
  
  # if out=NULL, proceed to make call to web
  if(!is.null(out)){ out } else
  {  
    tt <- GET(url, query=args)
    stop_for_status(tt)
    temp <- content(tt, as="text")
    # If cache=TRUE, cache key and value in chosen backend
    cache_save(cache, cachekey, temp, backend, path, db=db)
    return( temp )
  }
}