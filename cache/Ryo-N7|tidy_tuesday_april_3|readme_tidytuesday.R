## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, message = FALSE, warning = FALSE)


## ------------------------------------------------------------------------
library(xlsx)
library(dplyr)
library(stringr)
library(tidyr)
library(ggplot2)
library(scales)



## ------------------------------------------------------------------------

usa_avg_tuition <- read.xlsx(file = "april_3_week_1/us_avg_tuition.xlsx", sheetName = "Table 5")

glimpse(usa_avg_tuition)

colnames(usa_avg_tuition)



## ------------------------------------------------------------------------

colnames(usa_avg_tuition) <- colnames(usa_avg_tuition) %>% 
  str_replace_all("X", "") %>% 
  str_replace("\\.", "-20")

# manually change 2007-2008 ...

usa_avg_tuition <- usa_avg_tuition %>% rename(`2007-2008` = `-20.2007.08.`)



## ------------------------------------------------------------------------

usa_avg_tuition <- usa_avg_tuition %>% gather(key = "year", value = "tuition", -State)

usa_avg_tuition <- usa_avg_tuition %>% 
  arrange(year, desc(tuition)) %>% 
  group_by(year) %>% 
  mutate(rank = dense_rank(desc(tuition)))


usa_avg_tuition <- usa_avg_tuition %>% 
  mutate(state = as.character(State))



## ------------------------------------------------------------------------

top_states <- usa_avg_tuition %>% 
  filter(year %in% c("2004-2005", "2015-2016") & rank %in% c(1:10)) %>% 
  pull(state) %>% 
  unique()

top_states

usa_avg_tuition <- usa_avg_tuition %>% 
  mutate(top_tuition = state %in% top_states,
         tuition = round(tuition, digits = 2))

colors = c(
  Vermont = "#EE2C2C",          # red
  Pennsylvania = "lightgreen",        # dark blue
  Ohio = "#00441b",          # green
  `New Hampshire` = "#4a1486",        # purple
  `New Jersey` = "#636363",        # dark grey
  Massachusetts = "#fd8d3c",    # orange
  Maryland = "#000000",          # black
  Delaware = "blue",
  `South Carolina` = "brown",
  Illinois = "pink",
  Michigan = "yellow",
  Virginia = "violet"
)



## ------------------------------------------------------------------------
library(extrafont)

theme_tuition <-  
  theme(text = element_text(family = "Arial Narrow", color = "#444444", face = "bold"),
        plot.title = element_text(size = 24, hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5),
        axis.title = element_text(size = 14),
        axis.title.y = element_text(angle = 0, vjust = 0.5, margin = margin(r = 15)),
        axis.text = element_text(size = 12),
        axis.text.x = element_text(angle = 35, vjust = 1.3, hjust = 1.1,
                                   margin = margin(t = 15, r = 0, b = 0, l = 0)),
        axis.title.x = element_text(margin = margin(t = 8)),
        panel.grid.minor.y = element_blank(),
        legend.title = element_blank(),
        legend.position = "none")



## ----fig.height=7, fig.width=9, fig.align='center'-----------------------

usa_avg_tuition %>% 
  filter(top_tuition == TRUE) %>% 
  ggplot(aes(year, rank, group = state)) +
  geom_line(aes(color = state), size = 1.6, alpha = 0.75) +
  geom_point(aes(color = state), size = 3, alpha = 1) +
  scale_y_reverse(breaks = 1:10) +         # show only top 10!
  geom_text(data = usa_avg_tuition %>% filter(year == "2004-2005"),
            aes(label = state, x = -0.3), 
            fontface = "bold", color = "black", size = 3.5) +
  geom_label(data = usa_avg_tuition %>% filter(year == "2004-2005"),
            aes(label = paste("$", tuition)), nudge_x = -1.3, nudge_y = -0.4, 
            fontface = "bold", color = "black", size = 2.5) +
  geom_text(data = usa_avg_tuition %>% filter(year == "2015-2016"),
            aes(label = state, x = 13.25), 
            fontface = "bold", color = "black", size = 3.5) +
  geom_label(data = usa_avg_tuition %>% filter(year == "2015-2016"),
             aes(label = paste("$", tuition)), nudge_x = 1.3, nudge_y = -0.4, 
             fontface = "bold", color = "black", size = 2.5) +
  coord_cartesian(ylim = c(1, 10.3), xlim = c(-0.9, 14)) +
  theme_tuition +
  scale_color_manual(values = colors) +
  labs(x = "Year", 
       y = "Rank\n&\nTuition",
       title = "Average College Tuition Rankings in the United States",
       subtitle = "By State, 2004-2005 to 2015-2016",
       caption = "By: Ryo Nakagawara (@R_by_Ryo) \n Source: https://onlinembapage.com/average-tuition-and-educational-attainment-in-the-united-states/\n#TidyTuesday")



