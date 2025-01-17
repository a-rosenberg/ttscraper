## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)


## ----warning=FALSE, message=FALSE----------------------------------------
library(readr)
library(dplyr)
library(tidyr)
library(purrr)
library(ggplot2)
library(ggimage)


## ------------------------------------------------------------------------
cran_R_df <- read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2018-10-30/r_downloads_year.csv") %>% select(-X1)


## ------------------------------------------------------------------------
# Set your range of dates
start <- as.Date('2018-10-01')
today <- as.Date('2018-10-07')

all_days <- seq(start, today, by = 'day')

year <- as.POSIXlt(all_days)$year + 1900

# combine dates into a character vector of dates
urls <- paste0('http://cran-logs.rstudio.com/', year, '/', all_days, '.csv.gz')

cran_packages_df <- urls %>%
  map_dfr(read_csv)


## ------------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(ggplot2)
library(cranlogs)
library(ggtextures) # devtools::install_github("clauswilke/ggtextures")
library(scales)
library(extrafont)
loadfonts()

# top 10 package downloads from 9/29 to 10/28 from 'cranlogs' package
top_10_october <- cran_top_downloads(when = "last-month", count = 10)

top_10_october_images <- top_10_october %>% 
  mutate(image = c(
    "https://raw.githubusercontent.com/tidyverse/tidyverse/master/man/figures/logo.png",
    "https://raw.githubusercontent.com/isocpp/logos/master/cpp_logo.png",
    "https://raw.githubusercontent.com/r-lib/rlang/master/man/figures/rlang.png",
    "https://raw.githubusercontent.com/tidyverse/ggplot2/master/man/figures/logo.png",
    "https://upload.wikimedia.org/wikipedia/en/1/1f/Spool_of_string.jpg",
    "https://pixfeeds.com/images/16/421149/1200-498885446-digestive-system.jpg",
    "https://raw.githubusercontent.com/tidyverse/glue/master/man/figures/logo.png",
    "https://raw.githubusercontent.com/tidyverse/dplyr/master/man/figures/logo.png",
    "https://i.imgur.com/JYv9NTF.jpg",
    "https://raw.githubusercontent.com/tidyverse/stringr/master/man/figures/logo.png")) %>% 
  mutate(count_lab = comma(count))

# PLOT
ggplot(top_10_october_images, 
       aes(x = reorder(package, -count), y = count, 
           image = image)) +
  geom_textured_col(img_width = unit(0.6, "null")) +
  geom_text(aes(label = count_lab, family = "Roboto Condensed"), 
            size = 3.5,
            nudge_y = 25000) +
  scale_y_continuous(expand = c(0, 0),
                     limits = c(0, 1100000),
                     labels = scales::comma) +
  labs(title = "Top 10 Most Downloaded R Packages in the Past Month",
       subtitle = "from CRAN: Sept. 28, 2018 - Oct. 29, 2018",
       x = "Package", y = "# of Times Downloaded") +
  theme_minimal() +
  theme(text = element_text(family = "Roboto Condensed"),
        axis.text = element_text(size = 10),
        axis.title = element_text(size = 12),
        panel.grid.major.x = element_blank())


## ------------------------------------------------------------------------
# isotype plot

ggplot(top_10_october_images, 
       aes(x = reorder(package, -count), y = count, 
           image = image)) +
  geom_isotype_col(img_height = grid::unit(100000, "native")) +
  geom_text(aes(label = count_lab, family = "Roboto Condensed"), 
            size = 3.5,
            nudge_y = 25000) +
  scale_y_continuous(expand = c(0, 0),
                     limits = c(0, 1100000),
                     labels = scales::comma) +
  labs(title = "Top 10 Most Downloaded R Packages in the Past Month",
       subtitle = "from CRAN: Sept. 28, 2018 - Oct. 29, 2018",
       x = "Package", y = "# of Times Downloaded") +
  theme_minimal() +
  theme(text = element_text(family = "Roboto Condensed"),
        axis.text = element_text(size = 10),
        axis.title = element_text(size = 12),
        panel.grid.major.x = element_blank())

