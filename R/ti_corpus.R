#' Build a TI text corpus from tagged arXiv records
#'
#' @description
#' Produces a corpus-like table with document id, metadata, and a cleaned text field.
#' Intended for saving to file/DB and for downstream analysis/visualization.
#'
#' @param x Tibble with arxiv_id, title, summary, published, primary_category, topics, hit_count.
#' @param keep_min_hits Integer. Keep only documents with at least this many topic hits.
#'
#' @return Tibble with columns: doc_id, published, primary_category, topics, text
#' @export
ti_build_corpus <- function(x, keep_min_hits = 1L) {
  stopifnot(is.data.frame(x))
  stopifnot(keep_min_hits >= 0)

  required <- c("arxiv_id", "title", "summary")
  miss <- setdiff(required, names(x))
  if (length(miss) > 0) stop(sprintf("Missing columns: %s", paste(miss, collapse = ", ")), call. = FALSE)

  df <- tibble::as_tibble(x)

  if (!("hit_count" %in% names(df))) {
    df$hit_count <- NA_integer_
  }
  if (!("topics" %in% names(df))) {
    df$topics <- vector("list", nrow(df))
  }
  if (!("published" %in% names(df))) df$published <- as.POSIXct(NA)
  if (!("primary_category" %in% names(df))) df$primary_category <- NA_character_

  # Basic text cleaning for corpus
  clean_text <- function(title, summary) {
    t <- paste(dplyr::coalesce(title, ""), dplyr::coalesce(summary, ""))
    t <- stringr::str_squish(t)
    t
  }

  corpus <- df |>
    dplyr::mutate(
      doc_id = .data$arxiv_id,
      text = mapply(clean_text, .data$title, .data$summary, USE.NAMES = FALSE)
    ) |>
    dplyr::select(.data$doc_id, .data$published, .data$primary_category, .data$topics, .data$hit_count, .data$text)

  if (keep_min_hits > 0L) {
    corpus <- corpus |>
      dplyr::filter(!is.na(.data$hit_count) & .data$hit_count >= keep_min_hits)
  }

  corpus
}

#' Save corpus to CSV (portable)
#'
#' @param corpus Tibble returned by ti_build_corpus()
#' @param path Optional file path. Default: user data dir.
#'
#' @return Path to written CSV.
#' @export
ti_save_corpus_csv <- function(corpus, path = NULL) {
  stopifnot(is.data.frame(corpus))

  if (is.null(path)) {
    path <- file.path(arxiv_data_dir(), "ti_corpus.csv")
  }
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)

  c2 <- tibble::as_tibble(corpus)
  if ("topics" %in% names(c2)) {
    c2$topics <- vapply(c2$topics, function(v) paste(v, collapse = "; "), character(1))
  }

  readr::write_csv(c2, path)
  normalizePath(path, winslash = "/", mustWork = FALSE)
}
