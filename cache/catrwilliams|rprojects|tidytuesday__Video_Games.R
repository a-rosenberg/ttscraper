## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, message=FALSE, warning=FALSE)

directory <- "07-31-19 - Video Games"

if(!getwd() == paste0("C:/Users/Cat/Google Drive/Data Analysis/Tidy Tuesday/",directory)) {
  setwd(paste0("C:/Users/Cat/Google Drive/Data Analysis/Tidy Tuesday/",directory))
  }


## ----library-------------------------------------------------------------
if (!require("pacman")) install.packages("pacman")
pacman::p_load("tidyverse","naniar","zoo","textclean","lubridate","grid","gridExtra")

theme_set(theme_minimal())


## ----import--------------------------------------------------------------
df <- read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-07-30/video_games.csv")


## ----view----------------------------------------------------------------
glimpse(df)
head(df)
summary(df)
sapply(df, function(x) n_distinct(x)) %>% sort()


## ----missing-------------------------------------------------------------
#Visualize missing values
gg_miss_var(df) + labs(title="Missing Values")

#see count of missing values
na_values <- function(df){
  na <- colSums(is.na(df)) %>% sort(decreasing=TRUE)
  na[na>0]
}

na_values(df)


## ----wrangle-------------------------------------------------------------
#group by most specific attributes to less specific to get the mean for missing price
groups <- c("game","publisher","developer")

for(group in groups){
  df <- df %>% group_by(get(group)) %>% mutate(price = na.aggregate(price)) %>% ungroup()
}

df$average_playtime[(is.na(df$average_playtime))] <- 0

#check missing values again
na_values(df)

#for the remaining missing prices, use the mean of the entire dataset
df <- df %>% mutate(price = na.aggregate(price)) %>% select(-11,-metascore)

na_values(df)

#check for string abnormalities in game
check_text(df$game)

#fix strings and other data anomalies
df <- df %>% mutate(game = str_replace_all(game, "[^\x20-\x7E]", ""), #removes unicode characters
                    game = replace_non_ascii(game), #did not work for everything. line above is better
                    game = replace_emoticon(game),
                    game = replace_date(game),
                    game = replace_hash(game),
                    game = replace_kern(game),
                    game = str_trim(game),
                    game = str_squish(game),
                    game = str_to_title(game),
                    game = str_replace_all(game, "\\d/\\d", ""),
                    game = str_replace(game, "^[:punct:]+", ""),
                    game = str_replace(game, "\\|.*", ""),
                    game = str_replace(game, "(?<=\\w):(?=\\w)", ": "),
                    game = str_replace(game, "\\s-|-\\s", ": "),
                    game = paste0(game, ": "), #add : to end to make it easy to extract into a group
                    game = str_replace(game, "[:punct:]:$", ":"),
                    game_group = str_extract(game,"([^:]+(?=[:punct:]+\\s))"),
                    game_group = str_trunc(game_group,25),
                    game = str_replace(game, ": $", ""), #clean it up: remove the trailing :
                    publisher = str_replace_all(publisher, "[:punct:]+", ""),
                    publisher = str_replace_all(publisher, "[^\x20-\x7E]", ""),
                    publisher = str_to_title(publisher),
                    owners = str_replace_all(owners, ",", ""),
                    owners_lower = str_extract_all(owners, "\\d+(?=\\s\\.\\.\\s)") %>% as.integer(),
                    owners_upper = str_extract_all(owners, "(?<=\\s\\.\\.\\s)\\d+") %>% as.integer(),
                    release_date = as.Date(release_date, "%b %d, %Y"),
                    average_playtime_group = case_when(average_playtime <= max(average_playtime)*0.2 ~ "Very Low",
                                                       average_playtime > max(average_playtime)*0.2 & 
                                                         average_playtime <= max(average_playtime)*0.4 ~ "Low",
                                                       average_playtime > max(average_playtime)*0.4 & 
                                                         average_playtime <= max(average_playtime)*0.6 ~ "Medium",
                                                       average_playtime > max(average_playtime)*0.6 & 
                                                         average_playtime <= max(average_playtime)*0.8 ~ "High",
                                                       average_playtime > max(average_playtime)*0.8 ~ "Very High"),
                    average_playtime_group = fct_relevel(average_playtime_group,c("Very Low","Low","Medium","High","Very High"))) 

#remove rows that do not have any alpha characters
df <- keep_row(df, "game","\\w+")

