#' Load topic dictionary (patterns) from package extdata
#'
#' @param path Optional path to CSV with columns: topic, pattern.
#'
#' @return Tibble(topic, pattern)
#' @export
ti_load_topics <- function(path = NULL) {
  if (is.null(path)) {
    path <- system.file("extdata", "ti_topics.csv", package = "arxivThreatIntel")
  }
  if (!nzchar(path) || !file.exists(path)) {
    stop("Topic dictionary not found. Expected inst/extdata/ti_topics.csv.", call. = FALSE)
  }
  topics <- readr::read_csv(path, show_col_types = FALSE)
  if (!all(c("topic", "pattern") %in% names(topics))) {
    stop("Topic dictionary must have columns: topic, pattern.", call. = FALSE)
  }
  dplyr::mutate(topics,
                topic = as.character(.data$topic),
                pattern = as.character(.data$pattern))
}

#' Tag arXiv records with TI topics using a rule-based dictionary
#'
#' @description
#' Assigns one or more topics to each record based on regex matches in title+summary.
#' Produces a list-column 'topics' plus a convenience string 'topic_labels'.
#'
#' @param x Tibble/data.frame with at least columns title, summary (recommended), and arxiv_id.
#' @param topics_tbl Output of ti_load_topics(). If NULL, loaded from extdata.
#' @param min_hits Integer, minimum number of matched topics required to keep a record in corpus filters.
#'   (This function does not filter; it only annotates.)
#'
#' @return Tibble with added columns: topics (list), topic_labels (chr), hit_count (int)
#' @export
ti_tag <- function(x, topics_tbl = NULL, min_hits = 0L) {
  stopifnot(is.data.frame(x))
  stopifnot(min_hits >= 0)

  if (is.null(topics_tbl)) topics_tbl <- ti_load_topics()

  if (!("title" %in% names(x))) stop("Input must contain 'title' column.", call. = FALSE)
  if (!("summary" %in% names(x))) x$summary <- NA_character_

  text <- paste0(
    dplyr::coalesce(as.character(x$title), ""),
    " ",
    dplyr::coalesce(as.character(x$summary), "")
  )
  text <- stringr::str_to_lower(text)

  # For each row, find matching topics
  topic_names <- topics_tbl$topic
  patterns <- topics_tbl$pattern

  matched <- lapply(text, function(t) {
    hits <- mapply(function(tp, pat) {
      stringr::str_detect(t, stringr::regex(pat, ignore_case = TRUE))
    }, topic_names, patterns, USE.NAMES = FALSE)
    topic_names[as.logical(hits)]
  })

  hit_count <- vapply(matched, length, integer(1))
  out <- tibble::as_tibble(x)
  out$topics <- matched
  out$topic_labels <- vapply(matched, function(v) paste(v, collapse = "; "), character(1))
  out$hit_count <- hit_count

  if (min_hits > 0L) {
    # Only annotate; do not drop rows here by default. Keep behaviour explicit.
    # Users may filter: dplyr::filter(hit_count >= min_hits)
  }

  out
}
