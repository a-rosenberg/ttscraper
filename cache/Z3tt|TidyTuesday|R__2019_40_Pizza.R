## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, warning = F)


## ----prep, message=FALSE, warning=FALSE----------------------------------
## packages
library(tidyverse)
library(ggtext)
library(extrafont)
library(emo)

extrafont::loadfonts(device = "win", quiet = TRUE)

theme_update(plot.title = element_text(size = 25))


## ----data----------------------------------------------------------------
df_pizza_jared <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-10-01/pizza_jared.csv")
df_pizza_barstool <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-10-01/pizza_barstool.csv")
#df_pizza_datafiniti <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-10-01/pizza_datafiniti.csv")


## ----plot-jared, fig.width = 7, fig.height = 16--------------------------
df_pizza_jared %>% 
  filter(total_votes > 0) %>% 
  mutate(answer = case_when(
    answer == "Never Again" ~ 0, 
    answer == "Poor" ~ 1, 
    answer == "Average" ~ 2, 
    answer == "Fair" ~ 3, 
    answer == "Good" ~ 4, 
    answer == "Excellent" ~ 5
  ),
  score = answer * votes
  ) %>% 
  group_by(polla_qid) %>% 
  summarize(
    place = unique(place),
    score = sum(score),
    total_votes = unique(total_votes)
  ) %>% 
  group_by(place) %>% 
  summarize(eaten = sum(score) / sum(total_votes)) %>% 
  mutate(
    leftover = 5 - eaten,
    place = gsub('(.{1,15})(\\s|$)', '\\1\n', place),
    place = substr(place, 1, nchar(place) - 1)
  ) %>% 
  ungroup() %>% 
  mutate(place = fct_reorder(place, -eaten)) %>%
  gather(var, val, -place) %>% 
  ggplot(aes(x = 1, y = val)) + 
    geom_col(aes(fill = var), width = 1) + 
    coord_polar(theta = "y") + 
    facet_wrap(~ place, ncol = 5) +
    scale_fill_manual(values = c("#dacab9", "#ffdb88"), guide = F) +
    theme_void() +
    labs(x = NULL, y = NULL, 
         title = paste("<span style='font-size:21pt'>Where to Eat Pizza in NYC</span><span style='font-size:25pt'>", emo::ji("pizza"), "</span><br><span style='font-size:12pt'>(Jared Edition)</span>"),
         subtitle = "<span style='color:#848484'>Pizza ratings by Jared & friends at the R Meetups in New York City.</span><br><br>The <span style='color:#d3c0ac'>grey plates</span> indicate the average score of restaurants,<br>the <span style='color:#ffd574'>pizza leftovers</span> the difference from the highest score possible.",
         caption = "\n\n\nVisualization by Cédric Scherer") +
    theme(strip.text = element_text(family = "Roboto Condensed", 
                                    face = "bold"),
          plot.title = element_markdown(family = "Ultra", 
                                        face = "plain",
                                        hjust = 0.5,
                                        margin = margin(b = 12)),
          plot.subtitle = element_markdown(family = "Ultra", 
                                           face = "plain",
                                           size = 9,
                                           color = "grey80",
                                           lineheight = 1.3,
                                           hjust = 0.5,
                                           margin = margin(b = 25)),
          plot.caption = element_text(family = "Ultra", 
                                      color = "#d3c0ac", 
                                      size = 7,
                                      hjust = 0.5),
          panel.spacing.x = unit(20, "pt"),
          panel.spacing.y = unit(10, "pt"),
          plot.margin = margin(30, 30, 30, 30))
  
ggsave(here::here("plots", "2019_40", "2019_40_Pizza_jared.png"),
       width = 7, height = 16, dpi = 600)


## ----plot-barstool, fig.width = 9, fig.height = 50-----------------------
theme_update(plot.title = element_text(size = 30))

df_pizza_barstool %>% 
  filter(city == "New York") %>% 
  group_by(name) %>% 
  summarize(eaten = mean(review_stats_all_average_score)) %>% 
  mutate(
    leftover = 10 - eaten,
    name = gsub('(.{1,15})(\\s|$)', '\\1\n', name),
    name = substr(name, 1, nchar(name) - 1)
  ) %>% 
  ungroup() %>% 
  mutate(name = fct_reorder(name, -eaten)) %>%
  gather(var, val, -name) %>% 
  ggplot(aes(x = 1, y = val)) + 
    geom_col(aes(fill = var), width = 1) + 
    coord_polar(theta = "y") + 
    facet_wrap(~ name, ncol = 7) +
    scale_fill_manual(values = c("#dacab9", "#ffdb88"), guide = F) +
    theme_void() +
    labs(x = NULL, y = NULL, 
         title = paste("<span style='font-size:28pt'>Where to Eat Pizza in NYC</span><span style='font-size:25pt'>", emo::ji("pizza"), "</span><br><span style='font-size:14pt'>(Barstool Sports Edition)</span>"),
         subtitle = "<span style='color:#848484'>Average ratings on Barstool Sports for pizzerias in New York City.</span><br><br>The <span style='color:#d3c0ac'>grey plates</span> indicate the score of listed restaurants,<br>the <span style='color:#ffd574'>pizza leftovers</span> the difference from the highest score possible (10).",
         caption = "\n\nVisualization by Cédric Scherer") +
    theme(strip.text = element_text(family = "Roboto Condensed", 
                                    face = "bold"),
          plot.title = element_markdown(family = "Ultra", 
                                        face = "plain",
                                        hjust = 0.5,
                                        margin = margin(b = 12)),
          plot.subtitle = element_markdown(family = "Ultra", 
                                           face = "plain",
                                           size = 11,
                                           color = "grey80",
                                           lineheight = 1.3,
                                           hjust = 0.5,
                                           margin = margin(b = 25)),
          plot.caption = element_text(family = "Ultra", 
                                      color = "#d3c0ac", 
                                      size = 9,
                                      hjust = 0.5),
          panel.spacing.x = unit(20, "pt"),
          panel.spacing.y = unit(10, "pt"),
          plot.margin = margin(25, 30, 25, 30))

ggsave(here::here("plots", "2019_40", "2019_40_Pizza_barstool.png"),
       width = 9, height = 50, dpi = 350, limitsize = F)


## ------------------------------------------------------------------------
sessionInfo()

