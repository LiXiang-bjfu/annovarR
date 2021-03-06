% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/web.R
\name{set_shiny_workers}
\alias{set_shiny_workers}
\title{Function to set shiny workers for background service}
\usage{
set_shiny_workers(n,
  shiny_config_file = Sys.getenv("ANNOVARR_SHINY_CONFIG",
  system.file("extdata", "config/shiny.config.toml", package =
  "annovarR")))
}
\arguments{
\item{n}{Number of needed workers}

\item{shiny_config_file}{annovarR shiny configuration file}
}
\description{
Function to set shiny workers for background service
}
\examples{
\dontrun{
set_shiny_workers(4)
}
}
