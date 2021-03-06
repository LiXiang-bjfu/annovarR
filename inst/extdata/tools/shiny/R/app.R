pkgs.shiny <- c("shinycssloaders", "Cairo", "shinydashboard", "configr",
                "data.table", "shinyjs", "liteq", "DT", "ggplot2", "benchmarkme",
                "stringr")
sapply(pkgs.shiny, function(x) {
  require(x, character.only = TRUE)
})
# source UI required code config.R sourced in the body_upload_ui.R
files <- list.files(".", "^ui_")
files <- c(files, "config.R")
for (i in files) {
  source(i, encoding = "UTF-8")
}

get_tabItems <- function () {
  source("config.R")
  items <- c("introduction", "dashbord",
             "file_viewer", "visulization",
             "annotation", "pipeline",
             "upload", "download")
  body_items <- sprintf("get_%s_tabItem_ui()", items)
  cmd <- sprintf("tabItems(%s)", paste0(body_items, collapse = ", "))
  eval(parse(text = cmd))
}

header <- dashboardHeader(title = "annovarR Shiny APP", messages, notifications,
  tasks)

sidebar <- dashboardSidebar(
  sidebarSearchForm(label = "Search...", "searchText", "searchButton"),
  sidebarMenu(id = "navbar_tabs",
    menuItem("Introduction", tabName = "introduction", icon = icon("home")),
    menuItem("Dashbord", tabName = "dashboard", icon = icon("dashboard")),
    menuItem("Annotation", tabName = "annotation", icon = icon("leaf")),
    menuItem("Visulization", tabName = "visulization", icon = icon("bar-chart")),
    menuItem("Pipeline", tabName = "pipeline", icon = icon("diamond")),
    menuItem("File Viewer", tabName = "file_viewer", icon = icon("file")),
    menuItem("Upload", tabName = "upload", icon = icon("cloud-upload")),
    menuItem("Downloader", icon = icon("cloud-download"), tabName = "download"),
    menuItem("Source code for app", icon = icon("file-code-o"),
             href = "https://github.com/JhuangLab/annovarR/blob/master/inst/extdata/tools/shiny/R/app.R")
  )
)

body <- dashboardBody(
  shinyjs::useShinyjs(),
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css"),
    tags$link(type = "text/javascript", src = "custom.js")),
  shiny::uiOutput("task_submit_modal"),
  shiny::actionButton("dashbord_auto_update", label = "dashbord_auto_update",
                        style = "display:none;"),
  get_tabItems()
)

# Defined shiny UI
ui <- dashboardPage(header, sidebar, body, skin = skin)

server <- function(input, output, session) {
  files <- c("server_utils.R", "server_download.R", "server_upload_file.R", "server_dashbord.R")
  for (i in files) {
    source(i, encoding = "UTF-8")
  }
  output <- render_input_box_ui(input, output)
  for(tool in unlist(annovarR_shiny_tools_list)) {
    eval(parse(text = sprintf('output <- %s_server(input, output)', tool)))
  }
  out <- server_upload_file(input, output, session)
  output <- out$output
  session <- out$session
  output <- dashbord_section_server(input, output)
  observeEvent(input$dashbord_auto_update, {
    last_update_time <- Sys.getenv('last_dashbord_update_time')
    if (last_update_time == "") {
      last_update_time <- Sys.time()
      output <- update_system_monitor(input, output)
    } else if (as.numeric(Sys.time() - last_update_time) >= 10) {
      output <- update_system_monitor(input, output)
    }
  })
  output <- download_section_server(input, output)
}
shinyApp(ui, server)
