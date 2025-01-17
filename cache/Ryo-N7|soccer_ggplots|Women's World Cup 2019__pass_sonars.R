## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)


## ----message=FALSE-------------------------------------------------------
library(soccermatics)
library(StatsBombR)
library(tidyverse)
library(ggsoccer)


## ------------------------------------------------------------------------
comps <- FreeCompetitions()

WC_Matches <- FreeMatches(43)

JPN_Matches <- WC_Matches %>% filter(home_team.home_team_id == 778 | away_team.away_team_id == 778)

jp_sen <- get.matchFree(JPN_Matches[1, ])

# need to clean player.name column due to non-ASCII characters
jp_col <- readRDS(file = "../data/jp_col.RDS")
jp_sen <- readRDS(file = "../data/jp_sen.RDS")
jp_pol <- readRDS(file = "../data/jp_pol.RDS")
jp_bel <- readRDS(file = "../data/jp_bel.RDS")
br_cr <- readRDS(file = "../data/br_cr.RDS")

# get all StatsBomb data
allinfo <- function(df) {
  lapply(1:nrow(df), function(i) {
    temp <- get.matchFree(df[i,])
    Sys.sleep(runif(1, 1, 2)) #be courteous!
    temp <- cleanlocations(temp)
    temp <- goalkeeperinfo(temp)
    temp <- shotinfo(temp)
    temp <- defensiveinfo(temp)
    return(temp)
  }) %>% 
    plyr::rbind.fill()
}

jp <- allinfo(jp_sen)




## ------------------------------------------------------------------------
comps


## ------------------------------------------------------------------------
comps %>% 
  filter(competition_id == 72)


all_free <- StatsBombFreeEvents(MatchesDF = 22961)

StatsBombR:::MatchesDF


wwc_matches <- FreeMatches(Competitions = 72)

jp_sco_id <- wwc_matches %>% filter(match_id == 22961)

jp_sco_raw <- get.matchFree(Match = jp_sco_id)

glimpse(jp_sco_raw)


## ------------------------------------------------------------------------
round.angle <- 15

jp_sco_pass_raw <- jp_sco_raw %>% 
  filter(type.name == "Pass",
         possession_team.name == "Japan Women's",
         !play_pattern.name %in% c("From Corner", "From Free Kick",
                                   "From Throw In")) %>% 
  mutate(angle_round = round(pass.angle * 180 / pi / round.angle) *
           round.angle)



sonar_df <- jp_sco_pass_raw %>% 
  add_count(player.name, team.name, name = "pass_n") %>% 
  add_count(player.name, team.name, angle_round, name = "angle_n") %>% 
  group_by(player.name, team.name) %>% 
  mutate(max_n = max(angle_n),
         angle_norm = angle_n / max_n) %>% 
  ungroup() %>% 
  group_by(angle_round, player.name, team.name, pass_n) %>% 
  summarize(angle_norm = mean(angle_norm),
            distance = mean(pass.length),
            distance = if_else(distance > 30, 30, distance))
  


## ------------------------------------------------------------------------
jugadores <- unique(sonar_df$player.name)


## ------------------------------------------------------------------------

sonar_df %>% 
  filter(player.name == jugadores[14]) %>% 
  ggplot() + 
  geom_bar(aes(x = angle_round, y = angle_norm, fill = distance),
           stat = "identity") +
  scale_y_continuous(limits = c(0, 1))+
  scale_x_continuous(breaks = seq(-180, 180, by = 90), 
                     limits = c(-180, 180)) +
  coord_polar(start = pi, direction = 1) +
  #RColorBrewer::brewer.pal.info
  colorspace::scale_fill_continuous_sequential(palette = "Blues", rev = TRUE) +
  # viridis::scale_fill_viridis("Distance (yards)", limits = c(0, 30),
  #                    na.value = "#FDE725FF") +
  labs(x = '', y = '', title = jugadores[14]) +
  theme_void()+
  theme(plot.title = element_text(hjust = 0.5),
        #legend.position = "none", #uncomment to remove colorbar
        plot.background = element_rect(fill = "transparent", colour = NA),
        panel.background = element_rect(fill = "transparent", colour = NA))


