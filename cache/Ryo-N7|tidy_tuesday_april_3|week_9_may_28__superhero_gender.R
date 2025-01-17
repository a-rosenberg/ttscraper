## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)


## ------------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)


superhero <- read.csv("../may_28_week9/week9_comic_characters.csv")

glimpse(superhero)

ggplot(superhero, aes(year)) +
  geom_bar(aes(fill = sex))

superhero %>% 
  group_by(year, publisher) %>% 
  mutate(hero_n = n()) %>% 
  ggplot(aes(x = year, y = hero_n, fill = publisher, color = publisher)) +
  geom_col() +
  facet_wrap(~publisher) +
  scale_y_continuous(breaks = scales::pretty_breaks(), expand = c(0, 0)) +
  scale_x_continuous(breaks = scales::pretty_breaks(), expand = c(0.01, 0)) +
  scale_color_brewer(palette = "Set1")

  


## ------------------------------------------------------------------------

female_pct <- superhero %>% 
  group_by(publisher, year) %>% 
  mutate(new_hero = n()) %>% # total new hero appearance in a certain year for certain publisher
  group_by(publisher, year, sex) %>% 
  mutate(gender_n = n(),
         gender_perc = gender_n / new_hero) %>% 
  ungroup() %>% 
  filter(sex == "Female Characters")


female_pct %>% 
  ggplot(aes(x = year, y = gender_perc * 100, 
             group = publisher, color = publisher)) +
  geom_line(size = 1.2) +
  scale_x_continuous(limits = c(1980, 2013))





## ------------------------------------------------------------------------

superhero %>% glimpse()

superhero %>% 
  mutate(align = as.character(align)) %>% 
  mutate(alignment = case_when(
    align == "Good Characters" ~ align,
    align == "Bad Characters" ~ align,
    TRUE ~ "Neutral Characters"
  )) %>% 
  group_by(publisher, sex, alignment) %>% 
  summarise(align_count = n())

superhero



