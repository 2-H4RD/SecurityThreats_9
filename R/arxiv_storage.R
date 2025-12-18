#' Get default local data directory for the package
#'
#' @description
#' Returns a writable per-user directory for storing cached arXiv data and metadata.
#' Uses tools::R_user_dir() (R >= 4.0). Falls back to tempdir().
#'
#' @return Character scalar path.
#' @keywords internal
arxiv_data_dir <- function() {
  base <- NULL

  # Prefer per-user writable directory (R >= 4.0), but guard against odd returns
  base <- tryCatch(
    tools::R_user_dir("arxivThreatIntel", which = "data"),
    error = function(e) NULL
  )

  # Normalize: must be a single, non-empty character scalar
  if (is.null(base) || !is.character(base) || length(base) != 1L || is.na(base) || !nzchar(base)) {
    base <- file.path(path.expand("~"), ".arxivThreatIntel-data")
  }

  if (!dir.exists(base)) dir.create(base, recursive = TRUE, showWarnings = FALSE)
  base
}


#' Save arXiv records to CSV
#'
#' @param x A tibble/data.frame returned by arxiv_search()/arxiv_parse().
#' @param path File path for CSV. If NULL, uses default package data dir.
#'
#' @return The normalized path to the written CSV.
#' @export
arxiv_save_csv <- function(x, path = NULL) {
  stopifnot(is.data.frame(x))

  if (is.null(path)) {
    path <- file.path(arxiv_data_dir(), "arxiv_records.csv")
  }
  if (!is.character(path) || length(path) != 1L || is.na(path)) {
    stop("csv path must be a single character string.", call. = FALSE)
  }

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)

  x2 <- x
  if ("authors" %in% names(x2)) {
    x2$authors <- vapply(x2$authors, function(v) paste(v, collapse = "; "), character(1))
  }
  if ("categories" %in% names(x2)) {
    x2$categories <- vapply(x2$categories, function(v) paste(v, collapse = "; "), character(1))
  }

  readr::write_csv(x2, path)
  normalizePath(path, winslash = "/", mustWork = FALSE)
}

#' Load arXiv records from CSV
#'
#' @param path File path for CSV. If NULL, uses default package data dir.
#'
#' @return Tibble (possibly empty).
#' @export
arxiv_load_csv <- function(path = NULL) {
  if (is.null(path)) {
    path <- file.path(arxiv_data_dir(), "arxiv_records.csv")
  }
  if (!is.character(path) || length(path) != 1L || is.na(path)) {
    stop("csv path must be a single character string.", call. = FALSE)
  }

  if (!file.exists(path)) {
    return(tibble::tibble())
  }

  x <- readr::read_csv(path, show_col_types = FALSE)

  if ("authors" %in% names(x)) {
    x$authors <- lapply(x$authors, function(s) {
      if (is.na(s) || !nzchar(s)) character() else stringr::str_split(s, "\\s*;\\s*")[[1]]
    })
  }
  if ("categories" %in% names(x)) {
    x$categories <- lapply(x$categories, function(s) {
      if (is.na(s) || !nzchar(s)) character() else stringr::str_split(s, "\\s*;\\s*")[[1]]
    })
  }

  x
}

#' Save update metadata (watermark)
#'
#' @param meta Named list. Stored as JSON.
#' @param path File path for JSON. If NULL, uses default package data dir.
#'
#' @return Path to written JSON.
#' @keywords internal
arxiv_save_meta <- function(meta, path = NULL) {
  if (is.null(path)) {
    path <- file.path(arxiv_data_dir(), "arxiv_meta.json")
  }
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)

  # simple JSON without adding heavy deps: use jsonlite if present; otherwise dput
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    jsonlite::write_json(meta, path, auto_unbox = TRUE, pretty = TRUE)
  } else {
    dput(meta, file = path)
  }

  normalizePath(path, winslash = "/", mustWork = FALSE)
}

#' Load update metadata (watermark)
#'
#' @param path File path for JSON/DPUT. If NULL, uses default package data dir.
#'
#' @return Named list (possibly empty).
#' @keywords internal
arxiv_load_meta <- function(path = NULL) {
  if (is.null(path)) {
    path <- file.path(arxiv_data_dir(), "arxiv_meta.json")
  }
  if (!file.exists(path)) return(list())

  if (requireNamespace("jsonlite", quietly = TRUE)) {
    as.list(jsonlite::read_json(path, simplifyVector = TRUE))
  } else {
    # dget for dput fallback
    dget(path)
  }
}
