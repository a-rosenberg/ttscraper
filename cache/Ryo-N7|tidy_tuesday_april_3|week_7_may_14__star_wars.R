## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)


## ------------------------------------------------------------------------
library(tidyverse)

star_wars_raw <- read_csv("../week_7_may_14/StarWars.csv")




## ------------------------------------------------------------------------
glimpse(star_wars_raw)

star_wars_raw %>% janitor::clean_names() %>% trimws() %>% glimpse()

star_wars_unite <- star_wars_raw %>% 
  unite("movies_watched", 
        c(`Which of the following Star Wars films have you seen? Please select all that apply.`, 
          "X5", "X6", "X7", "X8", "X9"), sep = ", ") %>% 
  unite("preference_rank",
        c(`Please rank the Star Wars films in order of preference with 1 being your favorite film in the franchise and 6 being your least favorite film.`,
          "X11", "X12", "X13", "X14", "X15"), sep = ", ") %>% glimpse()

star_wars_unite <- star_wars_unite %>% 
  mutate(movies_watched = movies_watched %>% as.list(),
         preference_rank = preference_rank %>% as.list()) %>% 
  glimpse()

star_wars_unite %>% select(movies_watched)

# ignore favorable - unfavorable Qs >>> filter them out into separate df?



## ------------------------------------------------------------------------
star_wars_unite2 <- star_wars_unite %>% 
  slice(-1) %>% 
  filter(`Do you consider yourself to be a fan of the Star Wars film franchise?` != "NA") %>% 
  filter(`Which character shot first?` != "I don't understand this question")

  star_wars_unite$`Do you consider yourself to be a fan of the Star Wars film franchise?` %>% unique()
  #mutate_all(funs(iconv(., from = "UTF-8", to = "ASCII//TRANSLIT")))


## ------------------------------------------------------------------------
star_wars_unite2 %>% 
  transmute(
    under30 = star_wars_unite2$Age == "18-29",
    over60 = star_wars_unite2$Age == "> 60",
    male = star_wars_unite2$Gender == "Male",
    female = star_wars_unite2$Gender == "Female",
    west_coast = star_wars_unite2$`Location (Census Region)` %in% c("Pacific", "Mountain")
  ) %>% 
  map(function(x) {
    out <- table(shoot = star_wars_unite2$`Do you consider yourself to be a fan of the Star Wars film franchise?`, blah = x) %>% 
      fisher.test(conf.level = 0.6785)
    out <- c(out$estimate, lower = out$conf.int[1], upper = out$conf.int[2])
    return(out)
  }) %>% 
  as.data.frame() %>% 
  rownames_to_column() %>% 
  gather(key, value, -rowname) %>% 
  spread(rowname, value) %>% 
  ggplot(aes(y = key, x = `odds ratio`))+ 
  geom_errorbarh(aes(xmin = lower, xmax = upper), size = .45, color = "#899DA4", height = 0.75) + 
  geom_point(size = 4, color = "#DC863B") +
  geom_vline(xintercept = 1, lty = 2, lwd = 1, color = "#C93312") + 
  scale_x_continuous(
    sec.axis = sec_axis(~ ., 
                        breaks = c(0.65, 1.5), 
                        labels = c("less likely\nto be a fan of Star Wars", 
                                   "more likely\nto be a fan of Star Wars"))
    )


## ------------------------------------------------------------------------
star_wars_unite2 %>% 
  transmute(
    under30 = star_wars_unite2$Age == "18-29",
    over60 = star_wars_unite2$Age == "> 60",
    male = star_wars_unite2$Gender == "Male",
    female = star_wars_unite2$Gender == "Female",
    west_coast = star_wars_unite2$`Location (Census Region)` %in% c("Pacific", "Mountain")
  ) %>% 
  map(function(x) {
    out <- table(shoot = star_wars_unite2$`Which character shot first?`, blah = x) %>% 
      fisher.test(conf.level = 0.95)
    out <- c(out$estimate, lower = out$conf.int[1], upper = out$conf.int[2])
    return(out)
  }) %>% 
  as.data.frame() %>% 
  rownames_to_column() %>% 
  gather(key, value, -rowname) %>% 
  spread(rowname, value) %>% 
  ggplot(aes(y = key, x = `odds ratio`))+ 
  geom_errorbarh(aes(xmin = lower, xmax = upper), size = .45, color = "#899DA4", height = 0.75) + 
  geom_point(size = 4, color = "#DC863B") +
  geom_vline(xintercept = 1, lty = 2, lwd = 1, color = "#C93312") + 
  scale_x_continuous(
    sec.axis = sec_axis(~ ., 
                        breaks = c(0.65, 1.8), 
                        labels = c("less likely\nto say 'Greedo shot first!'", 
                                   "more likely\nto say 'Greedo shot first!'"))
    )



## ---- warning=FALSE, message=FALSE---------------------------------------
pacman::p_load(tidyverse, scales, ggforce, extrafont)
loadfonts()


## ------------------------------------------------------------------------
starwars_char <- dplyr::starwars

glimpse(starwars_char)


## ------------------------------------------------------------------------
starwars_char %>% 
  #filter(species %in% c("Human", "Ewok")) %>% 
  #select(name, height, mass, species) %>% 
  ggplot(aes(birth_year, height, color = species)) +
  geom_point() +
  geom_mark_ellipse(aes(filter = species == "Yoda's species", 
                        label = "Do i look so old to young eyes")) +
  theme_minimal()


## ------------------------------------------------------------------------
starwars_char %>% 
  filter(species %in% c("Human", "Ewok")) %>% 
  select(name, height, mass, species) %>% 
  ggplot(aes(mass, height, color = species)) +
  geom_point() +
  geom_mark_ellipse(aes(filter = species == "Ewok", label = "Ewok")) +
  theme_minimal()

