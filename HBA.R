#Data is from Community Development Manager's files.
#Data is received and updated quarterly

setwd("U:/CityWide Performance/CovStat/CovStat Projects/Development/Community Development/HBA")

library("xlsx")
library("plyr")
library("dplyr")
library("tidyr")
library("reshape")
library("reshape2")
library("stringr")
library("arcgisbinding")
library("sp")
library("spdep")
library("rgdal")
library("maptools")
library("ggmap")
#######################
## Program Year 2016 ##
#######################
### Read in Covington HBA sheets
hba2016DATA <- "U:/CityWide Performance/CovStat/CovStat Projects/Development/Community Development/HBA/PY 2016 HOME-CDBG Program databases- updated for 2nd quarter.xlsx"
hba2016COV <- read.xlsx(hba2016DATA, sheetIndex = "PY 2016 Cov HBA", startRow = 21, endRow = 79, as.data.frame = TRUE, header = TRUE)

hba2016COV$City <- "Covington"
hba2016COV$PY <- "2016"

### Read in other home consortium cities 
hba2016 <- read.xlsx(hba2016DATA, sheetIndex = "PY 2016 NKY Cons HBA", startRow = 21, endRow = 44, as.data.frame = TRUE, header = TRUE)
hba2016$PY <- "2016"

## bind covington and other cities files by column names
fy16hba <- do.call("rbind", list(hba2016, hba2016COV))

#######################
## Program Year 2015 ##
#######################
### Read in Covington HBA sheets
hba2015DATA <- "U:/CityWide Performance/CovStat/CovStat Projects/Development/Community Development/HBA/PY 2015 HOME-CDBG Program databases.xlsx"
hba2015COV <- read.xlsx(hba2015DATA, sheetIndex = "PY 2015 Cov HBA", startRow = 21, endRow = 95, as.data.frame = TRUE, header = TRUE)
hba2015COV$City <- "Covington"
hba2015COV$PY <- "2015"

### Read in other home consortium cities 
hba2015 <- read.xlsx(hba2015DATA, sheetIndex = "PY 2015 NKY Cons HBA", startRow = 21, endRow = 61, as.data.frame = TRUE, header = TRUE)
hba2015$PY <- "2015"


## bind covington and other cities files by column names
fy15hba <- do.call("rbind", list(hba2015, hba2015COV))
fy15hba$Source.of.Referral <- ""

#######################
## Program Year 2014 ##
#######################
### Read in Covington HBA sheets
hba2014DATA <- "U:/CityWide Performance/CovStat/CovStat Projects/Development/Community Development/HBA/PY 2014 Covington Homebuyer Assistance Database.xlsx"
hba2014COV <- read.xlsx(hba2014DATA, sheetIndex = "PY 2014 Cov HBA list", startRow = 18, endRow = 62, colIndex = 1:26, as.data.frame = TRUE, header = TRUE)
hba2014COV$City <- "Covington"
hba2014COV$PY <- "2014"
hba2014COV <- hba2014COV[, c(-6, -15:-16)]
#hba2014$Source.of.Referral <- ""

### Read in other home consortium cities 
hba2014DATA_NKY <- "U:/CityWide Performance/CovStat/CovStat Projects/Development/Community Development/HBA/PY 2014 NKY HOME HBA Database.xlsx"
hba2014 <- read.xlsx(hba2014DATA_NKY, sheetIndex = "NKY HOME Consortium", startRow = 16, endRow = 46, colIndex = 1:24, as.data.frame = TRUE, header = TRUE)
hba2014$PY <- "2014"
hba2014 <- plyr::rename(hba2014, c("HOME.Funds.to.Buyer"="HOME..Funds.to.Buyer", 
                                   "Staff.Hours....J..Hammons"="Staff.Hours.....J..Hammons",
                                   "Staff.Hours......J..Wallace"="Staff.Hours.....J..Wallace"))

## bind covington and other cities files by column names
fy14hba <- do.call("rbind", list(hba2014, hba2014COV))
fy14hba$Source.of.Referral <- ""

