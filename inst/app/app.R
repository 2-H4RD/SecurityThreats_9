library(shiny)
library(bslib)
library(DT)
library(dplyr)
library(ggplot2)
library(shinycssloaders)
library(arxivThreatIntel)

ui <- page_sidebar(
  title = "arXiv Threat Intel Explorer",
  theme = bs_theme(
    version = 5,
    bootswatch = "cyborg",
    base_font = font_google("Inter"),
    bg = "#0a0e27",
    fg = "#e8eaf6",
    primary = "#00d4ff",
    secondary = "#7c4dff",
    success = "#00e676",
    info = "#2979ff",
    warning = "#ffd600",
    danger = "#ff1744"
  ),
  
  tags$head(tags$style(HTML("
    /* Общие улучшения */
    body {
      background: linear-gradient(135deg, #0a0e27 0%, #1a1f3a 100%);
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    }
    
    .bslib-page-title {
      color: #00d4ff;
      text-shadow: 0 0 20px rgba(0, 212, 255, 0.6);
      font-weight: 700;
      letter-spacing: 0.5px;
    }
    
    /* Карточки с градиентами и тенями */
    .card {
      border-radius: 20px;
      background: linear-gradient(145deg, rgba(26, 31, 58, 0.95), rgba(15, 20, 40, 0.98));
      border: 1px solid rgba(0, 212, 255, 0.2);
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5), 0 0 0 1px rgba(0, 212, 255, 0.15);
      backdrop-filter: blur(10px);
      transition: all 0.3s ease;
      overflow: hidden;
    }
    
    .card:hover {
      box-shadow: 0 12px 48px rgba(0, 212, 255, 0.25), 0 0 0 1px rgba(0, 212, 255, 0.4);
      transform: translateY(-2px);
      border-color: rgba(0, 212, 255, 0.3);
    }
    
    .card-header {
      background: linear-gradient(135deg, rgba(0, 212, 255, 0.2), rgba(124, 77, 255, 0.15));
      border-bottom: 2px solid rgba(0, 212, 255, 0.4);
      border-radius: 20px 20px 0 0 !important;
      font-weight: 600;
      font-size: 1.05rem;
      padding: 1rem 1.25rem;
      color: #00d4ff;
      text-shadow: 0 0 15px rgba(0, 212, 255, 0.6);
      position: relative;
    }
    
    .card-header::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      height: 2px;
      background: linear-gradient(90deg, transparent, #00d4ff, transparent);
      animation: shimmer 3s infinite;
    }
    
    @keyframes shimmer {
      0%, 100% { opacity: 0.3; }
      50% { opacity: 0.8; }
    }
    
    .card-body {
      padding: 1.5rem;
    }
    
    /* Sidebar стилизация */
    .bslib-sidebar-layout > .sidebar {
      background: linear-gradient(180deg, rgba(15, 20, 40, 0.98), rgba(10, 14, 39, 0.99));
      border-right: 2px solid rgba(0, 212, 255, 0.25);
      box-shadow: 4px 0 24px rgba(0, 0, 0, 0.4);
    }
    
    /* Кнопки */
    .btn {
      border-radius: 12px;
      font-weight: 600;
      padding: 0.7rem 1.5rem;
      text-transform: uppercase;
      letter-spacing: 0.8px;
      font-size: 0.85rem;
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      border: none;
      position: relative;
      overflow: hidden;
    }
    
    .btn::before {
      content: '';
      position: absolute;
      top: 50%;
      left: 50%;
      width: 0;
      height: 0;
      border-radius: 50%;
      background: rgba(255, 255, 255, 0.25);
      transform: translate(-50%, -50%);
      transition: width 0.6s, height 0.6s;
    }
    
    .btn:hover::before {
      width: 350px;
      height: 350px;
    }
    
    .btn-primary {
      background: linear-gradient(135deg, #00d4ff, #0091ea);
      box-shadow: 0 4px 20px rgba(0, 212, 255, 0.5);
    }
    
    .btn-primary:hover {
      background: linear-gradient(135deg, #00e5ff, #00b0ff);
      box-shadow: 0 8px 28px rgba(0, 212, 255, 0.7);
      transform: translateY(-3px);
    }
    
    .btn-outline-secondary {
      border: 2px solid rgba(124, 77, 255, 0.6);
      color: #b388ff;
      background: rgba(124, 77, 255, 0.08);
    }
    
    .btn-outline-secondary:hover {
      background: linear-gradient(135deg, rgba(124, 77, 255, 0.25), rgba(124, 77, 255, 0.35));
      border-color: #9575ff;
      color: #d1c4e9;
      box-shadow: 0 6px 20px rgba(124, 77, 255, 0.5);
      transform: translateY(-2px);
    }
    
    .btn-success {
      background: linear-gradient(135deg, #00e676, #00c853);
      box-shadow: 0 4px 20px rgba(0, 230, 118, 0.5);
    }
    
    .btn-success:hover {
      background: linear-gradient(135deg, #00ff89, #00e676);
      box-shadow: 0 8px 28px rgba(0, 230, 118, 0.7);
      transform: translateY(-3px);
    }
    
    .btn-sm {
      padding: 0.45rem 1.1rem;
      font-size: 0.8rem;
    }
    
    /* Инпуты */
    .form-control, .form-select {
      background: rgba(26, 31, 58, 0.7);
      border: 2px solid rgba(0, 212, 255, 0.25);
      border-radius: 12px;
      color: #e8eaf6;
      transition: all 0.3s ease;
      padding: 0.6rem 1rem;
    }
    
    .form-control:focus, .form-select:focus {
      background: rgba(26, 31, 58, 0.9);
      border-color: #00d4ff;
      box-shadow: 0 0 0 0.25rem rgba(0, 212, 255, 0.25), 0 0 25px rgba(0, 212, 255, 0.4);
      color: #fff;
    }
    
    .form-control::placeholder {
      color: rgba(176, 190, 197, 0.5);
    }
    
    .form-label {
      color: #b0bec5;
      font-weight: 500;
      font-size: 0.9rem;
      margin-bottom: 0.6rem;
    }
    
    /* Чекбоксы */
    .form-check-input {
      background-color: rgba(26, 31, 58, 0.7);
      border: 2px solid rgba(0, 212, 255, 0.4);
      border-radius: 6px;
      width: 1.3em;
      height: 1.3em;
      cursor: pointer;
    }
    
    .form-check-input:checked {
      background-color: #00d4ff;
      border-color: #00d4ff;
      box-shadow: 0 0 15px rgba(0, 212, 255, 0.6);
    }
    
    .form-check-label {
      color: #b0bec5;
      margin-left: 0.6rem;
      cursor: pointer;
    }
    
    /* Code blocks */
    code {
      background: rgba(0, 212, 255, 0.12);
      color: #00e5ff;
      padding: 0.3rem 0.6rem;
      border-radius: 8px;
      font-family: 'Fira Code', 'Courier New', monospace;
      font-size: 0.82rem;
      border: 1px solid rgba(0, 212, 255, 0.25);
      display: inline-block;
      max-width: 100%;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    
    /* Статистические карточки */
    .stat-card {
      background: linear-gradient(135deg, rgba(0, 212, 255, 0.1), rgba(124, 77, 255, 0.1));
      border-radius: 14px;
      padding: 1.1rem;
      margin-bottom: 0.6rem;
      border-left: 4px solid #00d4ff;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
      transition: all 0.3s ease;
    }
    
    .stat-card:hover {
      background: linear-gradient(135deg, rgba(0, 212, 255, 0.15), rgba(124, 77, 255, 0.15));
      transform: translateX(3px);
      box-shadow: 0 6px 16px rgba(0, 212, 255, 0.2);
    }
    
    .stat-card b {
      color: #00d4ff;
      font-weight: 600;
    }
    
    .stat-card div {
      margin: 0.3rem 0;
    }
    
    /* Таблицы DataTables */
    .dataTables_wrapper {
      color: #e8eaf6;
    }
    
    table.dataTable {
      background: transparent;
      border-collapse: separate;
      border-spacing: 0 4px;
    }
    
    table.dataTable thead th {
      background: linear-gradient(135deg, rgba(0, 212, 255, 0.2), rgba(124, 77, 255, 0.2));
      color: #00d4ff;
      border-bottom: 3px solid rgba(0, 212, 255, 0.5);
      font-weight: 600;
      padding: 1rem 0.8rem;
      text-transform: uppercase;
      font-size: 0.85rem;
      letter-spacing: 0.5px;
    }
    
    table.dataTable tbody tr {
      background: rgba(26, 31, 58, 0.4);
      transition: all 0.2s ease;
      border-radius: 8px;
    }
    
    table.dataTable tbody tr:hover {
      background: linear-gradient(90deg, rgba(0, 212, 255, 0.12), rgba(124, 77, 255, 0.08));
      box-shadow: 0 2px 12px rgba(0, 212, 255, 0.25);
      transform: scale(1.01);
    }
    
    table.dataTable tbody td {
      border-bottom: 1px solid rgba(0, 212, 255, 0.08);
      padding: 0.9rem 0.8rem;
      color: #cfd8dc;
    }
    
    .dataTables_info, .dataTables_paginate {
      color: #90a4ae !important;
      margin-top: 1rem;
    }
    
    .paginate_button {
      background: rgba(0, 212, 255, 0.1) !important;
      border: 1px solid rgba(0, 212, 255, 0.3) !important;
      color: #00d4ff !important;
      border-radius: 6px !important;
      margin: 0 2px !important;
    }
    
    .paginate_button:hover {
      background: rgba(0, 212, 255, 0.2) !important;
      border-color: rgba(0, 212, 255, 0.5) !important;
    }
    
    .paginate_button.current {
      background: linear-gradient(135deg, #00d4ff, #7c4dff) !important;
      border-color: #00d4ff !important;
      color: #fff !important;
    }
    
    /* Навигационные табы */
    .nav-tabs {
      border-bottom: 2px solid rgba(0, 212, 255, 0.3);
      margin-bottom: 0;
    }
    
    .nav-tabs .nav-link {
      color: #90a4ae;
      border: none;
      border-radius: 12px 12px 0 0;
      transition: all 0.3s ease;
      font-weight: 600;
      padding: 0.85rem 1.8rem;
      font-size: 0.95rem;
    }
    
    .nav-tabs .nav-link:hover {
      color: #00d4ff;
      background: rgba(0, 212, 255, 0.1);
    }
    
    .nav-tabs .nav-link.active {
      color: #00d4ff;
      background: linear-gradient(180deg, rgba(0, 212, 255, 0.2), transparent);
      border-bottom: 3px solid #00d4ff;
      box-shadow: 0 -3px 15px rgba(0, 212, 255, 0.4);
      text-shadow: 0 0 10px rgba(0, 212, 255, 0.5);
    }
    
    /* Спиннер загрузки */
    .spinner-border {
      color: #00d4ff;
      filter: drop-shadow(0 0 10px rgba(0, 212, 255, 0.6));
    }
    
    /* How to use список */
    .small ol {
      padding-left: 1.5rem;
      margin: 0;
    }
    
    .small li {
      margin-bottom: 0.6rem;
      color: #b0bec5;
      line-height: 1.7;
    }
    
    .small b {
      color: #00d4ff;
    }
    
    /* Ошибки */
    .shiny-output-error {
      color: #ff1744;
      background: rgba(255, 23, 68, 0.1);
      border: 1px solid rgba(255, 23, 68, 0.3);
      border-radius: 12px;
      padding: 1rem;
      margin: 1rem 0;
    }
    
    .shiny-output-error::before {
      content: '⚠️ ';
      font-size: 1.2rem;
    }
    
    /* Scrollbar */
    ::-webkit-scrollbar {
      width: 12px;
      height: 12px;
    }
    
    ::-webkit-scrollbar-track {
      background: rgba(10, 14, 39, 0.6);
      border-radius: 6px;
    }
    
    ::-webkit-scrollbar-thumb {
      background: linear-gradient(180deg, #00d4ff, #7c4dff);
      border-radius: 6px;
      border: 2px solid rgba(10, 14, 39, 0.6);
    }
    
    ::-webkit-scrollbar-thumb:hover {
      background: linear-gradient(180deg, #00e5ff, #9575ff);
    }
    
    /* Дополнительные акценты */
    .text-muted {
      color: #78909c !important;
    }
    
    h5, h6 {
      color: #00d4ff;
    }
    
    /* Анимация появления */
    @keyframes fadeInUp {
      from {
        opacity: 0;
        transform: translateY(30px);
      }
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }
    
    .card {
      animation: fadeInUp 0.6s ease-out;
    }
    
    /* Layout improvements */
    .layout-column-wrap > * {
      margin-bottom: 1rem;
    }
    
    /* Better spacing */
    .d-grid {
      gap: 0.75rem;
    }
    
    .mb-3 {
      margin-bottom: 1rem !important;
    }
    
    /* Selectize improvements */
    .selectize-input {
      background: rgba(26, 31, 58, 0.7) !important;
      border: 2px solid rgba(0, 212, 255, 0.25) !important;
      border-radius: 12px !important;
      color: #e8eaf6 !important;
    }
    
    .selectize-dropdown {
      background: rgba(26, 31, 58, 0.98) !important;
      border: 2px solid rgba(0, 212, 255, 0.3) !important;
      border-radius: 12px !important;
    }
    
    .selectize-dropdown-content .option {
      color: #e8eaf6 !important;
      padding: 0.6rem !important;
    }
    
    .selectize-dropdown-content .option:hover,
    .selectize-dropdown-content .option.active {
      background: rgba(0, 212, 255, 0.15) !important;
      color: #00d4ff !important;
    }
  "))),
  
  sidebar = sidebar(
    width = 340,
    
    card(
      card_header("📊 Data Source"),
      textInput("q", "Search query (arXiv)", value = "threat intelligence"),
      numericInput("n", "Max results", value = 50, min = 10, max = 500, step = 10),
      div(
        class = "d-grid gap-2",
        actionButton("update", "🔄 Update cache", class = "btn btn-primary"),
        actionButton("refresh", "✨ Refresh view", class = "btn btn-outline-secondary")
      ),
      checkboxInput("tag", "🏷️ Apply TI topic tagging", value = TRUE)
    ),
    
    card(
      card_header("🔍 Filters"),
      uiOutput("topic_ui"),
      uiOutput("primary_topic_ui"),  # 🔥 Новый фильтр
      dateRangeInput(
        "dr", "Published date range",
        start = Sys.Date() - 30, end = Sys.Date()
      ),
      textInput("textfilter", "Text contains (title/summary)", value = ""),
      downloadButton("dl", "📥 Download CSV", class = "btn btn-success w-100 mt-2")
    ),
    
    card(
      card_header("💡 How to use"),
      tags$div(
        class = "small",
        tags$ol(
          tags$li("Click ", tags$b("Update cache"), " to fetch & store papers."),
          tags$li("Click ", tags$b("Refresh view"), " to apply tagging & filters."),
          tags$li("Use the topic/date/text filters and download the filtered CSV.")
        )
      )
    )
  ),
  
  layout_column_wrap(
    width = 1,
    
    layout_column_wrap(
      width = 1/3,
      card(
        card_header("📈 Dataset"),
        uiOutput("stat_rows")
      ),
      card(
        card_header("🆕 Update"),
        uiOutput("stat_added")
      ),
      card(
        card_header("💾 Cache"),
        uiOutput("stat_paths")
      )
    ),
    
    navset_card_tab(
      nav_panel(
        "📄 Papers",
        card_body(
          DTOutput("tbl") |> withSpinner(color = "#00d4ff", type = 4)
        )
      ),
      
      nav_panel(
        "📊 Topics",
        layout_column_wrap(
          width = 1/2,
          card(
            card_header("📊 Distribution"),
            plotOutput("topic_plot", height = 350) |> withSpinner(color = "#00d4ff", type = 4)
          ),
          card(
            card_header("🔢 Counts"),
            DTOutput("topic_tbl") |> withSpinner(color = "#00d4ff", type = 4)
          )
        )
      ),
      
      # 🔥 НОВАЯ ВКЛАДКА TRENDS
      nav_panel(
        "📈 Trends",
        card(
          card_header("📈 Topic Trends Over Time"),
          card_body(
            plotOutput("trend_plot", height = 500) |> withSpinner(color = "#00d4ff", type = 4)
          )
        ),
        card(
          card_header("📋 Weekly Topic Data"),
          card_body(
            DTOutput("trend_tbl") |> withSpinner(color = "#00d4ff", type = 4)
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  
  topics_tbl  <- reactiveVal(NULL)
  records_tbl <- reactiveVal(NULL)
  tagged_tbl  <- reactiveVal(NULL)
  
  output$stat_rows  <- renderUI({
    tags$div(
      class = "stat-card",
      tags$div(
        style = "text-align: center; padding: 1rem 0;",
        "No data yet. Click ", tags$b("Update cache"), "."
      )
    )
  })
  output$stat_added <- renderUI({
    tags$div(
      class = "stat-card",
      tags$div(style = "text-align: center; color: #78909c;", "—")
    )
  })
  output$stat_paths <- renderUI({
    tags$div(
      class = "stat-card",
      tags$div(style = "text-align: center; color: #78909c;", "—")
    )
  })
  
  observeEvent(TRUE, {
    topics_tbl(ti_load_topics())
  }, once = TRUE)
  
  observeEvent(input$update, {
    output$stat_rows  <- renderUI({
      tags$div(
        class = "stat-card",
        tags$div(style = "text-align: center;", "⏳ Updating…")
      )
    })
    output$stat_added <- renderUI({
      tags$div(
        class = "stat-card",
        tags$div(style = "text-align: center;", "⏳ Updating…")
      )
    })
    output$stat_paths <- renderUI({
      tags$div(
        class = "stat-card",
        tags$div(style = "text-align: center;", "⏳ Updating…")
      )
    })
    
    res <- arxiv_update(input$q, max_results = as.integer(input$n))
    records_tbl(res$records)
    
    output$stat_rows <- renderUI({
      tags$div(
        class = "stat-card",
        tags$div(tags$b("Rows:"), nrow(res$records)),
        tags$div(tags$b("Query:"), tags$code(input$q))
      )
    })
    
    output$stat_added <- renderUI({
      tags$div(
        class = "stat-card",
        tags$div(tags$b("Added:"), res$added),
        tags$div(tags$b("Max:"), as.integer(input$n))
      )
    })
    
    output$stat_paths <- renderUI({
      tags$div(
        class = "stat-card",
        tags$div(tags$b("CSV:"), tags$code(basename(res$csv_path))),
        tags$div(tags$b("META:"), tags$code(basename(res$meta_path)))
      )
    })
  })
  
  observeEvent(input$refresh, {
    req(records_tbl())
    x <- records_tbl()
    
    if (isTRUE(input$tag)) {
      x <- ti_tag(x, topics_tbl())
      # 🔥 Добавляем primary topic
      x <- ti_assign_primary_topic(x, topics_tbl(), method = "frequency")
    }
    
    tagged_tbl(x)
  })
  
  output$topic_ui <- renderUI({
    req(tagged_tbl())
    x <- tagged_tbl()
    if (!("topic_labels" %in% names(x))) return(NULL)
    
    all_topics <- sort(unique(unlist(strsplit(paste(x$topic_labels, collapse = ";"), ";"))))
    all_topics <- all_topics[nzchar(all_topics)]
    
    selectizeInput(
      "topic", "Filter by any topic",
      choices = c("ALL", all_topics),
      selected = "ALL",
      options = list(placeholder = "Choose a topic…")
    )
  })
  
  # 🔥 Новый UI для primary topic
  output$primary_topic_ui <- renderUI({
    req(tagged_tbl())
    x <- tagged_tbl()
    if (!("primary_topic" %in% names(x))) return(NULL)
    
    primary_topics <- sort(unique(x$primary_topic[!is.na(x$primary_topic)]))
    
    selectizeInput(
      "primary_topic", "Filter by primary topic",
      choices = c("ALL", primary_topics),
      selected = "ALL",
      options = list(placeholder = "Choose primary topic…")
    )
  })
  
  filtered <- reactive({
    req(tagged_tbl())
    x <- tagged_tbl()
    
    if ("published" %in% names(x) && !anyNA(input$dr)) {
      x <- x %>% filter(as.Date(published) >= input$dr[1], as.Date(published) <= input$dr[2])
    }
    
    # Фильтр по любой теме
    if (!is.null(input$topic) && input$topic != "ALL" && "topic_labels" %in% names(x)) {
      x <- x %>% filter(grepl(paste0("(^|;)", input$topic, "(;|$)"), topic_labels))
    }
    
    # 🔥 Фильтр по основной теме
    if (!is.null(input$primary_topic) && input$primary_topic != "ALL" && "primary_topic" %in% names(x)) {
      x <- x %>% filter(primary_topic == input$primary_topic)
    }
    
    tf <- trimws(input$textfilter)
    if (nzchar(tf)) {
      x <- x %>% filter(grepl(tf, title, ignore.case = TRUE) | grepl(tf, summary, ignore.case = TRUE))
    }
    
    x
  })
  
  output$tbl <- renderDT({
    req(filtered())
    x <- filtered()
    
    view <- x %>%
      transmute(
        published = as.Date(published),
        title = title,
        authors = author_names,
        primary = if ("primary_topic" %in% names(x)) primary_topic else NA_character_,
        all_topics = if ("topic_labels" %in% names(x)) topic_labels else NA_character_,
        link = link_abs
      )
    
    view$link <- sprintf(
      '<a class="btn btn-sm btn-outline-primary" target="_blank" href="%s">🔗 Open</a>',
      view$link
    )
    
    datatable(
      view,
      escape = FALSE,
      options = list(
        pageLength = 15,
        autoWidth = TRUE,
        scrollX = TRUE,
        dom = 'frtip',
        language = list(
          search = "Search:",
          lengthMenu = "Show _MENU_ entries",
          info = "Showing _START_ to _END_ of _TOTAL_ entries",
          paginate = list(
            'first' = "First",
            'last' = "Last",
            'next' = "Next",
            'previous' = "Prev"
          )
        )
      ),
      class = 'cell-border stripe hover'
    )
  })
  
  output$topic_tbl <- renderDT({
    req(tagged_tbl())
    x <- tagged_tbl()
    if (!("topic_labels" %in% names(x))) {
      return(datatable(
        data.frame(message = "No topic data available"),
        options = list(dom = 't', ordering = FALSE)
      ))
    }
    
    freq <- ti_topic_freq(x)
    datatable(
      freq, 
      options = list(
        pageLength = 15,
        dom = 'frtip',
        order = list(list(1, 'desc'))
      ),
      class = 'cell-border stripe hover'
    )
  })
  
  output$topic_plot <- renderPlot({
    req(tagged_tbl())
    x <- tagged_tbl()
    
    if (!("topic_labels" %in% names(x))) {
      ggplot() +
        annotate(
          "text", 
          x = 0.5, y = 0.5, 
          label = "No topic data available.\nClick 'Refresh view' with tagging enabled.",
          size = 5,
          color = "#90a4ae"
        ) +
        theme_void() +
        theme(
          plot.background = element_rect(fill = "transparent", color = NA),
          panel.background = element_rect(fill = "transparent", color = NA)
        )
    } else {
      freq <- ti_topic_freq(x)
      
      if (nrow(freq) == 0) {
        ggplot() +
          annotate(
            "text", 
            x = 0.5, y = 0.5, 
            label = "No topics found",
            size = 5,
            color = "#90a4ae"
          ) +
          theme_void() +
          theme(
            plot.background = element_rect(fill = "transparent", color = NA),
            panel.background = element_rect(fill = "transparent", color = NA)
          )
      } else {
        ggplot(freq, aes(x = reorder(topic, n), y = n)) +
          geom_col(
            aes(fill = n),
            alpha = 0.9,
            width = 0.7
          ) +
          scale_fill_gradient(
            low = "#7c4dff",
            high = "#00d4ff",
            guide = "none"
          ) +
          coord_flip() +
          labs(x = NULL, y = "Count") +
          theme_minimal(base_size = 13) +
          theme(
            plot.background = element_rect(fill = "transparent", color = NA),
            panel.background = element_rect(fill = "transparent", color = NA),
            panel.grid.major.y = element_blank(),
            panel.grid.major.x = element_line(color = "#00d4ff", alpha = 0.15, linewidth = 0.5),
            panel.grid.minor = element_blank(),
            axis.text.y = element_text(color = "#e8eaf6", size = 11, face = "bold"),
            axis.text.x = element_text(color = "#b0bec5", size = 10),
            axis.title.x = element_text(color = "#00d4ff", face = "bold", size = 12, margin = margin(t = 10)),
            axis.line = element_blank(),
            text = element_text(color = "#e8eaf6"),
            plot.margin = margin(15, 15, 15, 15)
          )
      }
    }
  }, bg = "transparent")
  
  # 🔥 НОВЫЙ КОД ДЛЯ TRENDS
  output$trend_plot <- renderPlot({
    req(tagged_tbl())
    x <- tagged_tbl()
    
    if (!("topics" %in% names(x))) {
      ggplot() +
        annotate(
          "text", 
          x = 0.5, y = 0.5, 
          label = "No topic data available.\nClick 'Refresh view' with tagging enabled.",
          size = 5,
          color = "#90a4ae"
        ) +
        theme_void() +
        theme(
          plot.background = element_rect(fill = "transparent", color = NA),
          panel.background = element_rect(fill = "transparent", color = NA)
        )
    } else {
      trend <- ti_topic_trend_weekly(x)
      
      if (nrow(trend) == 0) {
        ggplot() +
          annotate(
            "text", 
            x = 0.5, y = 0.5, 
            label = "No trend data available.\nNeed more papers with dates.",
            size = 5,
            color = "#90a4ae"
          ) +
          theme_void() +
          theme(
            plot.background = element_rect(fill = "transparent", color = NA),
            panel.background = element_rect(fill = "transparent", color = NA)
          )
      } else {
        # Берём топ-5 тем для читаемости
        top_topics <- trend %>%
          group_by(topic) %>%
          summarise(total = sum(n, na.rm = TRUE)) %>%
          arrange(desc(total)) %>%
          head(5) %>%
          pull(topic)
        
        trend_filtered <- trend %>%
          filter(topic %in% top_topics)
        
        ggplot(trend_filtered, aes(x = week, y = n, color = topic, group = topic)) +
          geom_line(linewidth = 1.2, alpha = 0.9) +
          geom_point(size = 3, alpha = 0.8) +
          scale_color_manual(
            values = c("#00d4ff", "#7c4dff", "#00e676", "#ffd600", "#ff1744")
          ) +
          labs(
            x = "Week",
            y = "Number of Papers",
            color = "Topic",
            title = "Topic Trends (Top 5)"
          ) +
          theme_minimal(base_size = 13) +
          theme(
            plot.background = element_rect(fill = "transparent", color = NA),
            panel.background = element_rect(fill = "transparent", color = NA),
            panel.grid.major = element_line(color = "#00d4ff", alpha = 0.1, linewidth = 0.5),
            panel.grid.minor = element_blank(),
            axis.text = element_text(color = "#b0bec5", size = 10),
            axis.title = element_text(color = "#00d4ff", face = "bold", size = 12),
            legend.position = "bottom",
            legend.background = element_rect(fill = "transparent", color = NA),
            legend.text = element_text(color = "#e8eaf6", size = 10),
            legend.title = element_text(color = "#00d4ff", face = "bold", size = 11),
            plot.title = element_text(color = "#00d4ff", face = "bold", size = 14, hjust = 0.5),
            text = element_text(color = "#e8eaf6"),
            plot.margin = margin(15, 15, 15, 15)
          )
      }
    }
  }, bg = "transparent")
  
  output$trend_tbl <- renderDT({
    req(tagged_tbl())
    x <- tagged_tbl()
    
    if (!("topics" %in% names(x))) {
      return(datatable(
        data.frame(message = "No topic data available"),
        options = list(dom = 't', ordering = FALSE)
      ))
    }
    
    trend <- ti_topic_trend_weekly(x)
    
    if (nrow(trend) == 0) {
      return(datatable(
        data.frame(message = "No trend data available"),
        options = list(dom = 't', ordering = FALSE)
      ))
    }
    
    datatable(
      trend, 
      options = list(
        pageLength = 20,
        dom = 'frtip',
        order = list(list(0, 'desc'))
      ),
      class = 'cell-border stripe hover'
    )
  })
  
  output$dl <- downloadHandler(
    filename = function() paste0("arxiv_filtered_", Sys.Date(), ".csv"),
    content = function(file) {
      x <- filtered()
      write.csv(x, file, row.names = FALSE, fileEncoding = "UTF-8")
    }
  )
}

shinyApp(ui, server)