# prepare environment ----------------------------------------------------------

# clear environment
rm(list = ls())

# import shiny libs
library(shiny)
library(shinydashboard)
library(shinydashboardPlus)
library(shinycssloaders)
library(htmlwidgets)

# import graph libs
library(echarts4r)

# import data wrangling libs
library(lubridate)
library(magrittr)
library(tidyverse)

# prepare datasets ------------------------------------------------------------

# time series
trend <- readRDS("data/timeseries/summary/trend.RDS")
trend_agg <- readRDS("data/timeseries/summary/trend-agg.RDS")
