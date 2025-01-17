## ------------------------------------------------------------------------
# Packages
library(tidyverse)
library(lubridate)
library(ggmap)
library(ggthemes)
library(ggrepel)
library(extrafont)

# Fonts for export
# loadfonts(device = "win")
# loadfonts()

# Color choices from BIKETOWN website
bikeorange <- "#FC4C02"
darkgray <- "#393737"
medgray <- "#434345"
lightgray <- "#75787B"
medbkgd <- "#D4D2D3"
lightbkgd <- "#E4E2E3"


## ------------------------------------------------------------------------
filelist <- list.files("PublicTripData/Quarterly") # data as downloaded

raw_bike <- data.frame()
for(f in filelist) {
  temp_bike <- read_csv(paste0("PublicTripData/Quarterly/", f)) %>% 
    mutate(Duration = as.difftime(Duration)) #Necessary to fix a join issue with different csv's
  raw_bike <- raw_bike %>% bind_rows(temp_bike)
}


## ------------------------------------------------------------------------
bike_parsed <- raw_bike %>% 
  mutate(StartDate = mdy(StartDate)) %>% 
  mutate(start_wday = wday(StartDate, label = TRUE)) %>% 
  mutate(weekend = case_when(
    str_detect(start_wday, "Sun|Sat") ~ "Weekend",
    TRUE ~ "Weekday"))

summary(bike_parsed)


## ------------------------------------------------------------------------
# Cardinal directions, coordinates, colors
compass_df <- data.frame(card_dir = c("N", "NE", "E","SE",
                                       "S", "SW", "W", "NW"),
                         x = c(0, 0.707, 1, 0.707,
                               0, -0.707, -1, -0.707),
                         y = c(1, 0.707, 0, -0.707,
                               -1, -0.707, 0, 0.707),
                         # compcolor = c("red", "orange", "chartreuse2", "green",
                         #               "cyan2", "blue", "purple", "pink"),
                         hexcolor = c("#e71516",
                                      "#FC4C02",
                                      "#82ef31",
                                      "#1eca32",
                                      "#38e8e5", 
                                      "#c504f6", #"#0c8cf5", #"#0452f6",
                                      "#0c8cf5", #"#9903fc", #"#6619c8",
                                      "#e216a2"))

# Basic plot
ggplot(compass_df, aes(x = x, y = y, color = hexcolor)) +
  scale_color_identity() +
  geom_segment(aes(x = 0, y = 0, xend = x, yend = y),
               size = 2, arrow = arrow()) +
  geom_point(aes(x = 0, y = 0), size = 5, color = "white") +
  theme(legend.position = "none", 
        panel.background = element_blank()) +
  coord_fixed(ratio = 1)

# Plot using long skinny arrows to look similar to standard compass rose
ggplot(compass_df, aes(x = x, y = y, color = hexcolor)) +
  scale_color_identity() +
  geom_segment(aes(x = 0, y = 0, xend = x, yend = y),
               size = 0,
               arrow = arrow(length = unit(0.4, "native"),
                             type = "closed",
                             angle = 3)) +
  geom_point(aes(x = 0, y = 0), size = 18, color = "white") +
  #geom_text() +
  theme(legend.position = "none", 
        panel.background = element_blank()) +
  coord_fixed(ratio = 1)


## ------------------------------------------------------------------------
bikegps <- bike_parsed %>% 
  filter(!is.na(StartLatitude) &
           !is.na(StartLongitude) &
           !is.na(EndLatitude) &
           !is.na(EndLongitude)) %>% 
  mutate(d_lat = EndLatitude - StartLatitude) %>% 
  mutate(d_lon = EndLongitude - StartLongitude) %>% 
  mutate(r_start_lat = round( #round off to 0.002, 0.004, 0.006 etc...
    StartLatitude * 5, 2) /5) %>% 
  mutate(r_start_lon = round( #round off to 0.002, 0.004, 0.006 etc...
    StartLongitude * 5, 2) /5)


