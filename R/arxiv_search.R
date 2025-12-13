#' Search arXiv and return a parsed tibble
#'
#' @description
#' Convenience wrapper: fetches Atom XML from arXiv API and parses it into a tibble.
#'
#' @inheritParams arxiv_fetch
#'
#' @return Tibble. See \code{arxiv_parse()}.
#' @export
arxiv_search <- function(search_query,
                         start = 0L,
                         max_results = 100L,
                         sort_by = c("submittedDate", "lastUpdatedDate", "relevance"),
                         sort_order = c("descending", "ascending"),
                         user_agent = "arxivThreatIntel (R; contact: <your_email>)",
                         timeout_sec = 30L) {
  xml_text <- arxiv_fetch(
    search_query = search_query,
    start = start,
    max_results = max_results,
    sort_by = sort_by,
    sort_order = sort_order,
    user_agent = user_agent,
    timeout_sec = timeout_sec
  )

  arxiv_parse(xml_text)
}
