## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)


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
TimhUS <- read_csv("TimHortons_US.csv")


## ----fig.width = 10------------------------------------------------------
library(usmap)
data(statepop)

# Select US Starbucks  
StarUS <- dfStar %>% 
  rename(ST = `State/Province`) %>%
  filter(Country == "US") %>% 
  mutate(State = openintro::abbr2state(ST)) %>% 
  select(Country, State, ST, City, Longitude, Latitude) %>% 
  mutate(Store = "Starbucks")

# Starbucks numbers in each states  
avgStarUS <- StarUS %>% 
  group_by(State) %>% 
  summarise(count = n(), ST = unique(ST)) %>% 
  left_join(statepop, by = c("ST" = "abbr")) %>% 
  mutate(Avg = count/pop_2015 * 1e5) 

# Select US Duckin  
DuckUS <- dfDunk %>% 
  rename(Country = e_country, ST = e_state, City = e_city,
         Longitude = loc_LONG_poly, Latitude = loc_LAT_poly) %>% 
  mutate(State = openintro::abbr2state(ST)) %>% 
  select(Country, State, ST, City, Longitude, Latitude) %>% 
  filter(Country == "USA") %>% 
  mutate(Store = "Dunkin' Donuts")
  
SDUS <- rbind(StarUS, DuckUS, TimhUS)
avgSDUS <- SDUS %>% 
  group_by(State, Store) %>% 
  summarise(count = n(), ST = unique(ST)) %>% 
  left_join(statepop, by = c("ST" = "abbr")) %>% 
  mutate(Avg = count/pop_2015 * 1e5)


## ----fig.width = 10------------------------------------------------------
library(albersusa)
us      <- usa_composite()
us_map  <- broom::tidy(us, region = "name")

p <- ggplot() +
  geom_map(data = avgStarUS, aes(fill = Avg, map_id = State),
           color="white", size = 0.01, map = us_map) + 
  scale_fill_distiller(name = "Number", palette = "Spectral") +
  expand_limits(x = us_map$long, y = us_map$lat) +
  coord_map() +
  theme_void() +
  theme(legend.position=c(.88, .4))+
  ggtitle( "Starbucks Stores per 100, 000 population" ) +
  labs(caption = "Source: US Census Demogrpahic Data 2015")
  
p


## ----fig.width = 10------------------------------------------------------
StarCONUS <- filter(StarUS, ST != "HI" & ST != "AK")
avgStarCONUS <- filter(avgStarUS, ST != "HI" & ST != "AK")
 
t <- ggplot() +
  geom_map(data = avgStarCONUS, aes(fill = Avg, map_id = State),
           color="white", size = 0.01, map = us_map) + 
  scale_fill_distiller(name = "Number", palette = "Spectral") +
  geom_point(data = StarCONUS, aes(x = Longitude, y = Latitude), size = 0.04, alpha = 0.1) +

  expand_limits(x = us_map$long, y = us_map$lat) +
  coord_map() +
  theme_void() +
  theme(legend.position=c(.88, .4)) +
  ggtitle( "Starbucks Stores per 100, 000 population" ) +
  labs(caption = "Source: US Census Demogrpahic Data 2015")
t
#t + coord_map("polyconic")


## ----fig.width = 10------------------------------------------------------
StarCONUS <- filter(StarUS, ST != "HI" & ST != "AK")
SDCONUS   <- filter(SDUS, ST != "HI" & ST != "AK")
us_map <- filter(us_map, id !="Hawaii" & id != "Alaska") 

c <- ggplot() +
  geom_map(data = us_map, aes(map_id = id),
           color="#2b2b2b", size = 0.1, fill = NA, map = us_map) + 
  #scale_fill_distiller(name = "Number", palette = "Spectral") +
  geom_point(data = SDCONUS, aes(x = Longitude, y = Latitude, color = Store), 
             size = 0.5, alpha = 0.1) +
  expand_limits(x = us_map$long, y = us_map$lat) +
  coord_map() +
  theme_void() +
#  theme(legend.position = "top")+
  ggtitle( "Starbucks and Dunkin's Donuts Stores" ) +
  labs(caption = "Source: US Census Demogrpahic Data 2015") +
  guides(colour = guide_legend(title = NULL, override.aes = list(size = 3 ))) +
  theme(legend.position=c(.88, .3)) 
c


## ----fig.height = 15, fig.width = 10-------------------------------------
library(grid)
library(gridExtra)
grid.arrange(p, t, c, ncol = 1)


## ----fig.width = 10------------------------------------------------------
SDCONUS   <- filter(SDUS, ST  == "MI")
us_map <- broom::tidy(us, region = "name") %>% filter(id == "Michigan") 

m <- ggplot() +
  geom_map(data = us_map, aes(map_id = id),
           color="#2b2b2b", size = 0.1, fill = NA, map = us_map) + 
  geom_point(data = SDCONUS, aes(x = Longitude, y = Latitude, color = Store), 
             size = 1, alpha = 0.1) +
  expand_limits(x = us_map$long, y = us_map$lat) +
  coord_map() +
  theme_void() +
#  theme(legend.position = "top")+
  ggtitle( "Coffee Stores" ) +
  guides(colour = guide_legend(title = NULL, override.aes = list(size = 3 ))) +
  theme(legend.position=c(.3, .3)) 
m


## ----message = F, warning = F, fig.height = 10, fig.width = 10-----------
library(ggmap)
SDCONUS   <- filter(SDUS, City == "New York")
us_map    <- broom::tidy(us, region = "name") %>% filter(id == "New York") 
nyc_base  <- get_map("Manhattan", zoom = 12, maptype = "toner-lite")

d <- nyc_base %>% 
  ggmap() +
  geom_point(data = SDCONUS, aes(x = Longitude, y = Latitude, color = Store, shape = Store), 
             size = 2) +
#  coord_map() +
  theme_void() +
  theme(legend.position = "top")+
  ggtitle( "Coffee Stores in Manhattan" ) +
  guides(shape = guide_legend(title = NULL, override.aes = list(size = 3 ))) +
  guides(colour = guide_legend(title = NULL, override.aes = list(size = 3 ))) 

d

