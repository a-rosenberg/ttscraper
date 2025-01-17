## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)
library(tidyverse)


## ------------------------------------------------------------------------
d <- read.csv('school_diversity.csv')


## ------------------------------------------------------------------------
str(d)


## ------------------------------------------------------------------------
head(d)


## ------------------------------------------------------------------------
d %>% filter(SCHOOL_YEAR=='2016-2017') %>% group_by(SCHOOL_YEAR,ST,) %>% summarize(nasian = mean(Asian)) %>% arrange(desc(nasian))


## ------------------------------------------------------------------------
d <- d %>% gather("racial_group","value",6:11)


## ------------------------------------------------------------------------
d %>% filter(SCHOOL_YEAR=='2016-2017') %>% group_by(racial_group,ST) %>% summarize(mean = mean(value))

