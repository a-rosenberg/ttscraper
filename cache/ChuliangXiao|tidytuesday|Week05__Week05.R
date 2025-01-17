## ----setup, include = FALSE----------------------------------------------
knitr::opts_chunk$set(echo = TRUE)


## ----message = F, warning = F--------------------------------------------
library(tidyverse)
library(Hmisc)
library(maps)


## ----message = F, warning = F--------------------------------------------
dfASC <- read_csv("../data/acs2015_county_data.csv")


## ------------------------------------------------------------------------
Upper1  <- function(x){
  substr(x, 1, 1) <- toupper(substr(x, 1, 1))
  x
}

cnty <- map_data("county")%>%
  as_tibble()%>%
  rename(State = region, County = subregion) %>%
  mutate(County = str_replace(County, "Dona Ana", "Doña Ana")) 

#dfASC <- dfASC%>%
#  select(CensusId:County, MeanCommute)
head(cnty)


## ------------------------------------------------------------------------
# cnty has 48 states and DC
# ASC has all 50 States, DC and PR
cntyASC <- left_join(cnty, dfASC, by = c("State", "County"))

stASC   <- dfASC %>%
  group_by(State) %>%
  summarise(MeanCommute = sum(MeanCommute * TotalPop)/sum(TotalPop))


## ------------------------------------------------------------------------
cntyMiss <- cntyASC%>%
  filter(is.na(MeanCommute))%>%
  group_by(State, County)%>%
  summarise(Missing = 1)

#cntyMiss %>% as.data.frame()
# https://en.wikipedia.org/wiki/De_Kalb,_Missouri
# https://en.wikipedia.org/wiki/DeKalb_County,_Alabama


## ----message = F, warning = F, fig.width = 10----------------------------
plt <- ggplot(cnty, aes(long, lat, group = group)) + 
  geom_polygon(data = cntyASC, aes(fill = MeanCommute), 
 #              show.legend = FALSE, 
               colour = "grey") + 
  coord_quickmap()+
  scale_fill_distiller(name = "Minutes", palette = "Spectral")+
  theme_void()+
  labs(title = "Mean Commute Time",
       caption = "Cource: US Census Demogrpahic Data 2015")
plt


## ----message = F, warning = F, fig.width = 10----------------------------
library(albersusa)
uscnty <- counties_composite()
# fortify may be deprecated in the future.
usmap  <- broom::tidy(uscnty, region = "fips") %>% 
  as.tbl() %>%
  mutate(id = as.integer(id))

albers <- usmap %>%
  left_join(dfASC, by = c("id" = "CensusId")) %>% 
  ggplot(aes(long, lat, group = group)) + 
  geom_polygon(aes(fill = MeanCommute), 
               colour = "grey") + 
  coord_quickmap()+
  scale_fill_distiller(name = "Minutes", palette = "Spectral")+
  theme_void()+
  labs(title = "Commute Time",
       caption = "Cource: US Census Demogrpahic Data 2015") #+
#  scale_fill_continuous(guide = guide_legend(title = "Mins"))+
#  guides(fill = guide_legend(title = "Minutes"))
albers


## ----message = F, warning = F, fig.width = 10----------------------------
library(plotly)
#ggplotly(p)


## ----message = F, warning = F, fig.width = 10----------------------------
# https://bookdown.org/rdpeng/RProgDA/mapping.html#mapping-us-counties-and-states
# https://github.com/trulia/choroplethr
library(choroplethr)
library(choroplethrMaps)
data(df_pop_county)

# https://twitter.com/nlj/status/991149834085289984
mean_commute <- dfASC %>%
  select(CensusId, MeanCommute) %>%
  rename(region = CensusId, value = MeanCommute)

choro               <- CountyChoropleth$new(mean_commute)
choro$title         <- "Mean Commute Times"
choro$ggplot_scale  <- scale_fill_brewer(name = "Minites", palette = 2, drop = F)
choro$legend
choro$render()


## ----message = F, warning = F, fig.width = 10----------------------------
library(fiftystater)
data("fifty_states")

fifty <- stASC %>% 
  mutate(State = tolower(State)) %>% 
  ggplot(aes(map_id = State)) +
  geom_map(aes(fill = MeanCommute), map = fifty_states) +
  expand_limits(x = fifty_states$long, y = fifty_states$lat) +
  scale_fill_distiller(name = "Minutes", palette = "Spectral") +
  coord_map() + 
  theme_void() +
  ggtitle( "Mean Commute Time" ) +
  labs(caption = "Cource: US Census Demogrpahic Data 2015")
