## ----echo=FALSE,message=FALSE,warning=FALSE------------------------------
library(magrittr) # para el %T>%
library(tidyverse)
# library(sf)
library(dplyr)
library(stringr)#;
# library(rebus)#; install.packages('rebus')
# library(tidytext)
library(prophet)


# install.packages("Rcpp")
# remotes::install_github("tylermorganwall/rayshader")
# library(rayshader)
library(lubridate)
library(ggforce)
library(ggrepel)

library(arules)#install.packages('arules')
library(arulesViz)#install.packages('arulesViz')
library(igraph)



## ----echo=FALSE,message=FALSE,warning=FALSE------------------------------
bob_ross <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-08-06/bob-ross.csv")
bob_ross_processed <- bob_ross %>% 
    janitor::clean_names() %>% 
    mutate(title=str_remove_all(title,'"'))


## ----echo=FALSE,message=FALSE,warning=FALSE------------------------------
bob_ross_processed %>% head()



## ----echo=FALSE,message=FALSE,warning=FALSE------------------------------
bob_ross_processed %>% glimpse()



## ----echo=FALSE,message=FALSE,warning=FALSE------------------------------
bob_ross_processed %>% skimr::skim()




## ----echo=FALSE,message=FALSE,warning=FALSE------------------------------
bob_ross_processed_trees <- bob_ross_processed %>% 
    mutate(id=paste0(episode,title)) %>% 
    select(id,tree,trees) %>% filter(trees==1 | tree == 1)

bob_ross_processed_trees %>% select(tree,trees) %>% table()

bob_ross_processed_trees %>% filter(trees==0)
bob_ross_processed_trees %>% filter(trees==1)



## ----echo=FALSE,message=FALSE,warning=FALSE------------------------------
elements_picture <- bob_ross_processed %>%  
    tibble::rownames_to_column() %>% # to get transactions id's
    mutate(rowname=as.integer(rowname)) %>% 
    rename(r_id=rowname) %>% 
    gather(element,appear,-episode,-title,-r_id) %>% 
    filter(appear==1)




transactions <- elements_picture %>% select(r_id,element) %>% arrange(r_id) %>% rename(itemset=element)
# elements_picture_graph_data <- elements_picture %>% select(TITLE,ELEMENT)

data_file <- here::here("jas1_weeks","2019","2019-08-06","tx_file.txt")
write.csv(transactions,file = data_file,row.names=FALSE,fileEncoding = "UTF-8")

tx <- read.transactions(data_file ,
                        format = "single",
                        sep = ",",
                        cols = c("r_id", "itemset"),
                        rm.duplicates = TRUE)

# transactions %>% distinct(itemset)



## ----echo=FALSE,message=FALSE,warning=FALSE------------------------------

# summary(tx)
# itemFrequencyPlot(tx,topN=20,type="absolute")
# itemFrequencyPlot(tx,topN=20,type="relative")

item_freq <- tx %>% itemFrequency()
item_freq_names <- item_freq %>% names()
tx_for_plot <- data.frame(element=item_freq_names,freq=item_freq,stringsAsFactors = FALSE) %>%
    as_tibble() %>%
    mutate(element=fct_reorder(element,freq))
    
set.seed(42)
freq_elements_plot <- tx_for_plot %>% 
ggplot(aes(element,freq,fill=element)) + 
geom_col() + 
scale_y_continuous(breaks = seq(0,1,0.25))+
theme_light()+
theme(legend.position = "none")+
coord_flip()+
    labs(title="Frequency of Elements of Bob Ross paintings",
         # subtitle="",
         x="",
         y="frequency",
         caption = "#TidyTuesday"
         )
freq_elements_plot
ggsave(freq_elements_plot,filename = "freq_elements_plot.png",height = 8,width = 6)


## ----echo=FALSE,message=FALSE,warning=FALSE------------------------------

