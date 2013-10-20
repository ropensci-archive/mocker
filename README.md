cachecall
=========

## Examples

### Get some dois via rplos

```coffee
dois <- searchplos(terms="*:*", fields='id', toquery='doc_type:full', limit=25)
dois <- do.call(c, dois[,1])
```

### Redis is fastest

First run with `cache=TRUE` checks for cached data, but there shouldn't be anything there, so takes same time as with `cache=FALSE`. Second run with `cache=TRUE` is a lot faster. 

```coffee
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="redis") )

   user  system elapsed 
  0.119   0.010   1.098 

system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="redis") )

   user  system elapsed 
  0.009   0.001   0.011 
```

### Local, the default, is a little bit slower than redis

```coffee
system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE) )
   user  system elapsed 
  0.067   0.007   1.051 

system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE) )
   user  system elapsed 
  0.011   0.000   0.011 
```

### SQLite is quite a bit slower than redis and local

```coffee
dbCreate("foodb", type = "SQLite") # create a database
db <- dbInit("foodb", type = "SQLite") # initialize the db

system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="sqlite") )
Loading required package: rjson
   user  system elapsed 
  0.252   0.018   1.215 

system.time( foo(doi = dois, apikey="WQcDSXml2VSWx3P", cache=TRUE, backend="sqlite") )
   user  system elapsed 
  0.253   0.001   0.254 
```


## Explanation

Here's the function inside this package that is like one we would use to make a web API call, with explanation.  The two additional arguments needed beyond whatever is already in a fxn are `cache` and `backend`. 

```coffee
foo <- function(doi, apikey, cache=FALSE, backend='local')
{
  # get api query ready
  url <- 'http://alm.plos.org/api/v3/articles'
  args <- compact(list(api_key = apikey, ids = paste(doi, collapse=",")))
  
  # create a key, using build_url from httr
  cachekey <- makeKey(url, args)
  
  # if cache=TRUE, check for data in backend using key, if cache=FALSE, returns NULL
  out <- suppressWarnings(goCache(cache, cachekey, backend))
  
  # if out=NULL, proceed to make call to web
  if(!is.null(out)){ out } else
  {  
    tt <- GET(url, query=args)
    stop_for_status(tt)
    temp <- content(tt)
    # If cache=TRUE, cache key and value in chosen backend, if cache=FALSE, passes with NULL
    goSave(cache, cachekey, temp, backend)
    temp
  }
}
``` 