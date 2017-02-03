# Data is extracted from Kenton County dispatch report server once a month.
# Data is pulled from CovPD Admin Reports > 24 Hours Shift Report CSV

setwd("U:/CityWide Performance/CovStat/CovStat Projects/Development/Parks_Recreation/ParkSafety")

library("xlsx")
library("plyr")
library("dplyr")
library("tidyr")
library("splitstackshape")
library("magrittr")
library("gmodels")
library("descr")
library("zoo")
library("arcgisbinding")
library("sp")
library("spdep")
library("rgdal")
library("maptools")
library("ggmap")
library("RSQLite")

## In ArcGIS, select police calls that are inside and within 100 feet of ParksOpenSpaces
## then join ParksOpenSpaces to the police calls points layer
## Name the final police calls points layer for the update 'safety2'

#####################
##Connect to ArcGIS##
#####################

#### Initialize arcgisbinding -----------------
arc.check_product()

#### Read GIS Features ----------------
readGIS<- arc.open("C:/Users/tsink/Mapping/Geocoding/Recreation/safety2.shp")

#### Create Data.Frame ---------------
safety <- arc.select(readGIS)

## Columsn to keep and 'Park' as name of column
safety<- safety[, c(-1:-4, -15:-18, -20:-32, -35:-41, -43:-45)] 
names(safety)[14] <- "Park"
safety_CFS <- safety[which(safety$Category == "Calls for Service"),]

### Function to assign safety ##
park_safety <- function(x = safety_CFS$Incident_T){
  
  #Create objects and store the data frame vector that contains the call type keys
  CFS <- key_safety$x
  
  #create an object and store a condition that tests if each call type in the police.runs file
  #matches the call type in the key
  match_cfs_safety <- safety_CFS$Incident_T %in% CFS
 
  #Create a new column that assigns a category designation to each row where the call type matches the key
  x[match_cfs_safety] <- "Safety"
   
  #Keep only calls designated as park safety calls
  safety_CFS <- subset(safety_CFS, Safety == "Safety")
}
safety_CFS <- park_safety()

#########################
####  SQLite storage ####
#########################
library("RSQLite")
cons.development <- dbConnect(drv=RSQLite::SQLite(), dbname="O:/AllUsers/CovStat/Data Portal/repository/Data/Database Files/Development.db")
dbWriteTable(cons.development, "ParkSafety", safety_CFS, overwrite = TRUE)
dbDisconnect(cons.development)

## Write for CovStat Data Repository ----------
write.csv(safety_CFS, file="O:/AllUsers/CovStat/Data Portal/Repository/Data/Development/ParksRecreation/ParkSafety.csv",
          row.names = FALSE)


## Write for Tableau Dashboard ----------
write.csv(safety_CFS, file="U:/CityWide Performance/CovStat/CovStat Projects/Development/Tableau Files/ParkSafety.csv",
          row.names = FALSE)

### SQLite Retrieval ----------------------
#alltables <- dbListTables(cons.police)
#dash_runs <- dbGetQuery(cons.police, 'select * from ParkSafety')