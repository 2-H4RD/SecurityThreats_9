#' Update locally stored arXiv dataset for a given query
#'
#' @description
#' Loads existing records from CSV, fetches latest records from arXiv API,
#' merges them, removes duplicates, and saves back to CSV. Also stores update metadata.
#'
#' Update strategy:
#' - Always fetch first N records (max_results) sorted by submittedDate desc.
#' - Merge with existing cache and deduplicate by arXiv id.
#' This is robust and simple. It does not rely on arXiv "since" filtering.
#'
#' @param search_query Character scalar. arXiv API search query.
#' @param csv_path Optional CSV file path for cached records.
#' @param meta_path Optional JSON file path for metadata.
#' @param max_results Integer. How many of the newest records to fetch each update.
#' @param sort_by,sort_order Passed to arxiv_fetch().
#' @param user_agent,timeout_sec Passed to arxiv_fetch().
#'
#' @return A list with:
#' \itemize{
#'   \item records: tibble of merged records
#'   \item added: integer, how many new unique records were added
#'   \item csv_path: path where records were saved
#'   \item meta_path: path where metadata was saved
#' }
#' @export
arxiv_update <- function(search_query,
                         csv_path = NULL,
                         meta_path = NULL,
                         max_results = 200L,
                         sort_by = c("submittedDate", "lastUpdatedDate", "relevance"),
                         sort_order = c("descending", "ascending"),
                         user_agent = "arxivThreatIntel (R; contact: <your_email>)",
                         timeout_sec = 30L) {
  stopifnot(is.character(search_query), length(search_query) == 1L, nchar(search_query) > 0L)
  stopifnot(is.numeric(max_results), length(max_results) == 1L, max_results >= 1)

  sort_by <- match.arg(sort_by)
  sort_order <- match.arg(sort_order)

  old <- arxiv_load_csv(csv_path)
  old_n <- nrow(old)

  fresh <- arxiv_search(
    search_query = search_query,
    start = 0L,
    max_results = as.integer(max_results),
    sort_by = sort_by,
    sort_order = sort_order,
    user_agent = user_agent,
    timeout_sec = timeout_sec
  )

  # Normalize ID column name. Step 2 provides arxiv_id; keep it authoritative.
  if (!("arxiv_id" %in% names(fresh)) && ("id" %in% names(fresh))) {
    fresh$arxiv_id <- fresh$id
  }

  # Merge + deduplicate by arxiv_id (fallback to id)
  merged <- dplyr::bind_rows(old, fresh)

  id_col <- if ("arxiv_id" %in% names(merged)) "arxiv_id" else "id"
  if (!(id_col %in% names(merged))) {
    stop("Cannot deduplicate: no arxiv_id/id column present.", call. = FALSE)
  }

  merged <- merged |>
    dplyr::filter(!is.na(.data[[id_col]]) & nzchar(.data[[id_col]])) |>
    dplyr::distinct(.data[[id_col]], .keep_all = TRUE)

  # Prefer newest first if published exists
  if ("published" %in% names(merged)) {
    merged <- merged |>
      dplyr::arrange(dplyr::desc(.data$published))
  }

  new_n <- nrow(merged)
  added <- max(0L, new_n - old_n)

  csv_written <- arxiv_save_csv(merged, csv_path)

  meta <- list(
    search_query = search_query,
    updated_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    fetched_max_results = as.integer(max_results),
    previous_rows = as.integer(old_n),
    current_rows = as.integer(new_n),
    added_rows = as.integer(added),
    newest_published_utc = if ("published" %in% names(merged) && nrow(merged) > 0) {
      format(max(merged$published, na.rm = TRUE), tz = "UTC", usetz = TRUE)
    } else {
      NA_character_
    }
  )

  meta_written <- arxiv_save_meta(meta, meta_path)

  list(
    records = merged,
    added = as.integer(added),
    csv_path = csv_written,
    meta_path = meta_written
  )
}
