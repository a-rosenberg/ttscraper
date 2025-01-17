## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, message = FALSE, warning = FALSE)


## ----getdat--------------------------------------------------------------
library(tidyverse)
jobs_gender <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-03-05/jobs_gender.csv")
earnings_female <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-03-05/earnings_female.csv") 
employed_gender <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-03-05/employed_gender.csv") 


## ----jobs----------------------------------------------------------------
head(jobs_gender)
head(earnings_female)


## ----earningsfemale------------------------------------------------------
earnings_female %>% mutate(total = str_detect(group, "Total")) %>% 
ggplot() + 
  geom_line(aes(x = Year, y = percent, group = group, color = group)) + 
  scale_color_brewer(palette = "Reds") + 
  facet_grid(total ~ ., space = "free", scales = "free_y")


## ----jobsgender----------------------------------------------------------
head(jobs_gender)
jobs_gender %>% 
  ggplot() + 
  geom_line(aes(x = year, y=  percent_female, group =occupation, color = major_category))

