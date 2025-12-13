#' Compute topic frequency table
#'
#' @param x Tagged tibble/data.frame (output of ti_tag()) with list-column 'topics'.
#'
#' @return Tibble with columns: topic, n
#' @export
ti_topic_freq <- function(x) {
  stopifnot(is.data.frame(x))
  if (!("topics" %in% names(x))) {
    stop("Expected list-column 'topics'. Run ti_tag() first.", call. = FALSE)
  }

  # Avoid hard dependency on tidyr by using base unnesting
  topics_vec <- unlist(x$topics, use.names = FALSE)
  topics_vec <- topics_vec[!is.na(topics_vec) & nzchar(topics_vec)]

  if (length(topics_vec) == 0) {
    return(tibble::tibble(topic = character(), n = integer()))
  }

  tibble::tibble(topic = topics_vec) |>
    dplyr::count(.data$topic, sort = TRUE, name = "n")
}

#' Compute topic trend by week
#'
#' @param x Tagged tibble/data.frame with columns 'published' and list-column 'topics'.
#'
#' @return Tibble with columns: week, topic, n
#' @export
ti_topic_trend_weekly <- function(x) {
  stopifnot(is.data.frame(x))
  if (!("published" %in% names(x))) stop("Expected column 'published'.", call. = FALSE)
  if (!("topics" %in% names(x))) stop("Expected list-column 'topics'. Run ti_tag() first.", call. = FALSE)

  # Keep rows with timestamps
  df <- tibble::tibble(published = x$published, topics = x$topics) |>
    dplyr::filter(!is.na(.data$published))

  if (nrow(df) == 0) {
    return(tibble::tibble(week = as.Date(character()), topic = character(), n = integer()))
  }

  # Expand list-column manually to avoid tidyr dependency
  expanded <- do.call(
    rbind,
    lapply(seq_len(nrow(df)), function(i) {
      tpcs <- df$topics[[i]]
      if (length(tpcs) == 0) return(NULL)
      data.frame(
        week = lubridate::floor_date(df$published[[i]], unit = "week"),
        topic = tpcs,
        stringsAsFactors = FALSE
      )
    })
  )

  if (is.null(expanded) || nrow(expanded) == 0) {
    return(tibble::tibble(week = as.Date(character()), topic = character(), n = integer()))
  }

  tibble::as_tibble(expanded) |>
    dplyr::filter(!is.na(.data$topic) & nzchar(.data$topic)) |>
    dplyr::count(.data$week, .data$topic, name = "n") |>
    dplyr::arrange(.data$week, dplyr::desc(.data$n))
}
