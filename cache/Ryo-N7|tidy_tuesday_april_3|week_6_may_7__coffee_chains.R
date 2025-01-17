## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)


## ----cars----------------------------------------------------------------
library(dplyr)
library(readxl)
# library(ggplot2)
library(sf)
library(extrafont)
loadfonts()



## ------------------------------------------------------------------------

starbucks_raw <- read_excel("../week_6_may_7/week6_coffee_chains.xlsx", sheet = 1)

glimpse(starbucks_raw)

starbucks_usa <- starbucks_raw %>% 
  janitor::clean_names() %>% 
  select(brand, city, state_province, country, longitude, latitude) %>% 
  filter(country == "US") %>% 
  group_by(state_province) %>% 
  summarize(count = n()) %>% 
  ungroup()

class(starbucks_usa)
# spData::us_states %>% pull(NAME) %>% unique() --- Postal abbrv same as ISO
# ggmap::get_map()
# acs::fips.state %>% st_as_sf()
# us_states %>% glimpse()

states_sf <- tigris::states(cb = TRUE) %>% 
  st_as_sf() %>% 
  select(STUSPS, NAME, geometry) %>% 
  filter(!STUSPS %in% c("VI", "MP", "GU", "PR", "AS")) # filter out territories and Puerto Rico

class(states_sf)

#starbucks_sf <- starbucks_usa %>% left_join(states_sp, by = c("state_province" = "STUSPS")) %>% glimpse()
# starbucks_usa %>% left_join.sf(states_sp, by = c("state_province" = "STUSPS")) %>% class()
starbucks_sf <- states_sf %>% left_join(starbucks_usa, by = c("STUSPS" = "state_province"))

class(starbucks_sf) # sf and data.frame

st_crs(starbucks_sf) # 4269, GRS80

plot(starbucks_sf)

# remove Alaska and Hawaii... for now
starbucks_sf2 <- starbucks_sf %>% filter(!NAME %in% c("Alaska", "Hawaii")) %>% glimpse()
st_crs(starbucks_sf2)

# test
library(ggplot2)
starbucks_sf2 %>% 
  ggplot() +
  geom_sf(aes(fill = count))




## ------------------------------------------------------------------------
# normalize by population
library(spData)

states_pop <- us_states %>% 
  select(GEOID, NAME, total_pop_15) %>% 
  filter(!NAME == "District of Columbia") %>% 
  st_set_geometry(NULL)

states_pop %>% glimpse()
states_pop %>% class()
states_sf %>% class()
st_crs(states_sf)

# merge/join INTO one with sf df or else lose spatial metadata
starbucks_population <- states_sf %>% 
  left_join(states_pop, by = "NAME") %>% 
  left_join(starbucks_usa, by = c("STUSPS" = "state_province"))

# NORMALIZE
library(units)

starbucks_sf_norm2 <- starbucks_sf2 %>% 
  mutate(area_km2 = st_area(geometry) %>% 
           set_units(km^2) %>% 
           as.numeric(),
         area_m2 = st_area(geometry) %>% 
           as.numeric(),
         count_norm_m2 = count / area_m2,
         count_norm_km2 = count / area_km2,
         area_sq2 = st_area(geometry) %>% 
           set_units(mi^2) %>% 
           as.numeric(),
         count_norm_sq2 = count / area_sq2) %>% 
  filter(!NAME == "District of Columbia")

starbucks_population <- starbucks_sf_norm2 %>% 
  left_join(states_pop, by = "NAME") %>% glimpse()


starbucks_population <- starbucks_population %>% 
  mutate(pop_norm = (count / total_pop_15 * 100000) %>% ceiling()) # try per 100,000 people?

library(cartogram)
starb_cartogram <- st_transform(starbucks_population, crs = 2163)

# change to sp
starb_sp <- as(starb_cartogram, "Spatial")

starb_cartogram <- cartogram_ncont(starb_sp, weight = "pop_norm", k = 1)
starb_cartogram <- cartogram_ncont(starb_sp, weight = "pop_norm", k = 10)
starb_cartogram <- cartogram_ncont(starb_sp, weight = "total_pop_15", k = 0.5)

# keep as sf
starb_sf <- starb_cartogram
starb_cartogram <- cartogram_ncont(starb_sf, weight = "pop_norm", k = 1)
starb_cartogram <- cartogram_ncont(starb_sf, weight = "pop_norm", k = 10)
starb_cartogram <- cartogram_ncont(starb_sf, weight = "total_pop_15", k = 0.5)

library(tmap)

# Sequential single hue color palette :: http://colorbrewer2.org/#type=sequential&scheme=Greens&n=5
greenpal <- c('#edf8e9','#bae4b3','#74c476','#31a354','#006d2c')

