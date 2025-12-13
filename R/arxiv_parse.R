#' Parse arXiv Atom XML into a tidy tibble
#'
#' @description
#' Converts arXiv API Atom XML (as returned by \code{arxiv_fetch()}) into a tibble
#' with one row per entry.
#'
#' @param xml_text Character scalar. Atom XML as text.
#'
#' @return A tibble with columns:
#' \itemize{
#'   \item id, arxiv_id
#'   \item title, summary
#'   \item published, updated
#'   \item authors (list-column), author_names (string)
#'   \item categories (list-column), primary_category
#'   \item link_abs, link_pdf
#' }
#' @export
arxiv_parse <- function(xml_text) {
  stopifnot(is.character(xml_text), length(xml_text) == 1L, nchar(xml_text) > 0L)

  doc <- xml2::read_xml(xml_text)

  # Atom uses namespaces; we define them explicitly for robust xpath queries
  ns <- c(
    atom = "http://www.w3.org/2005/Atom",
    arxiv = "http://arxiv.org/schemas/atom"
  )

  entry_nodes <- xml2::xml_find_all(doc, ".//atom:entry", ns = ns)
  if (length(entry_nodes) == 0L) {
    return(tibble::tibble(
      id = character(),
      arxiv_id = character(),
      title = character(),
      summary = character(),
      published = as.POSIXct(character()),
      updated = as.POSIXct(character()),
      authors = list(),
      author_names = character(),
      categories = list(),
      primary_category = character(),
      link_abs = character(),
      link_pdf = character()
    ))
  }

  # Helpers
  txt1 <- function(node, xpath) {
    x <- xml2::xml_find_first(node, xpath, ns = ns)
    if (inherits(x, "xml_missing")) return(NA_character_)
    val <- xml2::xml_text(x)
    if (length(val) == 0L) NA_character_ else val
  }

  attr1 <- function(node, xpath, attr) {
    x <- xml2::xml_find_first(node, xpath, ns = ns)
    if (inherits(x, "xml_missing")) return(NA_character_)
    val <- xml2::xml_attr(x, attr)
    if (length(val) == 0L) NA_character_ else val
  }

  parse_dt <- function(x) {
    # arXiv timestamps are ISO 8601; lubridate::ymd_hms handles "Z"
    if (is.na(x) || !nzchar(x)) return(as.POSIXct(NA))
    lubridate::ymd_hms(x, tz = "UTC", quiet = TRUE)
  }

  rows <- lapply(entry_nodes, function(e) {
    id_full <- txt1(e, "./atom:id")
    arxiv_id <- if (!is.na(id_full)) {
      # Usually like "http://arxiv.org/abs/XXXX.XXXXXvY"
      sub("^.*/abs/", "", id_full)
    } else {
      NA_character_
    }

    title <- txt1(e, "./atom:title")
    summary <- txt1(e, "./atom:summary")

    # Normalize whitespace: arXiv titles/abstracts often contain newlines
    title <- if (!is.na(title)) stringr::str_squish(title) else title
    summary <- if (!is.na(summary)) stringr::str_squish(summary) else summary

    published <- parse_dt(txt1(e, "./atom:published"))
    updated <- parse_dt(txt1(e, "./atom:updated"))

    # Authors
    author_nodes <- xml2::xml_find_all(e, "./atom:author/atom:name", ns = ns)
    author_vec <- xml2::xml_text(author_nodes)
    author_vec <- stringr::str_squish(author_vec)
    author_vec <- author_vec[nzchar(author_vec)]

    # Categories
    cat_nodes <- xml2::xml_find_all(e, "./atom:category", ns = ns)
    cat_vec <- xml2::xml_attr(cat_nodes, "term")
    cat_vec <- cat_vec[!is.na(cat_vec) & nzchar(cat_vec)]

    primary_category <- txt1(e, "./arxiv:primary_category/@term")
    # Sometimes primary category is absent in parsing via attribute xpath above; fallback:
    if (is.na(primary_category) || !nzchar(primary_category)) {
      primary_category <- attr1(e, "./arxiv:primary_category", "term")
    }

    # Links
    # rel="alternate" => abstract page; title might be "abs"
    link_abs <- {
      links <- xml2::xml_find_all(e, "./atom:link", ns = ns)
      hrefs <- xml2::xml_attr(links, "href")
      rels <- xml2::xml_attr(links, "rel")
      types <- xml2::xml_attr(links, "type")
      # prefer alternate HTML
      idx <- which(rels == "alternate")
      if (length(idx) >= 1L) hrefs[idx[1L]] else NA_character_
    }

    link_pdf <- {
      links <- xml2::xml_find_all(e, "./atom:link", ns = ns)
      hrefs <- xml2::xml_attr(links, "href")
      titles <- xml2::xml_attr(links, "title")
      types <- xml2::xml_attr(links, "type")
      # PDF is commonly indicated by title="pdf" or type="application/pdf"
      idx <- which(titles == "pdf" | types == "application/pdf")
      if (length(idx) >= 1L) hrefs[idx[1L]] else NA_character_
    }

    tibble::tibble(
      id = id_full,
      arxiv_id = arxiv_id,
      title = title,
      summary = summary,
      published = published,
      updated = updated,
      authors = list(author_vec),
      author_names = paste(author_vec, collapse = "; "),
      categories = list(cat_vec),
      primary_category = primary_category,
      link_abs = link_abs,
      link_pdf = link_pdf
    )
  })

  dplyr::bind_rows(rows)
}
