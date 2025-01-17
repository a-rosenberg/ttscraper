## ----message = F, warning = F--------------------------------------------
library(tidyverse)
library(Hmisc)


## ----message = F, warning = F--------------------------------------------
library(readxl)
setwd("../Week06")
fname <- "week6_coffee_chains.xlsx"
excel_sheets(fname)
dfStar <- read_excel(fname, 1)
dfTimh <- read_excel(fname, 2)
dfDunk <- read_excel(fname, 3)


## ------------------------------------------------------------------------
# https://stackoverflow.com/a/32505896
# Following the SOF post. Looks like the Google geocode API is very unstable
geocodeAdddress <- function(address) {
  require(RJSONIO)
  url <- "http://maps.google.com/maps/api/geocode/json?address="
  url <- URLencode(paste(url, address, "&sensor=false", sep = ""))
  x <- fromJSON(url, simplify = FALSE)
  if (x$status == "OK") {
    out <- c(x$results[[1]]$geometry$location$lng,
             x$results[[1]]$geometry$location$lat)
  } else {
    cat(paste0(address, "\n"))
    out <- NA
  }
  Sys.sleep(1)  # API only allows 5 requests per second
  out
}

library(ggmap)
TimhUS <- dfTimh %>% 
  rename(ST = state, Country = country, City = city) %>%
  filter(Country == "us") %>% 
  mutate(postal_code = replace(postal_code, 
                               nchar(postal_code) == 4, 
                               paste0("0", postal_code))) %>% 
  mutate(Country = "USA",
         State = openintro::abbr2state(ST),
         address = paste(address, City, ST, postal_code, sep = ", ")) %>% 
  select(Country, address, State, ST, City)

nTimh <- nrow(TimhUS)
loc <- data.frame(Longitude = rep(NA, nTimh), Latitude = rep(NA, nTimh))
for (i in 1 : nTimh){
  loc[i,] <- geocodeAdddress(TimhUS[i, "address"])
  cat(paste0(i, "\n"))
}

# the following loop might need to be tried multiple times
for (i in 1 : nTimh){
  if (is.na(loc[i, 1])) {
    loc[i,] <- geocodeAdddress(TimhUS[i, "address"])
    cat(paste0(i, "\n"))
  }
}

TimhUS <- cbind(TimhUS, loc) %>% 
  select(-address) %>% 
  filter(!is.na(Longitude)) %>% 
  mutate(Store = "Tim Hortons")

write_csv(TimhUS, "Week06/TimHortons_US.csv")