## ----fig.height=12, fig.width=9, fig.align='center'----------------------
# ALL states
library(viridis)

usa_avg_tuition %>% 
  ggplot(aes(year, rank, group = state)) +
  geom_line(aes(color = state), size = 1.6, alpha = 0.75) +
  geom_point(aes(color = state), size = 3, alpha = 1) +
  #scale_color_viridis(option = "A") +
  scale_y_reverse(breaks = 1:50) +         # show only top 10!
  geom_text(data = usa_avg_tuition %>% filter(year == "2004-2005"),
            aes(label = state, x = -0.3), 
            fontface = "bold", color = "black", size = 2.7) +
  geom_label(data = usa_avg_tuition %>% filter(year == "2004-2005"),
            aes(label = paste("$", tuition)), nudge_x = -1.3, nudge_y = -0.4, 
            fontface = "bold", color = "black", size = 1.5) +
  geom_text(data = usa_avg_tuition %>% filter(year == "2015-2016"),
            aes(label = state, x = 13.25), 
            fontface = "bold", color = "black", size = 2.7) +
  geom_label(data = usa_avg_tuition %>% filter(year == "2015-2016"),
             aes(label = paste("$", tuition)), nudge_x = 1.3, nudge_y = -0.4, 
             fontface = "bold", color = "black", size = 1.5) +
  coord_cartesian(ylim = c(1, 51), xlim = c(-0.9, 14)) +
  theme_tuition +
  labs(x = "Year", 
       y = "Rank\n&\nTuition",
       title = "Average College Tuition Rankings in the United States",
       subtitle = "By State, 2004-2005 to 2015-2016",
       caption = "By: Ryo Nakagawara (@R_by_Ryo) \n Source: https://onlinembapage.com/average-tuition-and-educational-attainment-in-the-united-states/\n#TidyTuesday") +
  theme(axis.text.y = element_text(size = 6.5))




## ------------------------------------------------------------------------

library(dplyr)
library(tidyr)
library(ggplot2)
library(xlsx)

## Load file
df <- read.csv(file = "../tidy_tuesday/april_16_week_3/df.csv")

## Easily clean names
df <- df %>% janitor::clean_names() 



## ------------------------------------------------------------------------
## Gather cause of deaths under single column 
df_gather <- df %>% 
  gather(key = "cause_of_death", value = "percentages", -country, -country_code, -year) 

## Use stringr functions to make cleaned names work on plot, leave HIV/AIDS for now...
library(stringr)

df_gather <- df_gather %>% 
  mutate(cause_of_death = stringr::str_replace_all(cause_of_death, "_", " "),
         cause_of_death = stringr::str_to_title(cause_of_death),
         cause_of_death = case_when(
           cause_of_death == "Hiv Aids" ~ "HIV/AIDS",
           TRUE ~ cause_of_death
         )) 




## ------------------------------------------------------------------------
library(wpp2015)

data("UNlocations")

UNlocations <- UNlocations %>% select(ends_with("name"))

df2 <- df_gather %>% 
  inner_join(UNlocations, by = c("country" = "name"))

## Only look at countries in the "Eastern Africa" region
east_afr <- df2 %>% 
  filter(reg_name == "Eastern Africa")



