
setwd("U:/CityWide Performance/CovStat/CovStat Projects/Development/Economic Development/Building_Permits")

library("xlsx")
library("plyr")
library("dplyr")
library("tidyr")
library("reshape")
library("reshape2")
library("stringr")
library("zoo")
library("lubridate")
library("ggmap")
library("arcgisbinding")
library("splitstackshape")

#Load newest update from PDS
update <- read.csv("January2017.csv", header=TRUE, na.strings=c("", NA), stringsAsFactors = FALSE)

## Remove rows that are all NAs. CSV formatting might geenrate one of these-------
update <- update[complete.cases(update),]

#Within dataframe add new columns
update <- within(update, {
  State <- "KY"
  FullAddress <- paste(Address, Jurisdiction, State, sep = " ")
  Value <- as.numeric(Value)})

#Geocode address against Google API
coordinates <- geocode(update$FullAddress)
update <- cbind(update, coordinates)

#For joining with geographic boundary layers to use in Tableau
write.csv(update, "C:/Users/tsink/Mapping/Geocoding/Permits/geocoded_2_2_2017.csv", row.names = FALSE)

###################################################
## Bring back from ArcGIS and format for OpenGov ##
###################################################
arc.check_product()

#### Read GIS Features ---------------------------------
readGIS<- arc.open("C:/Users/tsink/Mapping/Geocoding/Permits/BldPermitsUpdate.shp")

#### Create Data.Frame -----------------------------------
BldPermitsGIS <- arc.select(readGIS)

BldPermitsGIS <- BldPermitsGIS[, c(-1:-2, -7, -12:-13, -16:-19, -21:-30)]
BldPermitsGIS$`Fiscal Year` <- "2017"

###Looks like date is reformated after bring in from ArcGIS
##Need to format to match OpenGov formatting -------------------------------
BldPermitsGIS$Issued__Da <- as.character(BldPermitsGIS$Issued__Da)
BldPermitsGIS$Applicatio <- as.character(BldPermitsGIS$Applicatio)
BldPermitsGIS$Issued__Da <- sub(" .*", "", BldPermitsGIS$Issued__Da)
BldPermitsGIS$Applicatio <- sub(" .*", "", BldPermitsGIS$Applicatio)

BldPermitsGIS$Issued__Da <- format(as.Date(BldPermitsGIS$Issued__Da), "%m-%d-%Y")
BldPermitsGIS$Applicatio <- format(as.Date(BldPermitsGIS$Applicatio), "%m-%d-%Y")

###################################################################################################################
### change names of BldPermitGIS before storing in database on next update.  Delete after correction is made ------
# Crate a csv for source file for dashboard
#------------------------------------------------------------------------------------------------------------------

#########################
####  SQLite storage ####
#########################
library("RSQLite")
cons.development <- dbConnect(drv=RSQLite::SQLite(), dbname="O:/AllUsers/CovStat/Data Portal/repository/Data/Database Files/Development.db")
dbWriteTable(cons.development, "BuildingPermits", BldPermitsGIS, append = TRUE)

#Write to CovStat Data Repository --------------------------
write.csv(BldPermitsGIS, "O:/AllUsers/CovStat/Data Portal/Repository/Data/Development/EconomicDevelopment/BuildingPermits.csv", 
          row.names = FALSE)

## Tableau Dashboard. Pull database and refresh dashboard source ---------------------------
#alltables <- dbListTables(cons.police)
dash_bldPermits <- dbGetQuery(cons.development, 'select * from BuildingPermits')
dbDisconnect(cons.development)



## Columns to keep and names for OpenGov---------------------------
BldPermitsGIS <- BldPermitsGIS[, c(1:4, 12, 5:11)]
names(BldPermitsGIS) <- c("Jurisdiction", "Address", "Permit Number", "Issued Date", "Fiscal Year", "Type",
                          "Application Date", "Value", "Count", "lon", "lat", "Neighborhood")

## Write for OpenGov Update. Change file name for update -------------------------------------------
file_loc  <- "U:/CityWide Performance/CovStat/CovStat Projects/Development/Economic Development/Building_Permits/OpenGov/January2017.csv"
write.csv(BldPermitsGIS, file_loc, row.names = FALSE)


#bind hidden lat/long coordinates back to data frame
#shape <- arc.shape(policeGIS)
#policeGIS<- data.frame(policeGIS, long=shape$x, lat=shape$y)


