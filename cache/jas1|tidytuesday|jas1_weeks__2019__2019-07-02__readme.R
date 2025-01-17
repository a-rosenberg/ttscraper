## ----echo=FALSE,message=FALSE,warning=FALSE------------------------------
library(magrittr) # para el %T>%
library(tidyverse)
# library(sf)
library(dplyr)
library(stringr)#;
library(rebus)#; install.packages('rebus')
library(tidytext)

# install.packages("Rcpp")
# remotes::install_github("tylermorganwall/rayshader")
library(rayshader)




## ----echo=FALSE,message=FALSE,warning=FALSE------------------------------
media_franchises <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-07-02/media_franchises.csv")


## ----echo=FALSE,message=FALSE,warning=FALSE------------------------------
media_franchises %>% head()



## ----echo=FALSE,message=FALSE,warning=FALSE------------------------------
glimpse(media_franchises)



## ----echo=FALSE,message=FALSE,warning=FALSE------------------------------
media_franchises %>% skimr::skim()



## ----echo=FALSE,message=FALSE,warning=FALSE------------------------------
media_franchises %>% 
    count(creators,owners) %>%
    mutate(creators=fct_reorder(creators,n)) %>% 
    ggplot(aes(x=creators,y=n,fill=owners))+
    geom_col()+
    coord_flip()+
    theme(legend.position = "none")

media_franchises %>% 
    count(owners) %>%
    mutate(creators=fct_reorder(owners,n)) %>% 
    ggplot(aes(x=owners,y=n,fill=owners))+
    geom_col()+
    coord_flip()+
    theme(legend.position = "none")

media_franchises %>% 
    mutate(year_origin=lubridate::ymd(paste0(year_created,"-01-01"))) %>%
    mutate(year_now=lubridate::ymd(paste0(lubridate::year(lubridate::today()),"-01-01"))) %>% 
    mutate(years_elapsed=lubridate::year(year_now)-lubridate::year(year_origin)) %>% 
    mutate(revenue_years=revenue/years_elapsed*1000) %>% 
    ggplot(aes(x=years_elapsed,
               y=revenue,color=revenue_category))+
    geom_point()

media_franchises %>% 
    mutate(year_origin=lubridate::ymd(paste0(year_created,"-01-01"))) %>%
    mutate(year_now=lubridate::ymd(paste0(lubridate::year(lubridate::today()),"-01-01"))) %>% 
    mutate(years_elapsed=lubridate::year(year_now)-lubridate::year(year_origin)) %>% 
    mutate(revenue_years=revenue/years_elapsed*1000) %>% 
    ggplot(aes(x=years_elapsed,
               y=revenue_years,color=revenue_category))+
    geom_point()


## ----echo=FALSE,message=FALSE,warning=FALSE------------------------------



data_processed <- media_franchises %>% 
    group_by(franchise) %>% 
    summarise(year_created_min=min(year_created),total_revenue=sum(revenue)) %>% 
    mutate(year_origin=lubridate::ymd(paste0(year_created_min,"-01-01"))) %>%
    mutate(year_now=lubridate::ymd(paste0(lubridate::year(lubridate::today()),"-01-01"))) %>% 
    mutate(years_elapsed=lubridate::year(year_now)-lubridate::year(year_origin)) %>% 
    mutate(revenue_years=total_revenue/years_elapsed*1000) %>% 
    mutate(franchise=fct_reorder(franchise,years_elapsed))


## ----echo=FALSE,message=FALSE,warning=FALSE------------------------------
background_diff <- "#bad8df"

plot_out <- data_processed %>%            
    ggplot(aes(x=year_now-(years_elapsed/2),
               y=franchise,
               color=franchise))+
    # geom_col()+
    geom_errorbarh(aes(xmin = year_origin, 
                       xmax = year_now), 
                  size = .5, alpha = 0.8)+
    scale_x_date(date_breaks = "5 years",date_labels = "%Y")+
    # coord_flip()+
    theme_light()+
    theme(legend.position = "none",
          axis.text.x = element_text(angle=90))+
    labs(title="Which Franchises are longer living?",
         x="",y="",caption="#tidytuesday")+
    
    geom_vline(xintercept = lubridate::ymd(c("1920-01-01",
                                             "1930-01-01",
                                             "1940-01-01",
                                             "1950-01-01",
                                             "1960-01-01",
                                             "1970-01-01",
                                             "1980-01-01",
                                             "1990-01-01",
                                             "2000-01-01",
                                             "2010-01-01",
                                             "2020-01-01")),
               linetype='dashed')+ 
  # Expand y axis scale so that the legend can fit
  scale_y_discrete(
    expand = expand_scale(add=c(0.65,1))
  )     +
    
# rectangle with years.
    geom_rect(
    mapping = aes(xmin = lubridate::ymd("2022-01-01"), xmax = lubridate::ymd("2026-01-01") , 
                  ymin = -Inf, ymax = Inf),
    fill = "white",
    color = "white"
  ) +
  # Add rectangle with correct banground color for the differences
  geom_rect(
    mapping = aes(xmin = lubridate::ymd("2022-01-01"), xmax = lubridate::ymd("2026-01-01") , 
                  ymin = -Inf, ymax = Inf),
    fill = background_diff,
    color = background_diff
  ) +
  # Add Differences values
  geom_text(
    # Bold face
    fontface = "bold",
    # Font size
    size = 4,
    # Font Color
    colour = "black",
    # Position
    mapping = 
      aes(
        x = lubridate::ymd("2024-05-01"),
        y = franchise,
        label = years_elapsed
      )
  ) +
  # Insert Title of Differences
  geom_text(
    # Bold face
    fontface = "bold",
    # Font size
    size = 4,
    # Cor
    colour = "#333333",
    # Set text a little above the dots
    nudge_y = 2,
    # Position
    mapping = 
      aes(
        x = lubridate::ymd("2024-01-01"),
        y = franchise,
        label = 
          # If Country is Germany, plot values
          ifelse(str_detect(franchise,"Winnie"),
                 # Value_if_True
                 "Years",
                 #Value_if_False
                 ""
          )
      )
  )

plot_out

ggsave(filename = "franchise_ages.png",plot = plot_out,height = 20,width = 10)


