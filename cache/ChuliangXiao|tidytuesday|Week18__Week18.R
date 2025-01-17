## ----message = F, warning = F--------------------------------------------
library(tidyverse)
library(readxl)
library(ggthemes)


## ----message = F, warning = F--------------------------------------------
raw_df <- read_excel("../data/week18_dallas_animals.xlsx")


## ------------------------------------------------------------------------
dist_df <- raw_df %>% 
  group_by(council_district)


## ----message = F, warning = F, fig.width = 5, fig.height = 6-------------
library(ggrepel)
library(scales)
pie <- raw_df %>% 
  count(animal_type) %>% 
  mutate(perc = percent(n/sum(n))) %>% 
  arrange(desc(n)) %>% 
  filter(animal_type != "LIVESTOCK") %>% 
  ggplot(aes(x = "", y = n, fill = fct_reorder(animal_type, desc(n)))) +
  geom_bar(width = 1, stat = "identity") + 
  coord_polar(theta = "y") +
# https://stackoverflow.com/a/41340766/9421451
  geom_label_repel(aes(label = paste0(animal_type, " ", perc)), 
                   size = 5, show.legend = F, nudge_x = 1) +
  theme_void() +
  theme(legend.position = "bottom") +
  labs(y = NULL,
       fill = "Animal Type")
pie
ggsave("pie.png", pie, dpi = 300)

