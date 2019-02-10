# prepare environment ----------------------------------------------------------

# clear environment
rm(list = ls())

# import libs
library(magrittr)
library(readxl)
library(tidyverse)

# prepare raw data -------------------------------------------------------------

# import the raw data
history <- read_excel("data-raw/Online Retail.xlsx")

# quick check
glimpse(history)

# cleaning ---------------------------------------------------------------------

# adjust the naming convention
colnames(history) %<>%
  str_squish() %>%
  str_replace_all("((?<=[:lower:])[:upper:](?=.))", "_\\1") %>%
  str_to_lower()

# add order status
history %<>%
  mutate(status = case_when(
    quantity < 0 ~ "Return",
    quantity < 0 & str_detect(invoice_no, "C") ~ "Cancel",
    TRUE ~ "Order"
  ))

# readjust cancel/returned quantity
history %<>%
  mutate(
    quantity = ifelse(quantity < 0, -quantity, quantity),
    invoice_no = str_replace_all(invoice_no, "[:alpha:]", "")
  )
  
# squish all strings for safety
history %<>%
  mutate_if(is.character, funs(str_squish(.)))

# drop all NAs
history %<>% drop_na()

# rearrange
history %<>%
  select(invoice_date, everything()) %>%
  arrange(invoice_date)

# export -----------------------------------------------------------------------

# save to RDS
saveRDS(history, "data/history.RDS")