# add "jenks" process for better interval categories (California and Texas are still their own categories but best I can do with big outliers)
# legend.reverse for HIGH values on TOP, slight sepia to offset white glare?
# fiddle with margins to fit legend and small title
# plot!
starbucks_cartogram <- tm_shape(starb_cartogram) + 
  tm_borders("grey10") +
  tm_fill(title = "", "pop_norm", 
          palette = greenpal, 
          #style = "kmeans",
          legend.reverse = TRUE) +
  tm_layout(inner.margins = c(.04,.02, .08, .02),
            main.title = "Number of Starbucks per 100,000 people",
            title = "(Source: https://www.kaggle.com/starbucks/store-locations)\nState size by total population",
            title.position = c("center", "top"), title.size = 0.7,
            fontfamily = "Garamond", fontface = "bold",
            legend.text.size = 0.85, 
            sepia.intensity = 0.1)

starbucks_cartogram

save_tmap(starbucks_cartogram, "starbucks_cartogram_pop_sf.png")

starb_cartogram %>% 
  mutate(pop_norm = pop_norm * 10) %>% 
  ggplot() +
  geom_sf(aes(fill = pop_norm)) +
  theme_minimal() +
  scale_fill_manual(values = greenpal)



## ------------------------------------------------------------------------

# normalize by area
library(units)

starbucks_sf2 %>% 
  mutate(area_m2 = as.numeric(set_units(st_area(starbucks_sf2$geometry)), km^2))


as.numeric(set_units(st_area(starbucks_sf2$geometry)), km^2)

x <- st_area(starbucks_sf2$geometry)

glimpse(x)

x

x_km <- set_units(x, km^2)

glimpse(x_km)

x_km

x_km_num <- as.numeric(x_km)

glimpse(x_km_num)

x_km_num

st_area(starbucks_sf2$geometry) %>% set_units(mi^2) %>% as.numeric() %>% glimpse()

starbucks_sf_norm <- starbucks_sf2 %>% 
  mutate(area_km2 = st_area(geometry) %>% 
           set_units(km^2) %>% 
           as.numeric(),
         area_m2 = st_area(geometry) %>% 
           as.numeric(),
         count_norm_m2 = count / area_m2,
         count_norm_km2 = count / area_km2,
         area_sq2 = st_area(geometry) %>% 
           set_units(mi^2) %>% 
           as.numeric(),
         count_norm_sq2 = count / area_sq2) %>% 
  filter(!NAME == "District of Columbia")

starbucks_sf_norm2 <- starbucks_sf2 %>% 
  mutate(area_km2 = st_area(geometry) %>% 
           set_units(km^2) %>% 
           as.numeric(),
         area_m2 = st_area(geometry) %>% 
           as.numeric(),
         count_norm_m2 = count / area_m2,
         count_norm_km2 = count / area_km2,
         area_sq2 = st_area(geometry) %>% 
           set_units(mi^2) %>% 
           as.numeric(),
         count_norm_sq2 = count / area_sq2) %>% 
  filter(!NAME == "District of Columbia")

library(cartogram)
starb_cartogram <- st_transform(starbucks_sf_norm2, crs = 2163)

starb_sp <- as(starb_cartogram, "Spatial")

starb_cartogram <- cartogram_ncont(starb_sp, weight = "count_norm_m2", k = 1000)
starb_cartogram <- cartogram_ncont(starb_sp, weight = "count_norm_km2", k = 1)
starb_cartogram <- cartogram_ncont(starb_sp, weight = "count_norm_sq2", k = 1) # 10000 with DC
starb_cartogram <- cartogram_ncont(starb_sp, weight = "count_norm_sq2", k = 5) # 10000 with DC
starb_cartogram <- cartogram_ncont(starb_sp, weight = "count_norm_sq2", k = 2) # 10000 with DC

library(tmap)

# Sequential single hue color palette :: http://colorbrewer2.org/#type=sequential&scheme=Greens&n=5
greenpal <- c('#edf8e9','#bae4b3','#74c476','#31a354','#006d2c')

# add "jenks" process for better interval categories (California and Texas are still their own categories but best I can do with big outliers)
# legend.reverse for HIGH values on TOP, slight sepia to offset white glare?
# fiddle with margins to fit legend and small title
# plot!
starbucks_cartogram <- tm_shape(starb_cartogram) + 
  tm_borders("grey10") +
  tm_fill(title = "Starbucks / sq.mile", "count_norm_sq2", 
          palette = greenpal, 
          style = "jenks",
          legend.reverse = TRUE) +
  tm_layout(inner.margins = c(.04,.02, .08, .02),
            main.title = "Number of Starbucks per sq. mile across the United States",
            title = "(Source: https://www.kaggle.com/starbucks/store-locations)\n(@R_by_Ryo, #TidyTuesday)",
            title.position = c("center", "top"), title.size = 0.7,
            fontfamily = "Garamond", fontface = "bold",
            legend.text.size = 0.85, 
            sepia.intensity = 0.1)

starbucks_cartogram

save_tmap(starbucks_cartogram, "starbucks_cartogram_sq_mile.png")