# summary(tx)
# itemFrequencyPlot(tx,topN=20,type="absolute")
# itemFrequencyPlot(tx,topN=20,type="relative")

item_freq_count <- tx %>% itemFrequency(type="absolute")
item_freq_names_count <- item_freq_count %>% names()
tx_for_plot_count <- data.frame(element=item_freq_names,count=item_freq_count,stringsAsFactors = FALSE) %>%
    as_tibble() %>%
    mutate(element=fct_reorder(element,count))
    
set.seed(42)
freq_elements_plot_count <- tx_for_plot_count %>% 
ggplot(aes(element,count,fill=element)) + 
geom_col() + 
scale_y_continuous(breaks = seq(0,375,25))+
theme_light()+
theme(legend.position = "none",
      axis.text.x=element_text(angle=90))+
coord_flip()+
    labs(title="Count of Elements of Bob Ross paintings",
         #subtitle="",
         x="",
         y="",
         caption = "#TidyTuesday"
         )
freq_elements_plot_count
ggsave(freq_elements_plot_count,
       filename = "freq_elements_plot_count.png",
       height = 8,width = 5)


## ----echo=FALSE,message=FALSE,warning=FALSE------------------------------

rules <- apriori(tx,
             parameter=list(supp=0.01,
                            conf=0.8,
                            maxlen=10))

subset_rules <- which(colSums(is.subset(rules, rules)) > 1)
length(subset_rules)
no_redundant_rules <- rules[-subset_rules] # remove subset rules.
length(no_redundant_rules)
# rules

 # inspect(sort(rules))

# inspect(head(sort(rules), n=10))
#


# plot(head(sort(rules, by = "lift"), n=50),
#      method = "graph",
#      control=list(cex=.8))
# 

element_visnet <- plot(head(sort(no_redundant_rules, by = "lift"), n=50),
     method = "graph",
     engine="htmlwidget",
     control=list(cex=.8))

element_visnet %>% 
    visNetwork::visSave( file = "bob_ross_rules.html")
# visNetwork::visExport(type = "png", name = "network",
#   label = paste0("Export as png"), background = "#fff",
#   float = "right", style = NULL, loadDependencies = TRUE)




## ----echo=FALSE,message=FALSE,warning=FALSE------------------------------

# graph_from_picture <- igraph::graph_from_data_frame(elements_picture_graph_data) %>% as_tbl_graph()
# igraph::V(graph_from_picture)$type <- igraph::V(graph_from_picture)$name == elements_picture_graph_data$TITLE
# igraph::V(graph_from_picture)$color <- if_else(igraph::V(graph_from_picture)$type == 1,"#FF0000","#0000FF")
# 
# 
# # visNetwork::visIgraph(igraph_network)
# visNetwork::visIgraph(graph_from_picture) %>% 
#     visNetwork::visIgraphLayout(randomSeed = 42, layout="layout_as_bipartite")
# 
# 
# 
#     ggplot(aes(x=TITLE,y=element,fill=as.factor(appear)))+
#     geom_tile()+
#     theme(axis.text.x = element_text(angle=90))
    # labs()


## ------------------------------------------------------------------------
bob_ross_processed %>% filter(fire==1)


## ----echo=FALSE,message=FALSE,warning=FALSE------------------------------
#https://github.com/othomantegazza/code-tidytuesday/blob/master/2-32-painting-voronoi.R
# Most steps are taken form:
# https://chichacha.netlify.com/2018/11/12/utilizing-k-means-to-extract-colours-from-your-favourite-images/


# set up ------------------------------------------------------------------


library(tidyverse)
library(imager)
library(ggvoronoi) # install.packages("ggvoronoi")
library(grid)

# background color
bg_color <- "#E8EDEF"

# Get image ---------------------------------------------------------------

image_path <- "2-32-bob-ross-sunset.Rdata"