## Combined files across program years by column names
hba_loans <- do.call("rbind", list(fy16hba, fy15hba, fy14hba))

## Add two columns to use for getting lat/long coordinates
hba_loans <- within(hba_loans, {
  State <- "KY"
  Locations <- paste(Property.Address, City, State)})

## Get lat/long coordinates for location
coordinates <- geocode(hba_loans$Locations)
hba_loans <- cbind(hba_loans, coordinates)

hba_loans$lat[grepl("NA", x = hba_loans$Locations)]<- NA
hba_loans$lon[grepl("NA", x = hba_loans$Locations)] <- NA

hba_loans$lat[which(is.na(hba_loans$lat))] <- 0
hba_loans$lon[which(is.na(hba_loans$lon))] <- 0

###########################
## Spatial Data Creation ##
###########################

#### Create Spatial Points Data.Frame from Lat/Long Coordinates
hba_loansSP <- hba_loans
coordinates(hba_loansSP) <- ~lon+lat

### Define Coordinate system for spatial points data.frame
reference <- CRS("+init=epsg:4326")
proj4string(hba_loansSP) <- reference

#### Write spatial points data.frame to a shapefile
writeOGR(obj = hba_loansSP, dsn ="C:/Users/tsink/Mapping/Geocoding/Development/Community Development", 
         layer = "HBA_Loans", driver = 'ESRI Shapefile', overwrite_layer = TRUE)

#####################
##Connect to ArcGIS##
#####################

#### Initialize arcgisbinding ####
arc.check_product()

#### Read GIS Features ####
readGIS<- arc.open("C:/Users/tsink/Mapping/Geocoding/Development/Community Development/Join_Output.shp")

#### Create Data.Frame ####
hba_loansSP_GIS <- arc.select(readGIS)

#bind hidden lat/long coordinates back to data frame
shape <- arc.shape(hba_loansSP_GIS)
hba_loansSP_GIS<- data.frame(hba_loansSP_GIS, long=shape$x, lat=shape$y)

#################################################################################
## save the spatial file to another object to be able to remove underling FIDs. #
## use hba_loansSP_GIS that retains spatial reference to load into arcgis  ######
#################################################################################
hba_loans_END <- hba_loansSP_GIS

## Remove the cumulative coumns from Jeremy's files and spatial geometry fields
hba_loans_END <- hba_loans_END[, c(-1:-3, -12:-13, -22:-27, -31:-34, -36:-45)]

## rename columns
names(hba_loans_END)[1] <- 'Referral Source'
names(hba_loans_END)[2] <- 'City Closing Date'
names(hba_loans_END)[3] <- 'Name'
names(hba_loans_END)[4] <- 'Address'
names(hba_loans_END)[7] <- 'Status'
names(hba_loans_END)[8] <- 'Disbursed Funds'
names(hba_loans_END)[9] <- 'HOME Funds to Project'
names(hba_loans_END)[10] <- 'Mortgage Amount'
names(hba_loans_END)[11] <- 'Purchase Price'
names(hba_loans_END)[12] <- 'Loan Type'
names(hba_loans_END)[16] <- 'AMI'
names(hba_loans_END)[20] <- 'Neighborhood'

hba_loans_END$Count <- 1

#############################
## Write files for storage ##
#############################
library("RSQLite")
cons.development <- dbConnect(drv=RSQLite::SQLite(), dbname="O:/AllUsers/CovStat/Data Portal/repository/Data/Database Files/Development.db")
dbWriteTable(cons.development, "HBA_Loans", hba_loans_END, overwrite = TRUE)
dbDisconnect(cons.development)

#####################################
## Write files for Data Repository ##
#####################################
write.csv(hba_loans_END, "O:/AllUsers/CovStat/Data Portal/Repository/Data/Development/CommunityDevelopment/HBA_Loans.csv",
          row.names = FALSE)

#####################################
## Write files for Tableau ##
#####################################
write.csv(hba_loans_END, "U:/CityWide Performance/CovStat/CovStat Projects/Development/Community Development/Tableau Files/HBA_Loans.csv",
          row.names = FALSE)



