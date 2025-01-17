## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, 
                      message = FALSE, 
                      warning = FALSE, 
                      dpi = 144,
                      fig.align = "center")
remove(list = ls(all.names = TRUE))
detachAllPackages <- function() {
  basic.packages.blank <-  c("stats","graphics","grDevices","utils","datasets","methods","base")
  basic.packages <- paste("package:", basic.packages.blank, sep = "")
  package.list <- search()[ifelse(unlist(gregexpr("package:", search())) == 1,TRUE,FALSE)]
  package.list <- setdiff(package.list, basic.packages)
  if (length(package.list) > 0)  for (package in package.list) {
    detach(package, character.only = TRUE)}}
detachAllPackages()
if (!require(pacman)) {
  install.packages("pacman")
  require(pacman)
}

# devtools::install_github("hrbrmstr/statebins") # Install newest statebins package

p_load(tidyverse, knitr, data.table, lubridate, zoo, hrbrthemes, tidytuesdayR, prophet, forecast, gridExtra, statebins, gganimate, gifski, png, Hmisc, janitor, ggridges, highcharter, viridis)

`%g%` <- function(x,y) {
  z <- paste0(y, collapse = "|")
  grepl(z, x, ignore.case = T)
}

nowt <- function(x = NULL) x


## ------------------------------------------------------------------------
tt_load(2019, week = 31) %>% 
  map(~list2env(.x[1], envir = .GlobalEnv))


## ---- fig.height=5, fig.width=7------------------------------------------
tc <- c("#A5143F", "#E5350F", "#E67F18", "#F5BD0E", "#8BDEFC", "#38BAB6", "#234C68", "#4B3460")

ce <- c("#303030", "#063A9C", "#36A8DC", "#BAE8F3", "#FACB6B", "#FC8D1E", "#F74543", "#7C246C")

video_games %>%
  select(publisher, metascore, owners) %>%
  filter(!is.na(metascore)) %>%
  group_by(publisher) %>%
  mutate(
    total = n(),
    med   = median(metascore)
  ) %>%
  ungroup() %>%
  nest(metascore, owners) %>%
  arrange(med) %>%
  top_n(10, total) %>%
  mutate(publisher = fct_inorder(factor(paste(publisher, total, sep = " - ")))) %>%
  unnest() %>%
  ggplot(aes(x = metascore, y = publisher, fill = publisher)) +
  geom_density_ridges(
    scale = 3,
    size = .01,
    color = "lightgrey",
    show.legend = F,
    rel_min_height = 0.0001,
    alpha = .9
  ) +
  theme_ipsum_rc() +
  theme(plot.title    = element_text(hjust = 9),
        plot.subtitle = element_text(hjust = 16.5)) +
  scale_fill_viridis(direction = 1, discrete = T, option = "D") + 
  labs(
    title = "PC Game Publishers on Steam by Metascore",
    subtitle = "Top 10 by volume with valid Metascore. Total noted by name.",
    caption = "Source: steamspy.com",
    y = "",
    x = "Metacritic Metascore"
  ) -> p

ggsave(p, filename = "tt_31_2019.png", device = "png", dpi = 300, width = 7, height = 5)

p