#change strings back to factors to make them easier to work with
df <- df %>% mutate_if(is.character, as.factor)



## ----viz, out.width="100%"-----------------------------------------------
df_price <- df %>% group_by(game_group) %>% summarize(total_revenue=sum(price)) %>% ungroup() %>%
  mutate(game_group = fct_reorder(game_group, total_revenue)) %>% arrange(total_revenue) %>% tail(20)

#practice with lollipop chart
df_price %>% ggplot(aes(game_group,total_revenue))+
  geom_point(size=1.75, color="gray10")+
  geom_segment(aes(x=game_group, xend=game_group, y=0, yend=total_revenue), size=1.25, color="deepskyblue4")+
  scale_color_gradient()+
  coord_flip()+
  labs(title="Highest Grossing Video Games", caption="Data: Steam Spy | Graphics: Cat Williams @catrwilliams",
       x = "Game", y = "Total Revenue")+
  theme(plot.title = element_text(size=14, hjust=0.5, face="bold"),
        plot.caption = element_text(size=6))

#################

#determine if there is a relationship between price and average playtime
outliers <- boxplot(df$price, plot=FALSE)$out
price_lim <- summary(outliers)[["3rd Qu."]]

outliers <- boxplot(df$average_playtime, plot=FALSE)$out
playtime_lim <- summary(outliers)[["3rd Qu."]]

p1 <- df %>% ggplot(aes(price, average_playtime))+
  geom_point(alpha=0.3,color="deepskyblue4")+
  labs(title="Summary for all data",x="Game Price",y="Average Playtime")+
  theme(text= element_text(color="gray10"),
        plot.title = element_text(size=13,hjust=0.5),
        axis.title = element_text(size=10))

p2 <- df %>% ggplot(aes(price, average_playtime))+
  geom_point(alpha=0.3,color="deepskyblue4")+
  xlim(0,price_lim)+
  ylim(0,playtime_lim)+
  labs(title="Zoomed in to remove outliers",x="Game Price",y="Average Playtime")+
  theme(text= element_text(color="gray10"),
        plot.title = element_text(size=13,hjust=0.5),
        axis.title = element_text(size=10))

tg <- grobTree(textGrob("Price vs. Average Time Played: No Distinct Relationship", 
                        y=1, 
                        vjust=1, 
                        gp=gpar(fontface="bold", fontsize = 16, color="deepskyblue4")),
               cl="titlegrob")

heightDetails.titlegrob <- function(x) do.call(sum,lapply(x$children, grobHeight))

#create final plot
p3 <- grid.arrange(arrangeGrob(p1,p2,nrow=1),top = tg)

#################

df_publisher <- df %>% group_by(publisher) %>% summarize(total_price=sum(price)) %>% ungroup() %>% 
  filter(publisher != "") %>% mutate(publisher = fct_reorder(publisher, total_price)) %>% 
  arrange(total_price) %>% tail(20)

df_publisher %>% ggplot(aes(publisher, total_price))+
  #geom_col(fill="deepskyblue4")+
  geom_point(size=1.75, color="gray10")+
  geom_segment(aes(x=publisher, xend=publisher, y=0, yend=total_price), size=1.25, color="deepskyblue4")+
  coord_flip()+
  labs(title="Top Video Game Publishers by Total Revenue", x="Revenue", y="Publisher")+
  theme(text= element_text(color="gray10"),
        plot.title = element_text(size=14, hjust=0.5, face="bold"),
        axis.title = element_text(size=10))
  
#################

#does having more players encourage more playtime?
df %>% ggplot()+
  geom_segment(aes(x=owners_lower, xend=owners_upper, y=average_playtime_group, yend=average_playtime_group), 
               size=1.25, color="deepskyblue4")+
  scale_x_continuous(labels=c("0","50","100","150","200"))+
  labs(title="Video Games: Does having more players encourage more playtime?", 
       subtitle="It appears that more players correlates with lower average playtime",
       x="Number of Players (in millions)", y="Time Played", 
       caption="Data: Steam Spy | Graphics: Cat Williams @catrwilliams")+
  theme(plot.title=element_text(hjust=0.5, color="deepskyblue4", face="bold"),
        text = element_text(color="gray10"),
        plot.subtitle=element_text(hjust=0.5, face="bold"),
        plot.caption = element_text(size=6),
        axis.title = element_text(size=10))

ggsave("video-games.png")

