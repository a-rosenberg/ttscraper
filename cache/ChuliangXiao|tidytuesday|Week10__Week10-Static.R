## ------------------------------------------------------------------------
library(tidyverse)
library(Hmisc)
library(lubridate)
library(ggmap)
library(patchwork)


## ------------------------------------------------------------------------
raw_df <- read_csv("../data/week10_biketown.csv")

library(glue)
trip_df<- raw_df %>% 
  filter(StartDate != "", StartTime != "") %>%
  mutate(StartDate = mdy(StartDate),
         EndDate = mdy(EndDate),
         Start = parse_date_time(glue("{StartDate} {StartTime}"), "Ymd HMS"),
         Hour = parse_factor(hour(Start), c(0, 23:1)),
         Weekday = fct_relevel(wday(Start, label = TRUE),
                               c("Mon","Tue","Wed","Thu","Fri","Sat","Sun")
                               ),
         Duration = hms::as.hms(round((EndTime - StartTime)))
         )


top_df <- trip_df %>% 
#  select(-TripType, -Duration, -StartHub, -EndHub) %>% 
#  drop_na() %>% 
  count(StartHub, StartLatitude,StartLongitude) %>% 
  arrange(desc(n)) %>% 
  top_n(148, n) 

trip_top <- trip_df %>% 
  filter(StartHub %in% top_df$StartHub)

ntrip    <- nrow(trip_top)
avgTime  <- mean(trip_top$Duration, na.rm = T) %>% 
  as.duration() %>% as.numeric("minutes") %>% round()

head_df <- top_n(top_df, 10)


## ------------------------------------------------------------------------
portland <- get_map(location = c(left = -122.75, 
                                 bottom = 45.47, 
                                 right = -122.55, 
                                 top = 45.57)
                    )
# Non-square (rectangular) maps in R-ggmap
# https://stackoverflow.com/q/31316076/9421451

p1 <- ggmap(portland) + 
  geom_point(data = top_df, 
             aes(x = StartLongitude, y = StartLatitude, size = n),
             color = "white", fill = "#f94d1f", shape = 21) + 
  scale_x_continuous(limits = c(-122.71, -122.63))+
  labs(title = "Starting Stations") + 
  theme_minimal() + 
  theme(axis.text = element_blank(),
        axis.title = element_blank(),
        legend.position = "none",
        plot.title = element_text(family = "Verdana Bold", size = 10),
        plot.margin = margin(0,0,0,0, "cm"))
p1  
#ggsave("map.png", p, width = 3, height = 6)


## ------------------------------------------------------------------------
p2 <- trip_df %>% 
  mutate(floor_week = floor_date(Start, "weeks")) %>% 
  count(floor_week, PaymentPlan) %>% 
  group_by(floor_week) %>% 
  mutate(nn = sum(n)) %>% 
  filter(PaymentPlan %in% "Subscriber") %>% 
  ggplot() + 
  geom_ribbon(aes(x = floor_week, ymin = 0, ymax = nn), 
              fill = "grey", color = "grey50") +
  geom_ribbon(aes(x = floor_week, ymin = 0, ymax = n),
              fill = "#f69366", color = "grey50") +
  scale_y_continuous(labels = glue("{seq(0,15,5)}K")) + 
  scale_x_datetime(date_labels = "%b %y", 
                   breaks = seq(as_datetime("2016-08-01"), 
                                as_datetime("2018-02-01"), "6 months")) + 
  labs(title = "Trips Per Week") + 
  theme_minimal() + 
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        axis.title = element_blank(),
        plot.title = element_text(family = "Verdana Bold", size = 10),
        axis.text = element_text(family = "Futura Medium", size = 10))


## ------------------------------------------------------------------------
d <- data.frame(x1 = c(0, 1.1), x2 = c(1, 2.1), y1 = c(0, 0), y2 = c(1, 1)/2,
                txt = c(paste0("Number of Trips\n", ntrip),
                        paste0("Average Trip Duration\n", avgTime, " minutes")
                        )
                )
p3 <- ggplot() + 
#  scale_x_continuous(name="x") + 
#  scale_y_continuous(name="y") +
  geom_rect(d, mapping = aes(xmin = x1, xmax = x2, ymin = y1, ymax = y2),
            fill = "white", color = "black", alpha = 0.5) +
  geom_text(d, mapping = aes(x = (x1+x2)/2, y = (y1+y2)/2, label = txt), size = 3) +
  coord_fixed()+
  theme_void()


## ------------------------------------------------------------------------
p4 <- trip_df %>% 
  count(Weekday, Hour) %>%
  filter(!Hour %in% c(1,2,3,4)) %>% 
  ggplot(aes(x = Weekday, y = Hour, fill = n)) + 
  geom_tile() +
  annotate("segment", y = 21, yend = 21, x = -Inf, xend = Inf,
           color = "black", size = .3) +
  annotate("segment", y = 0, yend = 0, x = -Inf, xend = Inf,
           color = "black", size = .3) +
  scale_x_discrete(position = "top") + 
  scale_y_discrete(labels = c("12 AM",glue("{c(11:1, 12)} PM"), glue("{11:5} AM"))) +
  scale_fill_gradient(low = "white", high = "#f94d1f") + 
  labs(title = "Trips per Weekday/Hour") + 
  theme_minimal() + 
  theme(legend.position = "none",
        axis.title = element_blank(),
        panel.grid = element_blank(), 
        axis.text.y = element_text(margin = margin(r = 0)),
        plot.title = element_text(family = "Verdana Bold", size = 10),
        axis.text = element_text(family = "Futura Medium"))


## ------------------------------------------------------------------------
pp <- p1 + 
  (p2 + p3 + p4 + plot_layout(ncol = 1, heights = c (3, 2, 7))) + 
  plot_layout(ncol = 2)
ggsave("Bike.png", pp)