## ------------------------------------------------------------------------
gps_sum <- bikegps %>% 
  filter(!is.na(r_start_lat)) %>% 
  group_by(r_start_lat, r_start_lon) %>% 
  summarise(rides = n(), d_lat = median(d_lat), d_lon = median(d_lon)) %>% 
  ungroup() %>% 
  filter(rides >= 10)

ggplot(gps_sum, aes(x = r_start_lon, y = r_start_lat)) + 
  geom_point(alpha = 0.2) + 
  geom_segment(aes(xend = r_start_lon + 0.25*d_lon, yend = r_start_lat + 0.25*d_lat), arrow = arrow(length = unit(0.1, "inches"))) +
  coord_cartesian(xlim = c(-122.7, -122.62), ylim = c(45.49, 45.56))


## ------------------------------------------------------------------------
tod_bike <- bikegps %>% 
  mutate(time_of_day = factor(case_when(
    between(hour(StartTime), 4, 9) ~ "Morning", #When the hour position of the start time is >= 4 and <= 9, call "Morning"
    between(hour(StartTime), 10, 15) ~ "Midday",
    between(hour(StartTime), 16, 21) ~ "Evening",
    between(hour(StartTime), 22, 24) ~ "Late Night",
    between(hour(StartTime), 0, 3) ~ "Late Night"),
    levels = c("Late Night", "Morning", "Midday", "Evening"),
    labels = c("Late Night (10pm-4am)", "Morning (4am-10am)", "Midday (10am-4pm)", "Evening (4pm-10pm)")
    ))

summary(tod_bike$time_of_day)


## ------------------------------------------------------------------------
tod_bike_sum <- tod_bike %>% 
  group_by(r_start_lat, r_start_lon, time_of_day, weekend) %>% 
  summarise(rides = n(), d_lat = median(d_lat), d_lon = median(d_lon)) %>% 
  filter(rides >= 10)


## ------------------------------------------------------------------------
tod_card <- tod_bike_sum %>% 
  #atan2(y, x) gives the angle of a point relative to the origin in radians
  #atan2(y, x) * 180 / pi gives the angle in degrees
  #a flat line to the right ("east") is 0, up ("north") is 90, down ("south") is -90, and left ("west") is 180/-180
  mutate(d_angle = (atan2(d_lat, d_lon) * 180) / pi) %>%
  mutate(card_dir = case_when(
    d_angle <= 22.5 & d_angle > -22.5 ~ "E",
    d_angle <= -22.5 & d_angle > -67.5 ~ "SE",
    d_angle <= -67.5 & d_angle > -112.5 ~ "S",
    d_angle <= -112.5 & d_angle > -157.5 ~ "SW",
    d_angle <= -157.5 | d_angle > 157.5 ~ "W",
    d_angle <=  157.5 & d_angle > 112.5 ~ "NW",
    d_angle <= 112.5 & d_angle > 67.5 ~ "N",
    d_angle <= 67.5 & d_angle > 22.5 ~ "NE")) %>% 
  left_join(compass_df, by = "card_dir")


## ------------------------------------------------------------------------
left <- -122.71
bottom <- 45.499
right <- -122.610
top <- 45.561
custom_bound_box <- c(left, bottom, right, top)
names(custom_bound_box) <- c("left", "bottom", "right", "top")

# "Toner-lines" chosen for not having street labels, even though the contrast is higher, which we will cover with transparency
custompdxmap <- get_map(location = custom_bound_box, maptype = "toner-lines")

# Separate dataframe for the coordinates above, used to create transparency layer over map
fade_box <- data.frame(lat = c(left, right, right, left),
                       lon = c(bottom, bottom, top, top))