fifty


## ----message = F, warning = F, fig.width = 10----------------------------
library(statebins)

bin <- stASC %>% 
  mutate(bin = cut(MeanCommute,
                   breaks = c(seq(10, 35, by = 5), Inf),
                   labels = c(seq(10, 30, by = 5), "35+"),
                   include.lowest = TRUE)) %>% 
  ggplot(aes(state = State, fill = MeanCommute)) + 
  geom_statebins() + 
  scale_fill_distiller(name = "Minutes", palette = "Spectral") +
  coord_map() + 
  theme_void() +
  ggtitle( "Mean Commute Time" ) +
  labs(caption = "Cource: US Census Demogrpahic Data 2015") 
bin


## ----include = F, message = F, warning = F, fig.width = 10---------------
library(rcstatebin)

st_crosswalk <- tibble(State = state.name) %>%
  bind_cols(tibble(ST = state.abb)) %>% 
  bind_rows(tibble(State = "District of Columbia", ST = "DC")) %>%
  bind_rows(tibble(State = "Puerto Rico", ST = "PR"))
#st_crosswalk$ST <- as.factor(st_crosswalk$ST)

stDemo   <- dfASC %>%
  group_by(State) %>%
  mutate_at(vars(Hispanic : Pacific), funs(. * TotalPop / 100)) %>%
  summarise_at(vars(TotalPop : Pacific), sum, na.rm = TRUE) %>%
  group_by(State) %>%
  mutate_at(vars(Men : Pacific), funs(round(. / TotalPop * 100, 3))) %>%
  left_join(st_crosswalk) %>%
  gather(TotalPop:Pacific, key = "demo", value = "share") %>% 
  filter(ST != "PR")
  
  

statebin(data = stDemo,
  x = "ST",
  y = "share",
  facet = "demo",
  heading =  "<b>State Demographics</b>",
  footer = "<small>Cource: US Census Demogrpahic Data 2015",
  colors = RColorBrewer::brewer.pal(5, 'PuRd'),
  control = 'dropdown'
)


## ----message = F, warning = F, fig.width = 10----------------------------
# https://www.r-graph-gallery.com/328-hexbin-map-of-the-usa/
library(geojsonio)
library(broom)
library(rgeos)

spdf            <- geojson_read("us_states_hexgrid.geojson",  what = "sp")
spdf@data       <- spdf@data %>% mutate(google_name = gsub(" \\(United States\\)", "", google_name))
spdf_fortified  <- tidy(spdf, region = "google_name")

centers <- cbind.data.frame(data.frame(gCentroid(spdf, byid = TRUE), id = spdf@data$iso3166_2))

spdf_fortified <- left_join(spdf_fortified , stASC, by=c("id" = "State")) 
spdf_fortified$bin <- cut(spdf_fortified$MeanCommute,
                          breaks = c(seq(10, 35, by = 5), Inf),
                          labels = c(seq(10, 30, by = 5), "35+"),
                          include.lowest = TRUE
                          )
 

library(viridis)
my_palette <- rev(magma(8))[c(-1,-8)]

hex <- ggplot() +
  geom_polygon(data = spdf_fortified, 
               aes(fill =  bin, x = long, y = lat, group = group)) +
  geom_text(data = centers, 
            aes(x = x, y = y, label = id), 
            color = "white", size = 3, alpha = 0.6
            ) +
  theme_void() +
  coord_map() +
  scale_fill_manual(values = my_palette, 
                    name="(units: minute)", 
                    guide = guide_legend(keyheight = unit(3, units = "mm"), 
                                         keywidth=unit(12, units = "mm"), 
                                         label.position = "bottom", 
                                         title.position = 'top', nrow=1
                                         ) 
                    ) +
  ggtitle( "Mean Commute Time" ) +
  labs(caption = "Cource: US Census Demogrpahic Data 2015") +
  theme(legend.position = c(0.5, 0.9),
        text = element_text(color = "#22211d"))

 hex


## ----message = F, warning = F, fig.width = 10----------------------------



## ----message = F, warning = F, fig.height = 10, fig.width = 10-----------
library(grid)
library(gridExtra)
d <- choro$render()
grid.arrange(plt, albers, bin, hex, fifty, d, ncol = 2)

