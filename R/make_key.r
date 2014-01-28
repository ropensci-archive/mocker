#' Make a key from a API call (base url for call, plus arguments).
#' 
#' @param url base url for an API
#' @param args A list with named arguments
#' @export
#' @keywords internal
make_key <- function(url, args)
{
  tmp <- parse_url(url)
  tmp$query <- args
  build_url(tmp)
}