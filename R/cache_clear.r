#' Clear cache.
#' 
#' @export
#' @examples \dontrun{
#' cache_clear()
#' }

cache_clear <- function(cachetype=NULL){
	if(is.null(cachetype))
		cachetype <- getOption('cachetype')
	if(is.null(cachetype))
		stop("Sorry, can't find your cache type. Either enter 
			a type or keep a type in your .Rprofile file")

	switch(cachetype, 
		local = X, # i.e., digest
		r.cache = X,
		redis = X,
		sqlite = X,
		couchdb = X)
}