## ------------------------------------------------------------------------
createPitch <- function(xmax=115, ymax=80, grass_colour="white", line_colour="gray", background_colour="white", goal_colour="gray", data=NULL, halfPitch=FALSE){
  
  GoalWidth <- 8
  penspot <- 12
  boxedgeW <- 44
  boxedgeL <- 18
  box6yardW <- 20
  box6yardL <- 6
  corner_d=3
  centreCirle_d <- 20
  
  # The 18 Yard Box
  TheBoxWidth <- c(((ymax / 2) + (boxedgeW / 2)),((ymax / 2) - (boxedgeW / 2)))
  TheBoxHeight <- c(boxedgeL,xmax-boxedgeL)
  GoalPosts <- c(((ymax / 2) + (GoalWidth / 2)),((ymax / 2) - (GoalWidth / 2)))
  
  # The 6 Yard Box
  box6yardWidth <- c(((ymax / 2) + (box6yardW / 2)),((ymax / 2) - (box6yardW / 2)))
  box6yardHeight <- c(box6yardL,xmax-box6yardL)
  
  ## define the circle function
  circleFun <- function(center = c(0,0),diameter = 1, npoints = 100){
    r = diameter / 2
    tt <- seq(0,2*pi,length.out = npoints)
    xx <- center[1] + r * cos(tt)
    yy <- center[2] + r * sin(tt)
    return(data.frame(x = xx, y = yy))
  }
  
  #### create leftD arc ####
  Dleft <- circleFun(c((penspot),(ymax/2)),centreCirle_d,npoints = 1000)
  ## remove part that is in the box
  Dleft <- Dleft[which(Dleft$x >= (boxedgeL)),]
  
  ## create rightD arc  ####
  Dright <- circleFun(c((xmax-(penspot)),(ymax/2)),centreCirle_d,npoints = 1000)
  ## remove part that is in the box
  Dright <- Dright[which(Dright$x <= (xmax-(boxedgeL))),]
  
  #### create center circle ####
  center_circle <- circleFun(c((xmax/2),(ymax/2)),centreCirle_d,npoints = 2000)
  
  
  if (halfPitch==FALSE){
    xmin=0
    ymin=0
    
    ## create corner flag radius ####
    TopLeftCorner <- circleFun(c(xmin,ymax),corner_d,npoints = 1000)
    TopLeftCorner <- TopLeftCorner[which(TopLeftCorner$x > (xmin)),]
    TopLeftCorner <- TopLeftCorner[which(TopLeftCorner$y < (ymax)),]
    TopRightCorner <- circleFun(c(xmax,ymax),corner_d,npoints = 1000)
    TopRightCorner <- TopRightCorner[which(TopRightCorner$x < (xmax)),]
    TopRightCorner <- TopRightCorner[which(TopRightCorner$y < (ymax)),]
    
    BottomLeftCorner <- circleFun(c(xmin,ymin),corner_d,npoints = 1000)
    BottomLeftCorner <- BottomLeftCorner[which(BottomLeftCorner$x > (xmin)),]
    BottomLeftCorner <- BottomLeftCorner[which(BottomLeftCorner$y > (ymin)),]
    
    BottomRightCorner <- circleFun(c(xmax,ymin),corner_d,npoints = 1000)
    BottomRightCorner <- BottomRightCorner[which(BottomRightCorner$x < (xmax)),]
    BottomRightCorner <- BottomRightCorner[which(BottomRightCorner$y > (ymin)),]
    
    
    
    ggplot(data=data) + #xlim(c(ymin,ymax)) + ylim(c(xmin,xmax)) +
      # add the theme 
      #theme_blankPitch() +
      # add the base rectangle of the pitch 
      geom_rect(aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax), fill = grass_colour, colour = line_colour)+

      # add the 18 yard box Left
      geom_rect(aes(xmin=0, xmax=TheBoxHeight[1], ymin=TheBoxWidth[1], ymax=TheBoxWidth[2]), fill = grass_colour, colour = line_colour) + 
      # add the 18 yard box Right
      geom_rect(aes(xmin=TheBoxHeight[2], xmax=xmax, ymin=TheBoxWidth[1], ymax=TheBoxWidth[2]), fill = grass_colour, colour = line_colour) +
      # add the six yard box Left
      geom_rect(aes(xmin=0, xmax=box6yardHeight[1], ymin=box6yardWidth[1], ymax=box6yardWidth[2]), fill = grass_colour, colour = line_colour)  +
      # add the six yard box Right
      geom_rect(aes(xmin=box6yardHeight[2], xmax=xmax, ymin=box6yardWidth[1], ymax=box6yardWidth[2]), fill = grass_colour, colour = line_colour)  + 
      # Add half way line 
      geom_segment(aes(x = xmax/2, y = ymin, xend = xmax/2, yend = ymax),colour = line_colour) +
      # add left D 
      geom_path(data=Dleft, aes(x=x,y=y), colour = line_colour) + 
      # add Right D 
      geom_path(data=Dright, aes(x=x,y=y), colour = line_colour) +
      # add centre circle 
      geom_path(data=center_circle, aes(x=x,y=y), colour = line_colour) +
      
      # add penalty spot left 
      geom_point(aes(x = penspot , y = ymax/2), colour = line_colour) + 
      # add penalty spot right
      geom_point(aes(x = (xmax-(penspot)) , y = ymax/2), colour = line_colour) + 
      # add centre spot 
      geom_point(aes(x = (xmax/2) , y = ymax/2), colour = line_colour) +
      # add Corner Flag corners
      geom_path(data=TopLeftCorner, aes(x=x,y=y), colour = line_colour) +
      geom_path(data=TopRightCorner, aes(x=x,y=y), colour = line_colour) +
      geom_path(data=BottomLeftCorner, aes(x=x,y=y), colour = line_colour) +
      geom_path(data=BottomRightCorner, aes(x=x,y=y), colour = line_colour) +
      geom_segment(aes(x = xmin-0.2, y = GoalPosts[1], xend = xmin-0.2, yend = GoalPosts[2]),colour = goal_colour, size = 1) +
      # add the goal right
      geom_segment(aes(x = xmax+0.2, y = GoalPosts[1], xend = xmax+0.2, yend = GoalPosts[2]),colour = goal_colour, size = 1) +
      
      coord_fixed() +
      theme(rect = element_blank(),#, #remove additional ggplot2 features: lines, axis, etc...
            line = element_blank(), 
            #legend.position = "none",
            axis.title.y = element_blank(),
            axis.title.x = element_blank(),
            axis.text.x = element_blank(),
            axis.text.y = element_blank())
}
  
  else{
    xmin=(xmax/2)
    ymin=0
    center_circle = center_circle[which(center_circle$x>=xmin),]
    
    ## create corner flag radius ####
    BottomRightCorner <- circleFun(c(xmax,ymin),corner_d,npoints = 1000)
    BottomRightCorner <- BottomRightCorner[which(BottomRightCorner$x < (xmax)),]
    BottomRightCorner <- BottomRightCorner[which(BottomRightCorner$y > (ymin)),]
    TopRightCorner <- circleFun(c(xmax,ymax),corner_d,npoints = 1000)
    TopRightCorner <- TopRightCorner[which(TopRightCorner$x < (xmax)),]
    TopRightCorner <- TopRightCorner[which(TopRightCorner$y < (ymax)),]
    
    ggplot(data=data) + #xlim(c(ymin,ymax)) + ylim(c(xmin,xmax)) +
      # add the theme 
      #theme_blankPitch() +
      # add the base rectangle of the pitch 
      geom_rect(aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax), fill = grass_colour, colour = line_colour)+ 
      # add the 18 yard box offensive
      geom_rect(aes(xmin=TheBoxHeight[2], xmax=xmax, ymin=TheBoxWidth[1], ymax=TheBoxWidth[2]), fill = grass_colour, colour = line_colour)+ 
      # add the six yard box offensive
      geom_rect(aes(xmin=box6yardHeight[2], xmax=xmax, ymin=box6yardWidth[1], ymax=box6yardWidth[2]), fill = grass_colour, colour = line_colour)+  
      # add the arc circle 
      geom_path(data=Dright, aes(x=x,y=y), colour = line_colour)+
      #add center arc
      geom_path(data=center_circle, aes(x=x,y=y), colour = line_colour)+
      # add penalty spot 
      
      geom_point(aes(x = (xmax-(penspot)) , y = ymax/2), colour = line_colour) +
      # add centre spot 
      geom_point(aes(x = (xmax/2) , y = ymax/2), colour = line_colour) +
      #geom_point(aes(x = CentreSpot , y = penSpotOff), colour = line_colour) +
      # add Corner Flag corners
      geom_path(data=BottomRightCorner, aes(x=x,y=y), colour = line_colour) +
      geom_path(data=TopRightCorner, aes(x=x,y=y), colour = line_colour) +

      
      # add the goal right
      geom_segment(aes(x = xmax+0.2, y = GoalPosts[1], xend = xmax+0.2, yend = GoalPosts[2]),colour = goal_colour, size = 1) +
      # add the goal offensive
      
    
    coord_fixed() +
      theme(rect = element_blank(), #remove additional ggplot2 features: lines, axis, etc...
            line = element_blank(), 
            #legend.position = "none",
            axis.title.y = element_blank(), 
            axis.title.x = element_blank(),
            axis.text.x = element_blank(),
            axis.text.y = element_blank())
  }
  
  
  
}