if(!file.exists(image_path)) {
  # img <- load.image("https://fivethirtyeight.com/wp-content/uploads/2014/04/campfire_banner1.jpg")
  img <- load.image("campfire_banner1.jpg")
  save(img, file = image_path)
} else {
  load(image_path)
}


# analyze -----------------------------------------------------------------

# number of pixel?
dim(img)[1]*dim(img)[2]

# colours: hex value for every pixel
hex_pix <- 
  img  %>% 
  as.data.frame(wide = "c") %>% 
  mutate(hexval = rgb(c.1,c.2,c.3))

# luminosity for every pixes
grey_pix <- 
  img %>% 
  grayscale() %>% 
  as.data.frame()

# merge
hex_pix <- 
  hex_pix %>%
  inner_join(grey_pix)


# sample pixels ------------------------------------------------------------

set.seed(42); hex_pix_mini <- 
  hex_pix %>% 
  sample_n(2500, weight = value) # more likely if luminosity is higher 
  
# colors named vectors
# for plotting
pix_colors <- 
  hex_pix_mini %>% 
  pull(hexval) %>% 
  {purrr::set_names(x = .,
                   nm = .)}

# range of axis
range_x <- c(0, dim(img)[1])
range_y <-  c(dim(img)[2], 0)

p <- 
  hex_pix_mini %>% 
  ggplot(aes(x = x,
             y = y)) +
  # geom_point(aes(colour = hexvalue)) +
  ggvoronoi::geom_voronoi(aes(fill = hexval),
                          colour = bg_color,
                          size = .2) +
  scale_y_reverse(limits = range_y,
                  expand = expand_scale(mult = .01)) +
  scale_x_continuous(limits = range_x,
                     expand = expand_scale(mult = .01)) +
  scale_fill_manual(values = pix_colors, guide = FALSE) +
  coord_fixed() +
  theme_void() +
  theme(plot.background = element_rect(fill = bg_color),
        plot.margin = margin(0,0,0,0)) +
    labs(title = "Voronoi test on: S03E10 - CAMPFIRE",
         subtitle = "Bob Ross paint , voronoi code by @othomn, @chisatini",
         caption = "#TidyTuesday")

# svglite::svglite(file = "plots/2-32-painting-voronoi.svg")
# p %>% print()
# dev.off()
ggsave(plot = p ,filename = "voronoi_2.png")


# decorate plot with grid and save ----------------------------------------
# 
# # png parameters
# img_height <- 2800
# img_width <- 2300
# 
# # position of bottom left corner
# img_x <- .2
# img_y <- .18
# 
# # and plot size
# plot_width <- 1 - img_x - .05
# plot_height <- 1 - img_y - .05
# 
# # save
# png(file = "2-32-painting-voronoi.png",
#     height = img_height,
#     width = img_width,
#     res = 300)
# grid.newpage()
# # background
# grid.rect(gp = gpar(fill = "#838798"))
# # plot
# p %>% print(vp = viewport(x = img_x, y = img_y, 
#                           just = c(0, 0),
#                           height = plot_height,
#                           width = plot_width))
# # side caption
# grid.text(label = str_wrap("Voronoi tesselation of one of Bob Ross paintigs. Inspired by @chisatini's blog.",
#                            width = 14),
#           x = img_x - .003, y = .945,
#           hjust = 1, vjust = 1, gp = gpar(size = 14, lineheight = 1,
#                                           col = bg_color))
# # signature
# grid.text(label = "Painting by Bob Ross | Plot by @othomn",
#           x = .92, y = .1,
#           hjust = 1, vjust = 1, gp = gpar(fontsize = 10, lineheight = 1,
#                                           col = bg_color))
# dev.off()
# 
# 
# # save json for d3 --------------------------------------------------------
# 
# library(jsonlite)
# 
# hex_pix_mini %>% 
#   toJSON() %>%
#   {paste("var hexpix = ", .)} %>% 
#   cat(file = "d3/json_data/2-32-painting-voronoi.js")


