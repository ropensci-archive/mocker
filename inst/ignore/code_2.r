#' Save results locally
#' @import digest
#' @param x Output from API call
#' @param y Cache key
#' @export
local <- function(x, y, path="~/")
{
  hash <- digest::digest(key)
  filepath <- paste(path, hash, sep="")
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
#' @keywords internal
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