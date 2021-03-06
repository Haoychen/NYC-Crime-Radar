library(dplyr)
library(sp)
library(leaflet)
library(rgdal)

# Working directory is the "output" folder
# NYC bars and NYC crime data have been modified using QGIS
# so that each row has a corresponding Neighorhood Tabulation Area

# nyc_bars_nta.csv and crime15_nta.csv are data.frames converted from a SpatialPointsDataFrame I manipulated in QGIS
# I previously read the shapefiles directly into R but they're too large for GitHub
# nyc_bars <- read.csv("nyc_bars_nta.csv")
# crime15 <- read.csv("crime15_nta.csv")
# 
# # NYC Neighborhood Tabulation Areas read as SpatialPolygonsDataFrame
# nynta <- readOGR(dsn = "../data/nynta_15d", layer = "nynta_projected") 
# nynta <- spTransform(nynta, CRS("+proj=longlat +datum=WGS84")) # transform lat/lng for leaflet
# 
# # Population data per NTA read as .csv file
# pop_nta <- read.csv("../data/New_York_City_Population_by_Neighborhood_Tabulation_Areas.csv")
# pop_nta <- filter(pop_nta, Year == 2010, Population != 0)

load("crime15.RData")
load("nynta.RData")
load("pop_nta.RData")
load("nyc_bars_clean.RData")

nyc_bars<-as.data.frame(nyc_bars)
nyc_bars$Doing.Busi<-as.character(nyc_bars$Doing.Busi)
nyc_bars$Actual.Add<-as.character(nyc_bars$Actual.Add)

# compute # of bars per 1000 population per NTA
bar_density <- group_by(nyc_bars, NTACode) %>% 
               summarize(num_bars = n()) %>% 
               inner_join(pop_nta, by = c("NTACode" = "NTA.Code")) %>% 
               mutate(bar_density_per_1K = num_bars / (Population / 1000)) %>%
               arrange(NTACode)

# # compute # of crimes per 1000 population per NTA
# crime_density <- group_by(crime15, NTACode) %>%
#                  summarize(num_crimes = n()) %>%
#                  inner_join(pop_nta, by = c("NTACode" = "NTA.Code")) %>%
#                  mutate(crime_density_per_1K = num_crimes / (Population / 1000)) %>%
#                  arrange(NTACode)

# subset polygons to include only those in bar_density
# dplyr functions don't work on objects of class Spatial*
nynta_bar <- subset(nynta, NTACode %in% bar_density$NTACode)
nynta_bar <- nynta_bar[order(nynta_bar$NTACode), ]
nynta_bar <- cbind(nynta_bar, bar_density$bar_density_per_1K)
names(nynta_bar)[8] <- "bar_density_per_1K"

save(nynta_bar,file="nynta_bar.Rdata")
nynta_bar<-0
load("nynta_bar.RData")
# # subset polygons to include only those in crime_density
# nynta_crime <- subset(nynta, NTACode %in% crime_density$NTACode)
# nynta_crime <- nynta_crime[order(nynta_crime$NTACode), ]
# nynta_crime <- cbind(nynta_crime, crime_density$crime_density_per_1K)
# names(nynta_crime)[8] <- "crime_density_per_1K"

# choropleth map of bar density per 1K, equal quantiles (7 divisions), superimposed onto street basemap
pal_bar <- colorQuantile(palette = "Purples", domain = nynta_bar$bar_density_per_1K, n = 7)
leaflet() %>% addProviderTiles("CartoDB.Positron") %>% 
              addPolygons(data = nynta_bar, weight = 2, fillOpacity = 0.7, color = ~pal_bar(bar_density_per_1K))

# # choropleth map of crime density per 1K, equal quantiles (7 divisions), superimposed onto street basemap
# pal_crime <- colorQuantile(palette = "Reds", domain = nynta_crime$crime_density_per_1K, n = 7)
# leaflet() %>% addProviderTiles("CartoDB.Positron") %>%
#               addPolygons(data = nynta_crime, weight = 2, fillOpacity = 0.7, color = ~pal_crime(crime_density_per_1K),
#                           popup = nynta_crime$NTAName)
