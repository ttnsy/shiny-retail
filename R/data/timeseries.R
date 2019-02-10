# prepare environment ----------------------------------------------------------

# clear environment
rm(list = ls())

# import libs
library(magrittr)
library(lubridate)
library(padr)
library(tidyverse)

# prepare dataset --------------------------------------------------------------

# import history dataset
history <- readRDS("data/history.RDS")

# quick check
glimpse(history)

# get valid orders by order status
history %<>%
  arrange(customer_id, invoice_date) %>%
  group_by(customer_id, stock_code) %>%
  mutate(
    next_status = lead(status, default = "NA"),
    status = ifelse(status == "Order" & next_status == "Cancel", NA, status),
    status = ifelse(status != "Order", NA, status)
  ) %>%
  ungroup() %>%
  drop_na() %>%
  select(-next_status) %>%
  arrange(invoice_date)

# data wrangling: hourly time series -------------------------------------------

# hourly time series range
start_val <-
  paste(
    min(as_date(history$invoice_date)),
    min(hour(history$invoice_date))
  ) %>%
  ymd_h()

end_val <-
  paste(
    max(as_date(history$invoice_date)),
    max(hour(history$invoice_date))
  ) %>%
  ymd_h()

# aggregate to hourly time series
trend <- history %>%
  arrange(invoice_date) %>%
  group_by(datetime = floor_date(invoice_date, "hour"), country) %>%
  summarise(
    customer = n_distinct(customer_id),
    quantity = sum(quantity),
    amount = sum(unit_price)
  ) %>%
  group_by(country) %>%
  pad("hour", start_val, end_val) %>%
  ungroup() %>%
  filter(
    wday(datetime) %in% unique(wday(history$invoice_date)),
    hour(datetime) >= min(hour(history$invoice_date)),
    hour(datetime) <= max(hour(history$invoice_date))
  ) %>%
  replace(is.na(.), 0)

# aggregate further to all country
trend_agg <- trend %>%
  group_by(datetime) %>%
  summarise(
    customer = sum(customer),
    quantity = sum(quantity),
    amount = sum(amount)
  ) %>%
  ungroup()

# export -----------------------------------------------------------------------

# save to RDS
saveRDS(trend, "data/timeseries/summary/trend.RDS")
saveRDS(trend_agg, "data/timeseries/summary/trend-agg.RDS")
