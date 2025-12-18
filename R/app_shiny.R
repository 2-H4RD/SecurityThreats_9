#' Run arxivThreatIntel Shiny GUI
#'
#' Simple GUI to update arXiv cache, tag papers with TI topics, and explore results.
#'
#' @param host Shiny host (default 127.0.0.1)
#' @param port Shiny port (default 8080)
#' @param launch_browser Open browser automatically
#' @export
run_app <- function(host = "127.0.0.1", port = 8080, launch_browser = TRUE) {
  app_path <- system.file("app", "app.R", package = "arxivThreatIntel")
  if (app_path == "") stop("App not found. Is the package installed correctly?", call. = FALSE)
  
  shiny::runApp(app_path, host = host, port = port, launch.browser = launch_browser)
}
