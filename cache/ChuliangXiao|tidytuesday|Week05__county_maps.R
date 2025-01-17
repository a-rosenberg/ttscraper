## ----message=FALSE, warning=FALSE, paged.print=FALSE---------------------
library(tidyverse)


## ----message=FALSE, warning=FALSE----------------------------------------
userPath <- .libPaths()[1]

Upper1 <- function(x){
  xsplit  <- str_split(x, " ")
  fun1    <- function(x) {
    substr(x, 1, 1) <- toupper(substr(x, 1, 1))
    x
    }
  
  sapply(lapply(xsplit, fun1), paste, collapse=" ")
}

# Test
#Upper1 ("new york")

cName0   <- read_delim(file = paste0(userPath, "/maps/mapdata/county-old.N"),
                      delim = "\t",
                      col_names = F) 


cName <- cName0 %>%
  mutate(X2 = as.integer(X2)) %>%
  rename(name =X1, number = X2)%>%
  separate(name, c("State", "County"), ",")%>%
  mutate(County = str_replace(County, "mc", "mc ")) %>%
  mutate(State = Upper1(State),
         County = Upper1(County)) %>%
  mutate(State = replace(State, State == "District Of Columbia", "District of Columbia")) %>%
  mutate(County = str_replace(County, "Mc ", "Mc")) %>%
  mutate(County = str_replace(County, "De ", "De")) %>%
  mutate(County = str_replace(County, "Du ", "Du")) %>%
  mutate(County = str_replace(County, "La ", "La")) %>%
  mutate(County = str_replace(County, "LaCrosse", "La Crosse")) %>%
  mutate(County = replace(County, State == "Texas" & County == "LaSalle", "La Salle")) %>%
  mutate(County = str_replace(County, "St ", "St. ")) %>%
  mutate(County = str_replace(County, "Ste ", "Ste. ")) %>%
  mutate(County = str_replace(County, " Of ", " of ")) %>%
  mutate(County = str_replace(County, " The ", " the ")) %>%
  mutate(County = str_replace(County, "Prince Georges", "Prince George's")) %>%
  mutate(County = str_replace(County, "St. Marys", "St. Mary's")) %>%
  mutate(County = str_replace(County, "Queen Annes", "Queen Anne's")) %>%
#  mutate(County = str_replace(County, "Dona Ana", "Doña Ana")) %>%
  mutate(County = str_replace(County, "Yellowstone National", "Yellowstone")) %>%
  mutate(County = str_replace(County, "Newport News", "Newport News city")) %>%
  mutate(County = str_replace(County, "Virginia Beach", "Virginia Beach city"))%>%
  mutate(County = replace(County, State == "Virginia" & County == "Norfolk", "Norfolk city"))%>%
  mutate(County = replace(County, State == "Virginia" & County == "Suffolk", "Suffolk city"))%>%
  mutate(County = replace(County, State == "Virginia" & County == "Hampton", "Hampton city"))%>% 
  mutate(County = replace(County, State == "Arizona" & County == "LaPaz", "La Paz"))%>%
  mutate(County = replace(County, State == "Colorado" & County == "LaPlata", "La Plata"))%>%
  mutate(County = replace(County, State == "Illinois" & County == "DeWitt", "De Witt"))%>%
  mutate(County = replace(County, State == "Indiana" & County == "Lagrange", "LaGrange"))%>%
  mutate(County = replace(County, State == "Iowa" & County == "Obrien", "O'Brien"))%>%
  mutate(County = replace(County, State == "Louisiana" & County == "DeSoto", "De Soto"))%>%
  mutate(County = str_replace(County, "King And Queen", "King and Queen"))%>%
  mutate(County = str_replace(County, "Lewis And Clark", "Lewis and Clark"))%>%
  mutate(County = str_replace(County, "Fond DuLac", "Fond du Lac"))%>%
  mutate(County = replace(County, 
                          State == "South Dakota" & County == "Shannon", 
                          "Oglala Lakota"))%>%
  mutate(County = replace(County, 
                          State == "District of Columbia" & County == "Washington", 
                          "District of Columbia"))%>%
  mutate(County = str_replace(County, "DeBaca", "De Baca"))%>%
  mutate(County = str_replace(County, "Miami-dade", "Miami-Dade"))%>%
  mutate(County = str_replace(County, "St. Louis City", "St. Louis"))%>%
  mutate(County = str_replace(County, "Baltimore City", "Baltimore"))%>%
  mutate(County = str_replace(County, "Lac Qui Parle", "Lac qui Parle"))%>%
  mutate(S.C = paste(State, County, sep = ",")) %>%
  select(S.C, number, -State, -County)

write_tsv(cName, paste0(userPath, "/maps/mapdata/county.N"), col_names = F)


## ----eval=FALSE, include=FALSE-------------------------------------------
## cName %>%
##   filter(grepl(" ", County))
## 
## cntyMiss %>%
##   filter(grepl(" ", County) & !grepl("st ", County)) %>% as.data.frame()
## 
## numASC1 <- dfASC %>%
##   group_by(State) %>%
##   filter(State == "New Mexico")
## numASC1$County[8]

