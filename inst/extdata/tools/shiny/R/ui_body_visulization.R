clean_parsed_item <- function(item, req_parse = FALSE) {
  item <- stringr::str_replace_all(item, "\\\\n", "\n")
  item <- stringr::str_replace_all(item, "\\\\\"", "\"")
  if (req_parse) {
    return(sprintf("eval(parse(text = %s))", item))
  }
  item
}
generate_boxes_object <- function(config) {
  items <- config$maftools$ui$sections$order
  sapply(items, function(item) {
    basic_params <- config$maftools$ui$sections$ui_basic[[item]]
    section_type <- config$maftools$paramters[[item]]$section_type
    if (section_type == "input") {
      input_sections <- config$maftools$paramters[[item]]$input_ui_order
      advanced_params <- ""
      for (input_section in input_sections) {
        input_section_dat <- config$maftools$paramters[[item]]$input[[input_section]]
        section_type <- input_section_dat$type
        title <- input_section_dat$title
        title_control <- input_section_dat$title_control
        label <- input_section_dat$label
        choices <- input_section_dat$choices
        selected <- input_section_dat$selected
        varname <- input_section_dat$varname
        input_id <- input_section_dat$input_id
        if (!is.null(title) && !is.null(title_control)) {
          advanced_params <- sprintf("%s, shiny::p('%s', %s)", advanced_params,
          title, title_control)
        } else if (!is.null(title)) {
          advanced_params <- sprintf("%s, shiny::p('%s')", advanced_params)
        }
        for (id_index in 1:length(input_id)) {

          var <- varname[id_index]
          advanced_params <- sprintf("%s, %s(inputId='%s', label = '%s'",
          advanced_params, section_type[id_index], input_id[id_index],
          label[id_index])
          for (param_name in c("choices", "selected", "width", "multiple",
          "buttonLabel", "placeholder", "value", "height", "rows", "cols",
          "resize", "ui_pre")) {
          if (param_name %in% names(input_section_dat)) {
            if (is.null(names(input_section_dat[[param_name]])))
            var <- id_index
            param_value <- input_section_dat[[param_name]][[var]]
            if (is.null(param_value)) {
            next
            }
            if (param_name == "ui_pre") {
            advanced_params <- sprintf("%s), shiny::verbatimTextOutput(outputId='%s'",
              advanced_params, paste0(item, "_", var, "_pre"))
            next
            }
            if (is.character(param_value)) {
            advanced_params <- sprintf("%s, %s=\"%s\"", advanced_params,
              param_name, input_section_dat[[param_name]][[var]])
            } else {
            advanced_params <- sprintf("%s, %s=%s", advanced_params,
              param_name, input_section_dat[[param_name]][[var]])
            }
          }
          }
          advanced_params <- sprintf("%s)", advanced_params)
        }
      }
    } else {
      render_id <- config$maftools$paramters[[item]]$render_id
      render_type <- config$maftools$paramters[[item]]$render_type
      output_type <- config$maftools$paramters[[item]]$output_type

      advanced_params <- sprintf(", withSpinner(%s(outputId = '%s'), type = 8)",
        output_type, render_id)
      if (render_type %in% c("shiny::renderImage", "shiny::renderPlot")) {

        export_params <- config$maftools$paramters[[item]]$export_params
        width <- stringr::str_replace(stringr::str_extract(export_params,
          "width = [0-9]*"), "width = ", "")
        height <- stringr::str_replace(stringr::str_extract(export_params,
          "height = [0-9]*"), "height = ", "")
        advanced_params <- sprintf("%s, shiny::column(6, wellPanel (shiny::sliderInput('export_%s_height', min = 0, max = 100, value = %s, label = 'height (cm)')))",
          advanced_params, render_id, height)
        advanced_params <- sprintf("%s, shiny::column(6, wellPanel (shiny::sliderInput('export_%s_width', min = 0, max = 100, value = %s, label = 'width (cm)')))",
          advanced_params, render_id, width)
        advanced_params <- sprintf("%s, shiny::downloadButton('export_%s', label = 'Export PDF')",
          advanced_params, render_id)
      }
    }

    cmd <- sprintf("box(%s%s)", basic_params, advanced_params)
    return(cmd)
  })
}

# Generate maftools UI
config.maftools <- configr::read.config(system.file("extdata", "config/shiny.maftools.parameters.toml",
  package = "annovarR"), rcmd.parse = TRUE, file.type = "toml")
boxes <- generate_boxes_object(config.maftools)

cmd <- sprintf(paste0("body_visulization_tabItem <- tabItem('dashboard',", "tabsetPanel(type = 'pills',",
  "tabPanel('maftools',", "fluidRow( %s )))", ")"), paste0(unname(boxes), collapse = ","))

body_visulization_tabItem <- eval(parse(text = cmd))