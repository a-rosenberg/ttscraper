## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)


## ------------------------------------------------------------------------
# pacman::p_load()
library(rvest)
library(polite)
library(dplyr)
library(tidyr)
library(ggplot2)
library(scales)
library(purrr)
library(stringr)
library(ggrepel)
library(glue)
library(extrafont)
loadfonts(quiet = TRUE)


## ------------------------------------------------------------------------
session <- bow("https://www.transfermarkt.com/liverpool-fc/leistungsdaten/verein/31/reldata/GB1%262018/plus/1")

print(session)
# "The path is scrapable for this user-agent": OK, looks like we are good to go!

# grab name from photo element instead
result_name <- scrape(session) %>% 
  html_nodes("#yw1 .bilderrahmen-fixed") %>% 
  html_attr("title") 

# grab age
result_age <- scrape(session) %>% 
  html_nodes(".posrela+ .zentriert") %>% 
  html_text()

# grab minutes played in league
result_mins <- scrape(session) %>% 
  html_nodes("td.rechts") %>% 
  html_text()



## ------------------------------------------------------------------------
# place each vector into list

resultados <- list(result_name, result_age, result_mins)

col_name <- c("name", "age", "minutes")

# then reduce(cbind) to combine them, set names to cols 
results_comb <- resultados %>% 
  reduce(cbind) %>% 
  as_tibble() %>% 
  set_names(col_name)

# NOICE.gif
glimpse(results_comb)


## ------------------------------------------------------------------------
wiki_url <- "https://en.wikipedia.org/wiki/2019–20_Liverpool_F.C._season"

wiki_session <- bow(wiki_url)

wiki_age <- scrape(wiki_session) %>% 
  html_nodes("table.wikitable:nth-child(6)") %>% 
  html_table(fill = TRUE) %>% 
  flatten_df()





## ------------------------------------------------------------------------
age_plus_one <- c("Lovren", "Van Dijk", "Moreno", "Ings")

# fix "strings" into proper formats, calculate % of minutes appeared
lfc_minutes <- results_comb %>% 
  
  mutate(age = as.numeric(age),
         minutes = minutes %>% 
           str_replace("\\.", "") %>% 
           str_replace("'", "") %>% 
           as.numeric(),
         min_perc = (minutes / 3420) %>% round(digits = 3)) %>% 
  
  filter(!is.na(minutes)) %>% 
  
  separate(name, into = c("first_name", "last_name"), sep = " ") %>% 
  
  # manually fix some names
  mutate(
    last_name = case_when(                        
      first_name == "Trent" ~ "Alexander-Arnold",   
      first_name == "Virgil" ~ "Van Dijk",
      first_name == "Alex" ~ "Oxlade-Chamberlain",
      TRUE ~ last_name),
    age = age + 1) %>%    # do CURRENT age instead for plot 2.0
  
  mutate(
    age = case_when(
      last_name %in% age_plus_one ~ age + 1,
      TRUE ~ age)
    ) %>% 
  arrange(desc(min_perc))

# rectanglular highlight for players in their prime:
rect_df <- data.frame(
  xmin = 25, xmax = 30,
  ymin = -Inf, ymax = Inf
)


## ----fig.height=6, fig.width=8-------------------------------------------
lfc_minutes %>% 
  ggplot(aes(x = age, y = min_perc)) +
  geom_rect(
    data = rect_df, inherit.aes = FALSE,
    aes(xmin = xmin, xmax = xmax, 
        ymin = ymin, ymax = ymax),
    alpha = 0.3,
    fill = "firebrick1") +
  geom_point(color = "red", size = 2.5) +
  geom_text_repel(
    aes(label = last_name, family = "Roboto Condensed"),
    nudge_x = 0.5,
    seed = 6) + 
  scale_y_continuous(
    expand = c(0.01, 0),
    limits = c(0, 1), 
    labels = percent_format()) +
  scale_x_continuous(
    breaks = pretty_breaks(n = 10)) +
  labs(
    x = "Current Age (As of Aug. --th, 2019)", y = "% of Minutes Played", 
    title = "Liverpool FC: Age-Utility Matrix",
    subtitle = "Premier League 18/19 (Summer 2019 transfers in bold, departed players left in for comparison)",
    caption = glue::glue("
                         Data: transfermarkt.com
                         By: @R_by_Ryo")) +
  theme_bw() +
  theme(
    text = element_text(family = "Roboto Condensed"),
    panel.grid.minor.y = element_blank()) +
  geom_label(
    aes(x = 20.5, y = 0.87, 
        hjust = 0.5, 
        label = glue("
          Encouraging to see Liverpool buying players both in 
          their prime and regulars in their previous teams. 
          Our entire best 'Starting XI' are going to be 
          in their prime this season!
          "), 
        family = "Roboto Condensed"),
    size = 3.5)


