#' Assign primary topic to each record
#'
#' @description
#' Determines the most relevant topic for each paper based on:
#' 1. Number of pattern matches (keyword frequency)
#' 2. Pattern position in text (earlier = more important)
#' 3. Pattern specificity (longer patterns = more specific)
#'
#' @param x Tagged tibble from ti_tag() with list-column 'topics'.
#' @param topics_tbl Topics dictionary from ti_load_topics().
#' @param method Character. One of "frequency" (default), "first", "specificity".
#'
#' @return Tibble with added column 'primary_topic' (character).
#' @export
ti_assign_primary_topic <- function(x, 
                                    topics_tbl = NULL, 
                                    method = c("frequency", "first", "specificity")) {
  stopifnot(is.data.frame(x))
  method <- match.arg(method)
  
  if (!("topics" %in% names(x))) {
    stop("Expected list-column 'topics'. Run ti_tag() first.", call. = FALSE)
  }
  
  if (is.null(topics_tbl)) topics_tbl <- ti_load_topics()
  
  # Prepare text for analysis
  text <- paste0(
    dplyr::coalesce(as.character(x$title), ""),
    " ",
    dplyr::coalesce(as.character(x$summary), "")
  )
  text <- stringr::str_to_lower(text)
  
  # Determine primary topic for each record
  primary <- vapply(seq_len(nrow(x)), function(i) {
    topics_list <- x$topics[[i]]
    
    # No topics assigned
    if (length(topics_list) == 0 || all(is.na(topics_list))) {
      return(NA_character_)
    }
    
    # Only one topic
    if (length(topics_list) == 1) {
      return(topics_list[1])
    }
    
    # Multiple topics - apply selection method
    txt <- text[i]
    
    if (method == "first") {
      # First matched topic (by pattern order in dictionary)
      patterns <- topics_tbl$pattern[match(topics_list, topics_tbl$topic)]
      positions <- vapply(patterns, function(p) {
        m <- stringr::str_locate(txt, stringr::regex(p, ignore_case = TRUE))
        if (is.na(m[1])) Inf else m[1]
      }, numeric(1))
      return(topics_list[which.min(positions)])
      
    } else if (method == "specificity") {
      # Most specific pattern (longest)
      patterns <- topics_tbl$pattern[match(topics_list, topics_tbl$topic)]
      pattern_lengths <- nchar(patterns)
      return(topics_list[which.max(pattern_lengths)])
      
    } else {
      # Default: frequency - count pattern matches
      patterns <- topics_tbl$pattern[match(topics_list, topics_tbl$topic)]
      counts <- vapply(patterns, function(p) {
        length(stringr::str_locate_all(txt, stringr::regex(p, ignore_case = TRUE))[[1]])
      }, integer(1))
      
      if (all(counts == 0)) {
        return(topics_list[1])  # fallback to first
      }
      
      return(topics_list[which.max(counts)])
    }
  }, character(1))
  
  out <- tibble::as_tibble(x)
  out$primary_topic <- primary
  out
}


#' Get primary topic statistics
#'
#' @param x Tibble with 'primary_topic' column
#'
#' @return Tibble with columns: primary_topic, n, pct
#' @export
ti_primary_topic_stats <- function(x) {
  stopifnot(is.data.frame(x))
  
  if (!("primary_topic" %in% names(x))) {
    stop("Expected column 'primary_topic'. Run ti_assign_primary_topic() first.", call. = FALSE)
  }
  
  stats <- x %>%
    dplyr::filter(!is.na(primary_topic)) %>%
    dplyr::count(primary_topic, sort = TRUE, name = "n") %>%
    dplyr::mutate(
      pct = round(100 * n / sum(n), 1)
    )
  
  stats
}