## ------------------------------------------------------------------------
#Plotting on top of a field by a team's formation
#The trick is to save each players PassSonar as a grob into a list. Then using
#annotation_custom() each PassSonar is placed in the correct position on the pitch
#It takes some trial and error to get the PassSonars into the correct position

text_color="black"
background_color="white"
radar.size=27
ymax=80
xmax=120

team.select="Japan Women's"
match.select=22961

game.lineup = jp_sco_raw %>% 
  filter(team.name == team.select, type.name == 'Starting XI', 
         match_id == match.select)

game.players = game.lineup$tactics.lineup[[1]][["player.name"]]
team.formation = game.lineup$tactics.formation
#game.lineup$tactics.lineup[[1]][["position.name"]]  #uncomment to view positions to help place into correct locations of field

player.plots <- list()

for (i in 1:length(game.players)){
  
  plot.data <- sonar_df %>% 
    filter(team.name == team.select & 
             player.name == game.players[i])
  
  player.plots[[i]] <- ggplot(plot.data) + 
    geom_bar(aes(x = angle_round, y = angle_norm, fill = distance), 
             stat="identity") +
    scale_y_continuous(limits = c(0, 1)) +
    scale_x_continuous(breaks = seq(-180, 180, by = 90), 
                       limits = c(-180, 180)) +
    coord_polar(start = pi, direction = 1) +
    viridis::scale_fill_viridis("Distance (yards)", 
                                limits = c(0, 30), na.value = "#FDE725FF") +
    labs(x = '', y = '', title = plot.data$player.name[1]) +
    theme_void() +
    theme(plot.title = element_text(hjust = 0.5, color = text_color),
          plot.background = element_rect(fill = "transparent", colour = NA),
          panel.background = element_rect(fill = "transparent", colour = NA),
          legend.position = "none")
  
  player.plots[[i]] <- ggplotGrob(player.plots[[i]])
  
  if (i == length(game.players)){
    colorbar <- ggplot(plot.data) + 
      geom_bar(aes(x = angle_round, y = angle_norm, fill = distance), 
               stat = "identity") +
      scale_y_continuous(limits = c(0, 0)) +
      viridis::scale_fill_viridis("", limits = c(0, 30), 
                                  na.value = "#FDE725FF")+
      labs(x = '', y = '')+
      theme_void()+
      theme(legend.position = "bottom",
            plot.background = element_rect(fill = "transparent", colour = NA),
            panel.background = element_rect(fill = "transparent", colour = NA))
    
    colorbar <- ggplotGrob(colorbar)
  }
}

