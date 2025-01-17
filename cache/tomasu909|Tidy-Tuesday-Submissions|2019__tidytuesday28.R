## ----setup, include=FALSE------------------------------------------------
options(repos='http://cran.rstudio.com/')
knitr::opts_chunk$set(echo = FALSE, message = FALSE, warning = FALSE)
remove(list = ls(all.names = TRUE))
detachAllPackages <- function() {
  basic.packages.blank <- c(
    "stats",
    "graphics",
    "grDevices",
    "utils",
    "datasets",
    "methods",
    "base"
  )
  basic.packages <- paste("package:", basic.packages.blank, sep = "")
  package.list <- search()[ifelse(unlist(gregexpr("package:", search())) == 1, TRUE, FALSE)]
  package.list <- setdiff(package.list, basic.packages)
  if (length(package.list) > 0) {
    for (package in package.list) {
      detach(package, character.only = TRUE)
    }
  }
}
detachAllPackages()
if (!require(pacman)) {
  install.packages("pacman")
  require(pacman)
}

`%g%` <- function(x,y) {
  z <- paste0(y, collapse = "|")
  grepl(z, x, ignore.case = T)
}

nowt <- function(x = NULL) x

extrafont::loadfonts(quiet = T)

tc <- c("#A5143F", "#E5350F", "#E67F18", "#F5BD0E", "#8BDEFC", "#38BAB6", "#234C68", "#4B3460")

p_load(janitor, tidyverse, hrbrthemes, scales, carbonate)


## ------------------------------------------------------------------------
wwc_outcomes <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-07-09/wwc_outcomes.csv")
squads <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-07-09/squads.csv")
codes <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-07-09/codes.csv")


## ------------------------------------------------------------------------
goal_diff <- wwc_outcomes %>% 
  filter(win_status != "Tie") %>% 
  nest(-year, -yearly_game_id) %>% 
  mutate(data = map(data, ~.x %>% 
                      mutate(team = paste(team, score, sep = "_")) %>% 
                      select(team, round, win_status) %>% 
                      spread(win_status, team))) %>% 
  unnest() %>% 
  separate(Won, c("W_T", "W_S"), "_") %>% 
  separate(Lost, c("L_T", "L_S"), "_") %>% 
  transmute(Game = paste(W_T, " vs ", L_T, " (", year, ")", sep = ""),
            Diff = as.numeric(W_S) - as.numeric(L_S),
            Score = paste(W_S, L_S, sep = " - "),
            Round = round) %>% 
  arrange(desc(Diff))


## ------------------------------------------------------------------------
goal_diff %>% 
  head(10) %>% 
  ggplot(aes(reorder(Game, Diff), Diff, fill = Round)) + 
  geom_bar(stat = "identity") +
  theme_ipsum_rc(plot_title_size = 20) +
  geom_text(aes(label = Score),
    colour = "white", 
    nudge_y = -.5, 
    nudge_x = .02, 
    fontface = "bold",
    size = 3
  ) +
  coord_flip() +
  scale_fill_manual(values = c("#234C68", "#E5350F")) +
  labs(
    title = "	Women's World Cup: Biggest Blowouts",
    subtitle = "Top 10 Games With the Largest Goal Differential",
    caption = "Source: https://data.world/sportsvizsunday/womens-world-cup-data",
    x = "",
    y = "Goal Differential"
  ) +
  nowt() -> wwc_tt28

ggsave(
  wwc_tt28, 
  filename = "wwc_tt28.png", 
  device = "png", dpi = 200, 
  width = 10, height = 5.625, 
  units = "in"
  )

