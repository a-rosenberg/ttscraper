## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)


## ------------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(ggplot2)
library(readr)

acs_survey <- read_csv("../april_30_week_5/acs2015_county_data.csv")

glimpse(acs_survey)

# gather on Ethnicity
acs_survey <- acs_survey %>% gather(key = "ethnicity", value = "percentage", Hispanic:Pacific)





## ------------------------------------------------------------------------
library(albersusa)

counties_map_data <- counties_composite()

glimpse(counties_map_data@data)


counties_map_data@data <- left_join(counties_map_data@data, acs_survey, by = c("name" = "County"))

anti_counties_map_data <- anti_join(counties_map_data@data, acs_survey, by = c("name" = "County"))
# ~50 counties from Alaska and Virginia dont have matching name == County between 2 data sets.........


# CensusID  == fips >>> fips is chr and has 0 in front of all

glimpse(counties_map_data@data)

plot(counties_map_data, lwd = 0.25)

c_map <- fortify(counties_map_data, region = "fips")




## ------------------------------------------------------------------------
library(dplyr)
library(ggplot2)
library(maps)

counties <- map_data("county")

acs_survey <- acs_survey %>% mutate(County = tolower(County),
                                    State = tolower(State))

all_county <- counties %>% inner_join(acs_survey, by = c("subregion" = "County",
                                                         "region" = "State"))


glimpse(all_county)


county_plot <- function(x) {
  
  all_county$x <- all_county[, x]
  
  
  counties %>% 
    ggplot(aes(x = long, y = lat, group = group)) +
    coord_fixed(1.3) +
    geom_polygon(data = all_county, aes(fill = x), color = "grey30", size = 0.05) +
    labs(fill = x) +
    scale_fill_distiller(palette = "Spectral") +
    theme_void()

}

county_plot("Unemployment")
county_plot("Income")
county_plot("Asian")
county_plot("Poverty")