#this is a 4-4-2 example. Use similar methods for other formations

if (team.formation == 442){
  team.formation <- '4-4-2'
  
  back.line <- 20
  mid.line <- 48
  forward.line <- 77
  
  p <- createPitch(grass_colour = background_color, 
                   goal_colour = text_colour, 
                   line_colour = text.color) + 
    coord_flip(ylim = c(0, 80))+
    theme(aspect.ratio = 120 / 80, 
          plot.title = element_text(size = 18, 
                                    hjust = 0.5, vjust = -2, 
                                    color = text.color),
          plot.background = element_rect(fill = background_color, colour = NA),
          panel.background = element_rect(fill = background_color, colour = NA)) +
    annotation_custom(grob = player.plots[[1]], 
                      xmin = -9, xmax = -9 + radar.size, 
                      ymax = ymax / 2 + radar.size / 2 - 1.5,
                      y= ymax / 2 - radar.size / 2 - 1.5) + #GK
    annotation_custom(grob = player.plots[[2]], 
                      xmin = back.line+3, xmax = back.line + 3 + radar.size, 
                      ymax = ymax + 1, y = ymax - radar.size + 1) + #RB
    annotation_custom(grob = player.plots[[5]], 
                      xmin = back.line + 3, xmax = back.line + 3 + radar.size,
                      ymax= -3 + radar.size, y = -3) + #LB
    annotation_custom(grob = player.plots[[4]], 
                      xmin = back.line, xmax= back.line + radar.size,
                      ymax = ymax / 2 - 23.5 + radar.size, y = ymax / 2 - 23.5) + #LCB
    annotation_custom(grob = player.plots[[3]], 
                      xmin = back.line, xmax = back.line + radar.size,
                      ymax = ymax / 2 - 6 + radar.size, y = ymax / 2 - 6) + #RCB
    annotation_custom(grob = player.plots[[7]], 
                      xmin = mid.line, xmax = mid.line + radar.size,
                      ymax = ymax / 2 - 23.5 + radar.size, y = ymax / 2 - 23.5) + #LCM
    annotation_custom(grob = player.plots[[6]], 
                      xmin = mid.line, xmax = mid.line + radar.size,
                      ymax = ymax / 2 - 6 + radar.size, y = ymax / 2 - 6) + #RCM
    annotation_custom(grob = player.plots[[10]], 
                      xmin = forward.line, xmax = forward.line + radar.size,
                      ymax = ymax / 2 - 3 + radar.size, y = ymax / 2 - 3) + #RF
    annotation_custom(grob = player.plots[[11]], 
                      xmin = forward.line, xmax = forward.line + radar.size,
                      ymax = ymax / 2 - 26 + radar.size, y = ymax / 2 - 26) + #LF
    annotation_custom(grob = player.plots[[8]], 
                      xmin = mid.line + 5, xmax = mid.line + 5 + radar.size, 
                      ymax = ymax + 1, y = ymax - radar.size + 1) + #RM
    annotation_custom(grob = player.plots[[9]], 
                      xmin = mid.line + 5, xmax = mid.line + 5 + radar.size, 
                      ymax = -3 + radar.size, y = -3) + #LM
    annotation_custom(grob = colorbar, xmin = 3, xmax = 7, 
                      ymin = 1, ymax = 18)+
    annotate("text", label = "concept:@etmckinley\ndata:@StatsBomb", 
             x = 6, y = 79, hjust = 1, vjust = 1,
             size = 3.75, color = text.color) +
    annotate("text", label = "Mean Pass Distance (Yards)", 
             x = 9, y = 3, hjust = 0, 
             size = 3, color = text.color) +
    annotate("text", 
             label = 'Bar length = normalized pass angle frequency; Bar color = mean pass distance', 
             color = text.color, 
             x = -2, y = 79, 
             hjust = 1, size = 3)+
    annotate("text", 
             label = paste0('Starting Formation: ', team.formation), 
             color = text.color, 
             x = -2, y = 0, 
             hjust = 0, size = 5, fontface = "bold") +
    annotate("text", 
             label = paste0('PassSonar: ', team.select), 
             color = text.color, 
             x = 121.5, y = 0, hjust = 0, size = 9, fontface = "bold") +
    guides(fill = guide_colourbar())
  
}


