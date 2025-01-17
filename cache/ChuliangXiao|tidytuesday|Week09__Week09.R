## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)


## ----library, message = F, warning = F-----------------------------------
library(tidyverse)
library(Hmisc)
library(ggthemes)


## ----read data, message = F, warning = F---------------------------------
df_raw  <- read_csv("../data/week9_comic_characters.csv")


## ----fig.width = 10------------------------------------------------------
publisher_name = c("DC, New Earth continuity", 
                   "Marvel, Earth-616 continuity")
p1 <- df_raw %>% 
  group_by(publisher, year) %>% 
  summarise(count = n()) %>% 
  ungroup() %>% 
  mutate(publisher = factor(publisher, labels = publisher_name))%>% 
  ggplot(aes(x = year, y = count, fill = publisher)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = c("blue", "red"))+
  scale_y_continuous(labels = seq(0,500,100),
                     breaks = seq(0,500,100)) +
  scale_x_continuous(labels = c(1940, "'60", "'80", 2000),
                     breaks = seq(1940,2000,20)) + 
#  ggtitle("New Comic Book Characters Introduced Per Year")+
  labs(title = "New Comic Book Characters Introduced Per Year",
       caption = "Source: FiveThirtyEight")+
  facet_wrap(~ publisher) +
  theme_fivethirtyeight() +
  theme(strip.text.x = element_text(size = 15))+
  theme(legend.position = "none") 
p1


## ----fig.width = 10------------------------------------------------------
p2 <- df_raw %>% 
  mutate(sex = str_replace(sex, " Characters", ""))%>% 
  count(publisher, year, sex) %>% 
  group_by(publisher, year) %>% 
  mutate(total = sum(n)) %>%
  mutate(ratio = n / total * 100) %>% 
  filter(sex == "Female") %>% 
  ggplot(aes(x = year, y = ratio, group = publisher, color = publisher)) +
  geom_line() +
  geom_text(aes(x = 2002, y = 25, label = "Marvel"), 
            color = "red", size = 5) + 
  geom_text(aes(x = 2001, y = 44, label = "DC"), 
            color = "blue", size = 5) + 
  scale_x_continuous(limits = c(1980, 2013),
                     labels = c(1980, "'90", 2000, "'10")) + 
  scale_y_continuous(labels = c(seq(0,40,10), "50%"),
                     breaks = seq(0,50,10),
                     limits = c(0,50)) + 
  scale_color_manual(values = c("blue", "red")) +
  labs(title = "Comics Aren't Gaining Many Female Characters",
       subtitle = "Percentage of new characters who are female",
       caption = "Source: FiveThirtyEight") +
  theme_fivethirtyeight() +
  theme(legend.position = "none") 
p2


## ----fig.width = 10------------------------------------------------------
p3 <- df_raw %>% 
  mutate(sex = str_replace(sex, " Characters", ""))%>% 
  filter(sex %in% c("Male", "Female")) %>% 
  count(publisher, year, sex) %>% 
  group_by(publisher, year) %>% 
  mutate(total = sum(n)) %>%
  filter(sex == "Female") %>% 
  group_by(publisher) %>% 
  mutate(cum_hero = cumsum(total),
         cum_female = cumsum(n),
         ratio = cum_female/cum_hero * 100) %>% 
  ggplot(aes(x = year, y = ratio, group = publisher, color = publisher)) + 
  geom_line() + 
  geom_text(aes(x = 1992, y = 15, label = "Marvel"),
            color = "red", size = 5) + 
  geom_text(aes(x = 1990, y = 30, label = "DC"), 
            color = "blue", size = 5) +
  scale_y_continuous(limits = c(0,50),
                     labels = c(seq(0,40,10), "50%")) + 
  scale_x_continuous(limits = c(1939, 2013),
                     labels = c(1940, glue::glue("'{seq(50,90,10)}"), 2010, "'10"),
                     breaks = seq(1940,2010, 10)) + 
  scale_color_manual(values = c("blue", "red")) +
  labs(title = "The Gender Ratio In Comic Books Is Improving",
       subtitle = "Percentage of total characters in universe who are female",
       caption = "Source: FiveThirtyEight") + 
  guides(color = FALSE) + 
  theme_fivethirtyeight() 
p3


## ----fig.width = 10, fig.height = 4--------------------------------------
describe(df_raw$align)
# Credit to https://twitter.com/dylanjm_ds/status/1001688440524673024
df_align <- df_raw %>% 
  mutate(sex = str_replace(sex, " Characters", ""),
         align = str_replace(align, " Characters", ""),
         align = if_else(is.na(align), "Neutral", align)) %>% 
  filter(align != "Reformed Criminals") %>%
  filter(sex %in% c("Female", "Male")) %>% 
  group_by(publisher, sex, align) %>% 
  summarise(count = n()) %>% 
  group_by(publisher, sex) %>% 
  mutate(total = sum(count),
         ratio = count/total * 100,
         align = fct_relevel(align, c("Bad", "Neutral", "Good"))) %>% 
  filter(sex %in% c("Female", "Male")) %>% 
# Mannually set the ration label
  ungroup() %>% 
  mutate(rlab0 = round(ratio),
         rlab1 = if_else(publisher == "DC" & sex == "Female",
                           paste0(rlab0, "%"),
                           as.character(rlab0)),
         r1 = if_else(align == "Good",
                      rlab1,
                      as.character(NA)),
         r2 = if_else(align == "Neutral",
                      rlab1,
                      as.character(NA)),
         r3 = if_else(align == "Bad",
                      rlab1,
                      as.character(NA))) 

p4 <- df_align %>% 
  ggplot(aes(x = fct_relevel(sex, c("Male", "Female")), y = ratio, fill = align)) + 
  geom_bar(stat = "identity", width = 0.8, position = position_stack()) + 
  geom_text(aes(y = 1, label = r1), color = "white", hjust = 0) + 
  geom_text(aes(label = r2), color = "white", position = position_stack(vjust = 0.5)) +
  geom_text(aes(y = 99, label = r3), color = "white", hjust = 1) +
  scale_fill_manual(values = c("#fc2a1c", "#f5b92b", "#78a949")) + 
  scale_x_discrete(labels = c("Male", "Female")) + 
  coord_flip() + 
  facet_wrap(~ publisher, ncol = 1) + 
  labs(title = "Good Girls Gone Meh",
       subtitle = "Character alignment by gender",
       caption = "Source: FiveThirtyEight") + 
  guides(fill = FALSE) + 
  theme_fivethirtyeight() + 
# Left-adjust title 
# https://stackoverflow.com/a/47621310/9421451
  theme(plot.title = element_text(hjust = -0.09),
        plot.subtitle = element_text(hjust = -0.08),
        strip.text.x = element_text(size = 15, hjust = 0),   
        # When hjust Cannot be negative for the trip.text
        panel.grid = element_blank(), 
        axis.text.x = element_blank())
p4 +
  annotate(geom = "text", x = 3, y = 0,   label = c("Good", NA),    
           color = "#78a949", vjust = 0.85, hjust = 0)+
  annotate(geom = "text", x = 3, y = 58,  label = c("Neutral", NA), 
           color = "#f5b92b", vjust = 0.85, hjust = 0.5)+
  annotate(geom = "text", x = 3, y = 100, label = c("Bad", NA),     
           color = "#fc2a1c", vjust = 0.85, hjust = 1)

