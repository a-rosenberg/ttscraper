## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)


## ----echo=FALSE, message=FALSE, warning=FALSE----------------------------
pacman::p_load(tidyverse, polite, scales, ggimage, ggforce, ggtextures, DT, 
               cowplot, rvest, glue, extrafont, ggrepel, magick)
loadfonts()


## ------------------------------------------------------------------------
theme_womenWorldCup <- function(
  title.size = 24,
  subtitle.size = 14,
  caption.size = 8,
  axis.text.size = 14,
  axis.text.x.size = 12,
  axis.text.y.size = 12,
  axis.title.size = 16,
  strip.text.size = 18,
  panel.grid.major.x = element_line(size = 0.5, color = "black"),
  panel.grid.major.y = element_line(size = 0.5, color = "black"),
  panel.grid.minor.x = element_blank(),
  panel.grid.minor.y = element_blank(),
  axis.ticks = element_line(color = "black")) {
  ## Theme:
  theme(text = element_text(family = "Roboto Condensed", color = "white"),
        plot.title = element_text(family = "Roboto Condensed", face = "bold", 
                                  size = title.size, color = "yellow"),
        plot.subtitle = element_text(size = subtitle.size),
        plot.caption = element_text(size = caption.size),
        panel.background = element_rect(fill = "white"), # red green
        plot.background = element_rect(fill = "#002776"),
        axis.text = element_text(size = axis.text.size, color = "white"),
        axis.text.x = element_text(size = axis.text.x.size, color = "white"),
        axis.text.y = element_text(size = axis.text.y.size, color = "white"),
        axis.title = element_text(size = axis.title.size),
        axis.line.x = element_blank(),
        axis.line.y = element_blank(),
        panel.grid.major.x = panel.grid.major.x,
        panel.grid.major.y = panel.grid.major.y,
        panel.grid.minor.x = panel.grid.minor.x,
        panel.grid.minor.y = panel.grid.minor.y,
        strip.text = element_text(color = "yellow", face = "bold", 
                                  size = strip.text.size, 
                                  margin = margin(4.4, 4.4, 4.4, 4.4)),
        strip.background = element_blank(),
        axis.ticks = axis.ticks
        )
}


## ------------------------------------------------------------------------
wwc_outcomes <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-07-09/wwc_outcomes.csv")
squads <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-07-09/squads.csv")
codes <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-07-09/codes.csv")


## ------------------------------------------------------------------------
squads_clean <- squads %>% 
  mutate(caps = if_else(is.na(caps), 0, caps),
         goals = if_else(is.na(goals), 0, goals))


## ---- fig.height = 8, fig.width = 12-------------------------------------
goals_country_plot <- squads_clean %>% 
  filter(pos %in% c("MF", "FW")) %>% 
  group_by(country) %>% 
  mutate(median = median(goals)) %>% 
  ungroup() %>% 
  ggplot(aes(x = goals, y = reorder(country, median))) +
  ggridges::geom_density_ridges(fill = "red", color = "black", scale = 1.1) +
  geom_point(aes(x = median, y = country), position = position_nudge(y = 0.25),
             color = "yellow", size = 3) +
  scale_x_continuous(limits = c(0, 190),
                     expand = c(0.01, 0.01),
                     breaks = seq(0, 190, by = 5),
                     labels = seq(0, 190, by = 5)) +
  expand_limits(y = 27) +
  labs(title = "Distribution of Goals Scored by Midfielders and Strikers",
       subtitle = "Women's World Cup 2019 squads, Yellow dot = Median goals",
       x = "Goals", y = NULL,
       caption = glue::glue("
                            Source: Wikipedia
                            By: @R_by_Ryo")) +
  theme_womenWorldCup(title.size = 18,
                    subtitle.size = 12, 
                    caption.size = 8,
                    axis.text.x.size = 10,
                    axis.text.y.size = 12,
                    axis.title.size = 16,
                    strip.text.size = 18) 

goals_country_labels <- goals_country_plot +
  ggforce::geom_mark_hull(aes(filter = country == "Canada" & goals == 181,
                              label = "Christine Sinclair: 181 goals"),
                          size = 1.25, con.size = 1.25, color = "red",
                          label.buffer = unit(5, "mm"), label.fontsize = 10,
                          label.fill = "red",
                          label.family = "Roboto Condensed", 
                          label.colour = "white", con.colour = "red",
                          con.cap = unit(1, "mm"), con.type = "straight") +
  ggforce::geom_mark_hull(aes(filter = country == "Brazil" & goals == 110,
                              label = "Marta: 110 goals"),
                          color = "darkgreen", size = 1.25,
                          label.buffer = unit(19, "mm"), label.fontsize = 10,
                          label.fill = "darkgreen",
                          label.family = "Roboto Condensed", 
                          label.colour = "white", 
                          con.colour = "darkgreen", con.size = 1.25,
                          con.cap = unit(1, "mm"), con.type = "straight") +
  ggforce::geom_mark_hull(aes(filter = country == "US" & goals == 107,
                              label = "Carli Lloyd: 107 goals"),
                          color = "darkblue", size = 1.25,
                          label.buffer = unit(27, "mm"), label.fontsize = 10,
                          label.fill = "darkblue",
                          label.family = "Roboto Condensed", 
                          label.colour = "white", 
                          con.colour = "darkblue", con.size = 1.25,
                          con.cap = unit(1, "mm"), con.type = "straight") +
  ggforce::geom_mark_hull(aes(filter = country == "Brazil" & goals == 83,
                              label = "Cristiane: 83 goals"),
                          color = "darkgreen", size = 1.25,
                          label.buffer = unit(20, "mm"), label.fontsize = 10,
                          label.fill = "darkgreen",
                          label.family = "Roboto Condensed", 
                          label.colour = "white", 
                          con.colour = "darkgreen", con.size = 1.25, 
                          con.cap = unit(1, "mm"), con.type = "straight") +
  ggforce::geom_mark_hull(aes(filter = country == "US" & goals == 101,
                              label = "Alex Morgan: 101 goals"),
                          color = "darkblue", size = 1.25,
                          label.buffer = unit(2, "mm"), label.fontsize = 10,
                          label.fill = "darkblue",
                          label.family = "Roboto Condensed", 
                          label.colour = "white", 
                          con.colour = "darkblue", con.size = 1.25,
                          con.cap = unit(0.1, "mm"), con.type = "straight")

goals_country_labels +
  annotate(geom = "label", 
           label = glue("
                        Canadian striker Christine Sinclair has scored 71 (!)
                        more national team goals than second highest scorer
                        Marta out of the players at the 2019 World Cup!"),
           x = 140, y = 8, label.padding = unit(0.8, "lines"),
           family = "Roboto Condensed", color = "white",
           fill = "#002776", size = 6)


## ------------------------------------------------------------------------
ggsave(filename = here::here("wwc_goal_dist_plot.png"), 
       height = 8, width = 12)

