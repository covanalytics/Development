
setwd("U:/CityWide Performance/CovStat/CovStat Projects/Development/Economic Development/Building_Permits")

library("xlsx")
library("plyr")
library("dplyr")
library("tidyr")
library("reshape")
library("reshape2")
library("stringr")
library("zoo")
library("ggmap")
library("arcgisbinding")
library("sp")
library("spdep")
library("rgdal")
library("maptools")
library("splitstackshape")
library("RSQLite")

#Load newest update from PDS
update <- read.csv("Update.csv",  header=TRUE, na.strings=c("", NA), stringsAsFactors = FALSE)

#Format value column to integer
update$Value <- as.integer(gsub("\\$|\\,|\\.\\d*", "", update$Value))

## Remove rows that are all NAs. CSV formatting might geenrate one of these-------
update <- update[complete.cases(update),]

#Within dataframe add new columns
update <- within(update, {
  State <- "KY"
  FullAddress <- paste(Address, Jurisdiction, State, sep = " ")
  Value <- as.numeric(Value)})


# Geocode location of permits
covstat_geocode <- function(df, address){
  coordinates <- geocode(address)
  df <- cbind(df, coordinates)
  
  # Add zero to NAs in lat and lon if geocode fails
    if(sum(is.na(df$lat > 0))){
      for (i in 1:length(df$lat)){
        if(is.na(df$lat[i]))
          df$lat[i] <- 0
      }
      for (i in 1:length(df$lon)){
        if(is.na(df$lon[i]))
          df$lon[i] <- 0
      }
    }
  df
}
update <- covstat_geocode(update, update$FullAddress)


#### Send to ArcGIS ####
send_arcgis <- function(dataframe, path, layerName){
  coordinates(dataframe) <- ~lon + lat
  ## Define Coordinate system for spatial points data.frame 
  reference <- CRS("+init=epsg:4326")
  proj4string(dataframe) <- reference
  ## Assign closest neighborhood and sector in ArcGIS
  writeOGR(obj = dataframe, dsn = path, layer = layerName, driver = 'ESRI Shapefile', overwrite_layer = TRUE)
}
send_arcgis(update, "C:/Users/tsink/Mapping/Geocoding/Permits", "BldgPermitUpdate")

#### Receive from ArcGIS ####
receive_arcgis <- function(fromPath) {
  arc.check_product()
  ## Read GIS Features 
  read <- arc.open(fromPath)
  ## Create Data.Frame from GIS data 
  dataframeName <- arc.select(read)
  ## Bind hidden lat/long coordinates back to data frame 
  shape <- arc.shape(dataframeName)
  dataframeName<- data.frame(dataframeName, long=shape$x, lat=shape$y)
}
BldPermitsGIS <- receive_arcgis("C:/Users/tsink/Mapping/Geocoding/Permits/BldPermitsUpdate.shp")


BldPermitsGIS <- BldPermitsGIS[, c(-1:-2, -12:-17, -19:-28)]
BldPermitsGIS$`Fiscal Year` <- "2017"
BldPermitsGIS <- BldPermitsGIS[, c(3, 1:2, 4, 13, 5:9, 11:12, 10 )]
names(BldPermitsGIS) <- c("PermitNumber", "Jurisdiction", "Address", "IssuedDate", "FiscalYear", "Owner",
                          "Type", "ApplicationDate", "Value", "Count", "lon", "lat", "Neighborhood")


###Looks like date is reformated after bring in from ArcGIS
##Need to format to match OpenGov formatting -------------------------------
#BldPermitsGIS$Issued__Da <- as.character(BldPermitsGIS$Issued__Da)
#BldPermitsGIS$Applicatio <- as.character(BldPermitsGIS$Applicatio)
#BldPermitsGIS$Issued__Da <- sub(" .*", "", BldPermitsGIS$Issued__Da)
#BldPermitsGIS$Applicatio <- sub(" .*", "", BldPermitsGIS$Applicatio)

#BldPermitsGIS$Issued__Da <- format(as.Date(BldPermitsGIS$Issued__Da), "%m-%d-%Y")
#BldPermitsGIS$Applicatio <- format(as.Date(BldPermitsGIS$Applicatio), "%m-%d-%Y")

###################################################################################################################
### change names of BldPermitGIS before storing in database on next update.  Delete after correction is made ------
# Crate a csv for source file for dashboard
#------------------------------------------------------------------------------------------------------------------

#### Write files ####

sql_write <- function(connection, dbName, dbGname, Rfile, dbPull, RepoPath, TablPath, ...) {
  #Database
  connection <- dbConnect(drv=RSQLite::SQLite(), dbname = dbName)
  dbWriteTable(connection, dbGname, Rfile, ...)
  #Pull entire database
  Rfile <- dbGetQuery(connection, dbPull)
  #CovStat Repository
  write.csv(Rfile, file=RepoPath, row.names = FALSE)
  #Tableau File
  write.csv(Rfile, file=TablPath, row.names = FALSE)
  dbDisconnect(connection)
}
connection <- cons.development
dbName <- "O:/AllUsers/CovStat/Data Portal/repository/Data/Database Files/Development.db"
dbPull <- 'select * from BuildingPermits'
RepoPath <- "O:/AllUsers/CovStat/Data Portal/Repository/Data/Development/EconomicDevelopment/BuildingPermits.csv"
TablPath <- "U:/CityWide Performance/CovStat/CovStat Projects/Development/Tableau Files/BuildingPermitsTableau.csv"
sql_write(connection, dbName , "BuildingPermits", Rfile = BldPermitsGIS, dbPull, RepoPath, TablPath, append = TRUE)

# Db pull if needed
#cons.development <- dbConnect(drv=RSQLite::SQLite(), "O:/AllUsers/CovStat/Data Portal/repository/Data/Database Files/Development.db")
#dash_bldPermits <- dbGetQuery(cons.development, 'select * from BuildingPermits')


## Columns to keep and names for OpenGov---------------------------
BldPermitsGIS <- BldPermitsGIS[, c(2, 3, 1, 4:5, 7:13)]
names(BldPermitsGIS) <- c("Jurisdiction", "Address", "Permit Number", "Issued Date", "Fiscal Year", "Type",
                          "Application Date", "Value", "Count", "lon", "lat", "Neighborhood")

## Write for OpenGov Update. Change file name for update -------------------------------------------
file_loc  <- "U:/CityWide Performance/CovStat/CovStat Projects/Development/Economic Development/Building_Permits/OpenGov/March2017.csv"
write.csv(BldPermitsGIS, file_loc, row.names = FALSE)