## ---- fig.height= 11.2, fig.width=15.4-----------------------------------
ggmap(custompdxmap,
      # The base_layer is essential to properly facet_wrap the plotted data
      base_layer = ggplot(data = tod_card %>% filter(weekend == "Weekday"), #subset data to only Weekdays, weekends are less consistent
        aes(xend = r_start_lon + 0.25*d_lon, # Scale the delta in lat/long by 25% to reduce length of lines
            yend = r_start_lat + 0.25*d_lat,
            x = r_start_lon,
            y = r_start_lat,
            color = hexcolor))) + #Pull colors direct from compass rose choices above
  # Prior to plotting segments, add a semitransparent box to give a dark background and reduce the visual noise of the map
  geom_polygon(data = fade_box,
               aes(x = lat,
                   y = lon),
               fill = "black",
               alpha = 0.7,
               # "inhterit.aes = FALSE" is essential for this to plot, given the aesthetics set above
               inherit.aes = FALSE) +
  # Draw every given line/arrow
  geom_segment(size = 0.5,
               arrow = arrow(length = unit(0.1, "inches"), 
                             angle = 20)) +
  # Set the colors to exactly as given in the dataset
  scale_color_identity() +
  # Maintain a 1-to-1 size of x and y points
  coord_fixed(ratio = 1) +
  # Generally remove axis, ticks, labels, etc
  theme_map() +
  # Draw small circle around CascadiaRConf location - OHSU CLSB
  geom_point(aes(x = -122.672, y = 45.503), size = 4, pch = 1, color = "white") +
  # Text labeling CascadiaRConf location
  geom_text_repel(data = data.frame(x = -122.672, y = 45.503, label = "You are\nhere"),
    aes(x = x, y = y, label = label),
    arrow = arrow(length = unit(0.08, "inches"), type = "closed"),
    segment.size = 0.5,
    nudge_x = -0.02,
    #nudge_y = -0.001,
    color = medbkgd,
    point.padding = 1,
    # "inhterit.aes = FALSE" is essential for this to plot, given global aesthetics
    inherit.aes = FALSE,
    family = "Arial") +
  
  # Wrap data by portion of day
  facet_wrap(~time_of_day) +
  
  # Draw compass rose
  geom_segment(data = compass_df, 
                # "inhterit.aes = FALSE" is essential for this to plot, given global aesthetics
               inherit.aes = FALSE,
               # The coordinates for the compass rose are set relative to an empirically chosen point in the upper-right
               # The size of the lines are scaled to an empirically determined amount (1/200th) for appearance
               aes(x = -122.624, y = 45.553,
                   xend = -122.624 + (x / 200),
                   yend = 45.553 + (y / 200),
                   color = hexcolor),
               size = 0,
               # Thin, long, closed arrowheads
               arrow = arrow(length = unit(0.1, "native"),
                             type = "closed",
                             angle = 8)) +
  # Off-White dot at center of compass rose, also obscures overlap of different colors
  geom_point(aes(x = -122.624, y = 45.553), size = 8, color = medbkgd) +
  
  # Set colors and text to mimic BIKETOWN branding
  theme(strip.background = element_rect(fill = darkgray),
        strip.text = element_text(color = bikeorange, face = "bold",
                                  size = 14, family = "Arial"),
        panel.border = element_rect(color = darkgray, fill = NA, size = 1),
        #plot.background = element_rect(fill = bikeorange), #This is a really cool variation, gives an orange hue to the whole plot
        plot.title = element_text(size = 38, hjust = 0.5,
                                  family = "Impact"),
        plot.subtitle = element_text(size = 12, family = "Arial",
                                     hjust = 0.5),
        plot.caption = element_text(size = 12, family = "Arial")) +
  
  # Title, subtitle, caption
  labs(title = "AVERAGE BIKETOWN TRIPS",
       subtitle = "Median trajectory of weekday trips (2016-2018)",
       caption = paste("Arrows represent median destination of 10 or more rides starting within a one-block radius (length of rides are 1/4 scale)",
                       "R & Rstudio, tidyverse & ggplot2, lubridate, ggmap & Stamen maps, ggrepel, extrafont, BIKETOWN system data",
                       "Kevin Watanabe-Smith for CascadiaRConf 2018 - github.com/WatanabeSmith/BIKETOWN_CascadiaR",
                       sep = "\n"))

# Saving image
ggsave("Biketown_trajectories_WatanabeSmith.png", height = 11.2, width = 15.4) # Size set as same ratio as 8.5 x 11

# Saving pdf
ggsave("Biketown_trajectories_WatanabeSmith.pdf", height = 11.2, width = 15.4, 
       # "device = cairo_pdf" fixes issue of fonts not appearing in PDF version
       device = cairo_pdf)

sessionInfo()
  

