## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)


## ----library, message = F, warning = F-----------------------------------
library(tidyverse)
library(Hmisc)


## ----read data, message = F, warning = F---------------------------------
fname1   <- "../data/week8_honey_production/honeyraw_1998to2002.csv"
fname2   <- "../data/week8_honey_production/honeyraw_2003to2007.csv"
fname3   <- "../data/week8_honey_production/honeyraw_2008to2012.csv"
df_raw1  <- read_csv(fname1, col_names = F, skip = 9)
df_raw2  <- read_csv(fname2, col_names = F, skip = 81)
df_raw3  <- read_csv(fname3, col_names = F, skip = 72)


## ----wrangle csv 1 and 2-------------------------------------------------
tidyfun <- function(df_raw, year0){
df_raw %>% 
    drop_na()%>% 
  filter(X3 %in% state.abb) %>% 
  mutate_at(vars(X4:X9), as.numeric) %>% 
  mutate(X1 = X1 + year0 -1,
         X4 = X4 * 1000,
         X6 = X4 * X5,
         X7 = X7 * 1000,
         X8 = X8/100,
         X9 = X6 * X8) %>% 
  select(-X2) %>% 
  rename(year = X1, st = X3, numcol = X4, yieldpercol = X5,
         totalprod = X6, stocks = X7, priceperlb = X8, prodvalue = X9)  
}

df_data1 <- tidyfun(df_raw1, 1998)
df_data2 <- tidyfun(df_raw2, 2003)
#df_data3 <- tidyfun(df_raw3)


## ----wrangle csv 3-------------------------------------------------------
#names(state.abb) <- state.name  

df_data3 <- df_raw3 %>% 
  mutate(X3 = state.abb[match(X3, state.name)]) %>% 
  tidyfun(2008)


## ------------------------------------------------------------------------
df_data_all <- bind_rows(df_data1, df_data2, df_data3)


## ----fig.height = 10-----------------------------------------------------
df_data_all %>% 
  group_by(st) %>% 
  summarise(sumprod = sum(totalprod)) %>% 
  arrange(desc(sumprod)) %>% 
  ggplot(aes(x = fct_reorder(st, sumprod), y = sumprod)) + 
  geom_bar(stat = "identity") +
  labs(x = "State", y = "Total Production") +
  coord_flip() +
  ggtitle("US Honey Production (1998-2012)")


## ------------------------------------------------------------------------
st10 <- df_data_all %>% 
  group_by(st) %>% 
  summarise(sumprod = sum(totalprod)) %>% 
  arrange(desc(sumprod)) %>% 
  top_n(5)
df_data_all %>% 
  filter(st %in% st10$st) %>% 
  ggplot(aes(x = year, y = totalprod, color = st)) + 
  geom_point() +
  geom_smooth(se = F)+
  guides(color = guide_legend(NULL))+
  labs(x = "Year", y = "Total Production") +
  ggtitle("Honey Production of Top 5 States")

