## ----message = F, warning = F--------------------------------------------
library(tidyverse)
library(readxl)
library(ggthemes)


## ----message = F, warning = F--------------------------------------------
file16    <- "../data/week16_exercise.xlsx"
excel_sheets(file16)
source_df <- read_xlsx(file16, 1)
tidy_df   <- read_xlsx(file16, 2) %>% mutate(exercise = as.numeric(exercise))


## ----worldmap, message = F, warning = F----------------------------------
#ggplot() + geom_sf(data = world1)
conus    <- rnaturalearth::ne_download(scale = 110,
                                       type = "states",
                                       category = "cultural",
                                       destdir = tempdir(),
                                       load = TRUE,
                                       returnclass = "sf") %>% 
  filter(!postal %in% c("HI", "AK")) %>% 
  select(woe_name, postal, region, region_sub, geometry)


## ------------------------------------------------------------------------
library(albersusa)
usmap <- usa_sf("laea")%>% 
  mutate(st = iso_3166_2) %>% 
  select(name, st, geometry)
work_sf <- inner_join(tidy_df, usmap, by = c("state" = "name")) 


## ----fig.width = 10, fig.height = 15-------------------------------------
library(scico)
library(hrbrthemes)
p <- work_sf %>% 
  filter(sex != "both") %>% 
  ggplot() +
  geom_sf(aes(fill = exercise)) +
# https://github.com/tidyverse/ggplot2/issues/2071
  coord_sf(datum = NA) +  # no graticules
  scale_fill_scico(palette = "vik", na.value = "grey50") +
  facet_grid(work_status ~ sex) +
  theme_ipsum() + 
  theme(axis.title = element_blank(),
        axis.text = element_blank(),
        panel.grid = element_blank(),
        legend.position = "bottom") +
  labs(title = "Adults 18-64 of aerobic and muscle-strengthening",
       caption = "Source: CDC - National Health Statistics Reports"  )+
  NULL
p
ggsave("exercise.png", p, dpi = 300)