## ----eval=FALSE----------------------------------------------------------
## library(purrr)
## 
## nested_east_afr <- east_afr %>%
##   mutate(percentages = percentages/100) %>%
##   group_by(year) %>%
##   nest() %>%
##   mutate(plot = map2(data, year,
##                      ~ggplot(data = .x, aes(reorder(cause_of_death, percentages), percentages)) +
##                        geom_boxplot(fill = "white", color = "darkred", outlier.color = "black") +
##                        scale_y_continuous(breaks = scales::pretty_breaks(10),
##                                           limits = c(0, 1),
##                                           labels = scales::percent,
##                                           expand = c(0.02, 0)) +
##                        coord_flip() +
##                        labs(title = "Median Proportion of 'Cause of Death' in Countries of the Eastern Africa Region",
##                             subtitle = paste0("Year: ", .y), # .y == YEAR!
##                             y = "Proportion of All Deaths", x = "",
##                             caption = "By: Ryo Nakagawara (@R_by_Ryo) \n Source: ourworldindata.org\n#TidyTuesday") +
##                        theme_bw() +
##                        theme(panel.grid.major.y = element_blank(),
##                              text = element_text(family = "Arial Narrow"),
##                              plot.title = element_text(size = 14, hjust = 0.5),
##                              plot.subtitle = element_text(size = 12, hjust = 0.5)
##                        )
##   ))
## 
## glimpse(nested_east_afr)
## 
## #nested_east_afr$plot[5]
## #nested_east_afr$plot[20]
## #nested_east_afr$plot[13]
## #nested_east_afr$plot[1]
## 


## ----eval=FALSE----------------------------------------------------------
## 
## map2(paste0("april_16_week_3/boxplots/", nested_east_afr$year, ".jpg"), nested_east_afr$plot, ggsave)
## 


## ------------------------------------------------------------------------
library(dplyr)
library(readxl)
library(sf)

# read-in data
starbucks_raw <- read_excel("../tidy_tuesday/may_7_week_6/week6_coffee_chains.xlsx", sheet = 1)

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

library(spData) # us_states has pop for each state

states_pop <- us_states %>% 
  select(GEOID, NAME, total_pop_15) %>% 
  filter(!NAME == "District of Columbia") %>% 
  st_set_geometry(NULL)

starbucks_population <- starbucks_sf_norm2 %>% 
  left_join(states_pop, by = "NAME")

starbucks_population <- starbucks_population %>% 
  mutate(pop_norm = (count / total_pop_15 * 100000) %>% ceiling()) # try per 100,000 people?

library(cartogram)
starb_cartogram <- st_transform(starbucks_population, crs = 2163)

starb_sp <- as(starb_cartogram, "Spatial")

# weigh size by state pop
starb_cartogram <- nc_cartogram(starb_sp, weight = "total_pop_15", k = 0.5) 

library(tmap)

# Sequential single hue color palette :: http://colorbrewer2.org/#type=sequential&scheme=Greens&n=5
greenpal <- c('#edf8e9','#bae4b3','#74c476','#31a354','#006d2c')

# legend.reverse for HIGH values on TOP, slight sepia to offset white glare?
# fiddle with margins to fit legend and small title
# plot!
starbucks_cartogram <- tm_shape(starb_cartogram) + 
  tm_borders("grey10") +
  tm_fill(title = "", "pop_norm", 
          palette = greenpal, 
          legend.reverse = TRUE) +
  tm_layout(inner.margins = c(.04,.02, .08, .02),
            main.title = "Number of Starbucks per 100,000 people",
            title = "(Source: https://www.kaggle.com/starbucks/store-locations)\nState size by state population",
            title.position = c("center", "top"), title.size = 0.7,
            fontfamily = "Garamond", fontface = "bold",
            legend.text.size = 0.85, 
            sepia.intensity = 0.1)

starbucks_cartogram

save_tmap(starbucks_cartogram, "starbucks_cartogram_pop_fix.png")


