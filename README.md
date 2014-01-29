webcache
=========

## Install webcache

```coffee
install.packages("devtools")
library(devtools)
install_github("ropensci/webcache")
library(webcache)
```

## Install redis

### using brew (OSX)

or [their site](http://redis.io/download) for other options.

```bash
brew install redis
```

### Remember to start Redis on your cli

```bash
redis-server 
```

A redis admin panel in browser is available from the Node.js library [redis-commander](https://github.com/joeferner/redis-commander)

```bash
sudo npm install -g redis-commander
redis-commander
```

## Install CouchDB

### using brew (OSX)

```bash
brew install couchdb
```

### Remember to start CouchDB on your cli

```bash
couchdb 
```

A CouchDB admin panel in your browser, Futon, comes with CouchDB. You can access it in your browser at `localhost:5984/_utils`. A new dashboard replacement called Fauxton, from Cloudant, can be installed from [NPM](https://npmjs.org/package/fauxton), and is found at `localhost:5984/_utils/fauxton/`.

```bash
npm install fauxton
```

## Examples

### Define query

```coffee
q <- "theory"
```

### Local storage via `saveRDS`

This is the default, 1st run with `cache=TRUE` same as `cache=FALSE`, then 2nd time faster. Same for any backend option.

```coffee
system.time( cachefxn(q=q, cache=TRUE, path="~/scottscache/") )
```
```coffee
   user  system elapsed 
  0.096   0.004   0.453 
```

```coffee
system.time( cachefxn(q=q, cache=TRUE, path="~/scottscache/") )
```

```coffee
  user  system elapsed 
  0.004   0.000   0.005
```

### Local storage via R.cache

```coffee
system.time( cachefxn(q=q, cache=TRUE, backend="rcache") )
```

```coffee
   user  system elapsed 
  0.033   0.002   0.279 
```

```coffee
system.time( cachefxn(q=q, cache=TRUE, backend="rcache") )
```

```coffee
   user  system elapsed 
  0.006   0.000   0.006 
```

### Redis

NOTE: startup redis in your shell first

```coffee
system.time( cachefxn(q=q, cache=TRUE, backend="redis") )
```

```coffee
   user  system elapsed 
  0.036   0.004   0.384 
```

```coffee
system.time( cachefxn(q=q, cache=TRUE, backend="redis") )
```

```coffee
   user  system elapsed 
  0.007   0.001   0.007 
```

### SQLite

```coffee
library(filehashSQLite)
dbCreate("foodb", type = "SQLite") # or skip if database already created
sqldb <- dbInit("foodb", type = "SQLite")
system.time( cachefxn(q=q, cache=TRUE, backend="sqlite", db=sqldb) )
```

```coffee
   user  system elapsed 
  0.038   0.002   0.293 
```

```coffee
system.time( cachefxn(q=q, cache=TRUE, backend="sqlite", db=sqldb) )
```

```coffee
   user  system elapsed 
  0.014   0.000   0.014
```

### CouchDB

NOTE: startup couchdb in your shell first

```coffee
sofa_createdb("cachecall")
cdb <- "cachecall"
system.time( cachefxn(q=q, cache=TRUE, backend="couchdb", db=cdb) )
```

```coffee
   user  system elapsed 
  0.032   0.001   0.315 
```

```coffee
system.time( cachefxn(q=q, cache=TRUE, backend="couchdb", db=cdb) )
```

```coffee
  user  system elapsed 
  0.025   0.001   0.028 
```

### All methods

With `microbenchmark`

```coffee
library(microbenchmark)
microbenchmark(
 local=cachefxn(q=q, cache=TRUE, path="~/scottscache/"),
 R.cache=cachefxn(q=q, cache=TRUE, backend="rcache"),
 redis=cachefxn(q=q, cache=TRUE, backend="redis"),
 sqlite=cachefxn(q=q, cache=TRUE, backend="sqlite", db=sqldb),
 couchdb=cachefxn(q=q, cache=TRUE, backend="couchdb", db=cdb),
 times=50
)
```

```coffee
Unit: milliseconds
    expr       min        lq    median        uq       max neval
   local  4.007978  4.278275  4.362870  4.816612  6.675667    50
  R.cache  4.461892  4.824427  5.038775  5.801503  8.543470    50
   redis  5.624845  6.146504  6.401435  7.075442  9.408585    50
  sqlite 10.074079 10.652784 11.210765 12.425844 18.450480    50
 couchdb 25.964903 27.661443 29.219574 32.668773 36.355845    50
```

Indeed, local caching is fastest, either via the simplest of writing files via `saveRDS` ("local"), or via R.cache. However, Redis isn't far behind, and could offer more flexibility over simple file storage if you are interested. SQLite and CouchDB probably aren't worth it unless you really need them. 

## Explanation of the cachefxn function

i.e., how you could incorporate this into a package or a script

Here's the function inside this package that is like one we would use to make a web API call, with explanation.  The two additional arguments needed beyond whatever is already in a fxn are `cache` and `backend`. 

```coffee
cachefxn <- function(q="*:*", db=NULL, cache=FALSE, backend='local', path)
{
  # get api query ready
  url = "http://api.plos.org/search"
  args <- list(q=q, fl='id,author,abstract', fq='doc_type:full', wt='json', limit=50)
  
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
```