## ------------------------------------------------------------------------
  team.formation <- '4-4-2'
  
  back.line <- 20
  mid.line <- 48
  forward.line <- 77


 plot.data <- sonar_df %>% 
    filter(team.name == team.select & 
             player.name == game.players[4])
  
  player.plots <- ggplot(plot.data) + 
    geom_bar(aes(x = angle_round, y = angle_norm, fill = distance), 
             stat="identity") +
    scale_y_continuous(limits = c(0, 1)) +
    scale_x_continuous(breaks = seq(-180, 180, by = 90), 
                       limits = c(-180, 180)) +
    coord_polar(start = pi, direction = 1) +
    viridis::scale_fill_viridis("Distance (yards)", 
                                limits = c(0, 30), na.value = "#FDE725FF") +
    labs(x = '', y = '', title = plot.data$player.name[4]) +
    theme_void() +
    theme(plot.title = element_text(hjust = 0.5, color = text_color),
          plot.background = element_rect(fill = "transparent", colour = NA),
          panel.background = element_rect(fill = "transparent", colour = NA),
          legend.position = "none")
  
  grobbo <- ggplotGrob(player.plots)


## ---- fig.height=6, fig.width=4------------------------------------------
ggplot() +
  annotate_pitch(dimensions = pitch_statsbomb) +
  theme_pitch() +
  coord_flip(xlim = c(0, 130),
             ylim = c(0, 80)) +
  theme(aspect.ratio = 120 / 80, 
          plot.title = element_text(size = 18, 
                                    hjust = 0.5, vjust = -2, 
                                    color = "black")) +
  annotation_custom(grob = grobbo, 
                      xmin = back.line+3, xmax = back.line + 3 + radar.size, 
                      ymax = ymax + 1, y = ymax - radar.size + 1)

