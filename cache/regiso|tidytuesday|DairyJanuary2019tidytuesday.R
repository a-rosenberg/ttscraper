## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)


## ------------------------------------------------------------------------
library(tidyverse)
library(RCurl)    # to load csv from git hub
library(ggthemes) # to get Tufte design
library(cowplot)  # to arrange 4 plots in a 2 x 2 arrangement
library(ggplot2)


x <- getURL("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-01-29/milkcow_facts.csv")
y <- read.csv(text=x)


## ------------------------------------------------------------------------
df1 <- y %>%
  filter(year == 1980 | year == 2014) %>%
  select(year, avg_milk_cow_number, avg_price_milk, milk_production_lbs, milk_per_cow) %>%
  gather(measure, metric, -year) %>%
  mutate(year = gsub(" ", "", paste("AD","", as.character(year)))) %>%
  spread(year, metric) %>%
  mutate(change = (AD2014-AD1980)/AD1980) 

print(df1)



## ------------------------------------------------------------------------
g <- ggplot(y)
p1 <- g +  geom_point(aes(y=avg_milk_cow_number, x=year)) +
  geom_line(aes(y=avg_milk_cow_number, x=year)) +
  theme_tufte() +
  scale_x_continuous() + 
  scale_y_continuous(limits=c(0, 11059000)) +
  ylab("Total # of Milk Cows") + xlab("Year") +
  labs(title    = "The number of milk cows dropped 14%",
       subtitle = "Total Milk Cows in the US, 1980-2014")

# Annual pounds per cow produced
p2 <- g +  geom_point(aes(y=milk_per_cow, x=year)) +
  geom_line(aes(y=milk_per_cow, x=year)) +
  theme_tufte() +
  scale_x_continuous() + 
  scale_y_continuous(limits=c(0, 25000)) +
  ylab("Average Milk in Pounds Per Cow") + xlab("Year")+ 
  labs(title    = "Milk cow productivity grew more than 87%",
       subtitle = "Pounds of Milk Produced / Cow Annually, 1980-2014")

# Annual milk production
p3 <- g +  geom_point(aes(y=milk_production_lbs, x=year)) +
  geom_line(aes(y=milk_production_lbs, x=year)) +
  theme_tufte() +
  scale_x_continuous() + xlab("Year")  + 
  scale_y_continuous(limits=c(0, 2.0e+11)) +
    ylab("Annual Total Milk Production") +
  labs(title    = "Overall milk production grew more than 60%",
       subtitle = "Total Pounds of Milk Produced, 1980-2014",
       caption  = "Source: USDA, github.com/rfordatascience/tidytuesday/tree/master/data/2019/2019-01-29") + 
  theme(plot.caption=element_text(hjust=.1))

# How has the price of milk changed
p4 <- g +  geom_point(aes(year,avg_price_milk)) +
  geom_line(aes(year,avg_price_milk)) +
  theme_tufte() +
  scale_x_continuous() + xlab("Year")  + 
  scale_y_continuous(limits=c(0, .25)) +
  ylab("Average Price for Milk") +
  labs(title    = "Meanwhile, the price of milk grew nearly 
       85%",
       subtitle = "$ / pound of Milk, 1980-2014",
       caption = "JANUARY 2019 | @REGISOCONNOR") +
  theme(plot.caption=element_text(hjust=1))

 plot_grid(p1, p2, p3, p4)