## ------------------------------------------------------------------------
# dev="cairo_pdf", dev.args=list(family = "Lucida Console") crs = 2163
library(cartogram)
starb_cartogram <- st_transform(starbucks_sf2, crs = 2163)

# reshape as sp object for cartogram_ncont()
starb_sp <- as(starb_cartogram, "Spatial")

# construct non-contiguous area cartogram
starb_cartogram <- cartogram_ncont(starb_sp, weight = "count") # k = 1 is default

library(tmap)

# Sequential single hue color palette :: http://colorbrewer2.org/#type=sequential&scheme=Greens&n=5
greenpal <- c('#edf8e9','#bae4b3','#74c476','#31a354','#006d2c')


# add "jenks" process for better interval categories (California and Texas are still their own categories but best I can do with big outliers)
# legend.reverse for HIGH values on TOP, slight sepia to offset white glare?
# fiddle with margins to fit legend and small title
# plot!
starbucks_cartogram <- tm_shape(starb_cartogram) + 
  tm_borders("grey10") +
  tm_fill(title = "", "count", 
          palette = greenpal, 
          style = "jenks",
          legend.reverse = TRUE) +
  tm_layout(inner.margins = c(.04,.02, .08, .02),
            main.title = "Number of Starbucks across the United States",
            title = "(Source: https://www.kaggle.com/starbucks/store-locations)\n(@R_by_Ryo, #TidyTuesday)",
            title.position = c("center", "top"), title.size = 0.9,
            fontfamily = "Garamond", fontface = "bold",
            legend.text.size = 0.85, 
            sepia.intensity = 0.1)




## ------------------------------------------------------------------------
save_tmap(starbucks_cartogram, "starbucks_cartogram.png")


## ----all-----------------------------------------------------------------
library(dplyr)
library(readxl)
library(sf)

# read-in data
starbucks_raw <- read_excel("../may_7_week_6/week6_coffee_chains.xlsx", sheet = 1)

# clean, select cols, filter USA, summarize
starbucks_usa <- starbucks_raw %>% 
  janitor::clean_names() %>% 
  select(brand, city, state_province, country, longitude, latitude) %>% 
  filter(country == "US") %>% 
  group_by(state_province) %>% 
  summarize(count = n()) %>% 
  ungroup()

# grab geometries of USA from tigris pkg, turn into sf
states_sf <- tigris::states(cb = TRUE) %>% 
  st_as_sf() %>% 
  select(STUSPS, NAME, geometry) %>% 
  filter(!STUSPS %in% c("VI", "MP", "GU", "PR", "AS")) # filter out territories and Puerto Rico

# join with starbucks data
starbucks_sf <- states_sf %>% left_join(starbucks_usa, by = c("STUSPS" = "state_province"))

# remove Alaska and Hawaii... try to rescale and put them back in another time
starbucks_sf2 <- starbucks_sf %>% filter(!NAME %in% c("Alaska", "Hawaii"))

# change crs to one cartogram_ncont() expects (sf compatibility for cartogram pkg coming soon i think...)
starb_cartogram <- st_transform(starbucks_sf2, crs = 2163)

# change back into sp object for cartogram_ncont()
starb_sp <- as(starb_cartogram, "Spatial")

# construct non-contiguous area cartogram, area weighed by "count" var 
library(cartogram)
starb_cartogram <- cartogram_ncont(starb_sp, weight = "count") # k = 1 is default

# Sequential single hue color palette :: http://colorbrewer2.org/#type=sequential&scheme=Greens&n=5
greenpal <- c('#edf8e9','#bae4b3','#74c476','#31a354','#006d2c')


# add "kmeans" process for better class intervals for the colors
# (California is still in their own category but best I can do with such big outliers)
# Texas has x2 the amount of Starbucks as NY, WA, and FL but size relative only to CA?
# can also use hclust, kmeans, quantile, jenks to varying success
# legend.reverse for HIGH values on TOP, slight sepia to offset white glare?
# fiddle with inner.margins to fit legend and small title
library(tmap)

starbucks_cartogram <- tm_shape(starb_cartogram) + 
  tm_borders("grey10") +
  tm_fill(title = "", "count", 
          palette = greenpal, 
          style = "kmeans",
          legend.reverse = TRUE) +
  tm_layout(inner.margins = c(.04,.02, .08, .02),
            main.title = "Number of Starbucks across the United States",
            title = "(Source: https://www.kaggle.com/starbucks/store-locations)\n(@R_by_Ryo, #TidyTuesday)",
            title.position = c("center", "top"), title.size = 0.9,
            fontfamily = "Garamond", fontface = "bold",
            legend.text.size = 0.85, 
            sepia.intensity = 0.2)

starbucks_cartogram

save_tmap(starbucks_cartogram, "starbucks_cartogram.png")



## ------------------------------------------------------------------------
starbucks_cartogram

