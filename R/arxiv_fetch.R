#' Fetch raw Atom XML from the arXiv API
#'
#' @description
#' Performs an HTTP request to the arXiv API and returns the response body as
#' a single XML string (Atom feed).
#'
#' @param search_query Character scalar. arXiv API search query, e.g.
#'   "cat:cs.CR AND (malware OR phishing)".
#' @param start Integer. Start index for pagination (0-based).
#' @param max_results Integer. Number of records to request (arXiv may cap).
#' @param sort_by Character. One of "relevance", "lastUpdatedDate", "submittedDate".
#' @param sort_order Character. One of "ascending", "descending".
#' @param user_agent Character scalar for polite identification.
#' @param timeout_sec Integer. Request timeout in seconds.
#' @param retries Integer. Number of retry attempts on network errors.
#' @param backoff_sec Numeric. Base backoff in seconds (exponential).
#'
#' @return Character scalar. Raw XML text.
#' @export
arxiv_fetch <- function(search_query,
                        start = 0L,
                        max_results = 100L,
                        sort_by = c("submittedDate", "lastUpdatedDate", "relevance"),
                        sort_order = c("descending", "ascending"),
                        user_agent = "arxivThreatIntel (R; contact: <your_email>)",
                        timeout_sec = 60L,
                        retries = 3L,
                        backoff_sec = 2) {
  stopifnot(is.character(search_query), length(search_query) == 1L, nchar(search_query) > 0L)
  stopifnot(is.numeric(start), length(start) == 1L, start >= 0)
  stopifnot(is.numeric(max_results), length(max_results) == 1L, max_results >= 1)
  stopifnot(is.character(user_agent), length(user_agent) == 1L, nchar(user_agent) > 0L)
  stopifnot(is.numeric(timeout_sec), length(timeout_sec) == 1L, timeout_sec >= 1)
  stopifnot(is.numeric(retries), length(retries) == 1L, retries >= 0)
  stopifnot(is.numeric(backoff_sec), length(backoff_sec) == 1L, backoff_sec >= 0)

  sort_by <- match.arg(sort_by)
  sort_order <- match.arg(sort_order)

  base_url <- "https://export.arxiv.org/api/query"

  req0 <- httr2::request(base_url) |>
    httr2::req_user_agent(user_agent) |>
    httr2::req_url_query(
      search_query = search_query,
      start = as.integer(start),
      max_results = as.integer(max_results),
      sortBy = sort_by,
      sortOrder = sort_order
    )

  last_err <- NULL
  for (i in seq_len(retries + 1L)) {
    req <- req0 |>
      httr2::req_timeout(timeout_sec)

    resp <- tryCatch(
      httr2::req_perform(req),
      error = function(e) e
    )

    if (!inherits(resp, "error")) {
      # HTTP error -> fail fast with body
      if (httr2::resp_status(resp) >= 400) {
        msg <- httr2::resp_body_string(resp)
        stop(sprintf(
          "arXiv API request failed: HTTP %s.\nResponse body:\n%s",
          httr2::resp_status(resp),
          msg
        ), call. = FALSE)
      }
      return(httr2::resp_body_string(resp))
    }

    last_err <- resp

    # If not last attempt, wait with exponential backoff + small jitter
    if (i < (retries + 1L)) {
      wait <- backoff_sec * (2^(i - 1)) + stats::runif(1, 0, 0.5)
      Sys.sleep(wait)
    }
  }

  stop(
    sprintf("arXiv API request failed after %d attempts: %s",
            retries + 1L, conditionMessage(last_err)),
    call. = FALSE
  )
}

