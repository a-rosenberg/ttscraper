## ----message = F, warning = F--------------------------------------------
library(tidyverse)
library(maps)
library(sf)
library(ggthemes)
library(patchwork)


## ----message = F, warning = F--------------------------------------------
raw_df    <- read_csv("../data/week14_global_life_expectancy.csv")
# Get non-country rows
cont_code <- raw_df %>% filter(is.na(code)) %>% distinct(country) 


## ----worldmap------------------------------------------------------------
#ggplot() + geom_sf(data = world1)
worldmap <- rnaturalearth::ne_download(scale = 110,
                                       type = "countries",
                                       category = "cultural",
                                       destdir = tempdir(),
                                       load = TRUE,
                                       returnclass = "sf") %>% 
  select(SOVEREIGNT, SOV_A3, ADMIN, ADM0_A3, geometry)



## ------------------------------------------------------------------------
# data countries not in the worldmap
cnty1 <- raw_df %>% 
  filter(!is.na(code)) %>% 
  anti_join(worldmap, by = c("code" = "ADM0_A3")) %>% 
  distinct(country)

# worldmap countries not in the data
cnty2 <- worldmap %>% 
  anti_join(raw_df, by = c("ADM0_A3" = "code")) %>% 
  as_tibble() %>% 
  distinct(ID)

map_df <- raw_df %>% 
  filter(!is.na(code)) %>% 
  left_join(worldmap, by = c("code" = "ADM0_A3"))


## ----life 2015, fig.width = 10, message = F, warning = F-----------------
library(scico)
library(hrbrthemes)
library(glue)
year1 <- 2015
p <- map_df %>% 
  filter(year == year1) %>% 
  ggplot() +
  geom_sf(aes(fill = life_expectancy)) + 
  scale_fill_scico(palette = "vik", na.value = "grey50") +
  labs(title = glue("Life expectancy, {year1}"), 
       subtitle = "Shown in the period of life expectancy at birth. This corresponds to the average estimate a newborn\ninfant would live if prevailing patterns of mortality at the time of birth were to stay the same throughout its life.",
       caption = "Source: Clio-Infra estimates until 1949; UN Population Division from 1950 to 2015",
       fill = "Life\nExpectancy") + 
  theme_ipsum() + 
  theme(plot.title = element_text(size = 18),
        plot.subtitle = element_text(size = 12),
        axis.title = element_blank(),
        axis.text = element_blank(), 
        panel.background = element_rect(fill = "grey95", color = NA), 
        plot.background = element_rect(fill = "grey95", color = NA))
p
ggsave("life2015.png", p, dpi = 300)


## ----Animation, message = F, warning = F---------------------------------
library(animation)
library(gganimate)

g <- map_df %>% 
  filter(year %in% seq(1950, 2015, 5)) %>% 
  ggplot(aes(frame = year)) +
  geom_sf(aes(fill = life_expectancy)) + 
  scale_fill_scico(palette = "vik", na.value = "grey50") +
  labs(title = "Life expectancy,", 
       subtitle = "Shown in the period of life expectancy at birth. This corresponds to the average estimate a newborn\ninfant would live if prevailing patterns of mortality at the time of birth were to stay the same throughout its life.",
       caption = "Source: Clio-Infra estimates until 1949; UN Population Division from 1950 to 2015",
       fill = "Life\nExpectancy") + 
  theme_ipsum() + 
  theme(plot.title = element_text(size = 18),
        plot.subtitle = element_text(size = 12),
        axis.title = element_blank(),
        axis.text = element_blank(), 
        panel.background = element_rect(fill = "grey95", color = NA), 
        plot.background = element_rect(fill = "grey95", color = NA))


animation::ani.options(interval = 1/8)
gganimate(g, "life_expectancy.gif", title_frame = T, ani.width = 1200,ani.height = 800)

