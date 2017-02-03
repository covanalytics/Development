
setwd("U:/Citywide Performance/Development/Section 8/For Reporting")

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

hcvp <- read.xlsx("participants.xlsx", sheetIndex = 1, startRow = 3, colIndex = 2:4, header = TRUE)

#hcvp$City <- ifelse(grepl("COVINGTON", hcvp$Address), "Covington", 
            # ifelse(grepl("INDEPENDENCE", hcvp$Address), "Independence",      
            # ifelse(grepl("CRESCENT SPRINGS", hcvp$Address), "Crescent Springs",      
            # ifelse(grepl("ERLANGER", hcvp$Address), "Erlanger", "Other"))))))

##Create new column for city name
hcvp$City[grepl("COVINGTON", hcvp$Address)] <- "Covington"
hcvp$City[grepl("INDEPENDENCE", hcvp$Address)] <- "Independence"            
hcvp$City[grepl("CRESCENT SPRINGS", hcvp$Address)] <- "Crescent Springs"
hcvp$City[grepl("ERLANGER", hcvp$Address)] <- "Erlanger"
hcvp$City[grepl("ELSMERE", hcvp$Address)] <- "Elsmere"
hcvp$City[grepl("FT. MITCHELL", hcvp$Address)] <- "Ft. Mitchell"
hcvp$City[grepl("TAYLOR MILL", hcvp$Address)] <- "Taylor Mill"
hcvp$City[grepl("PARK HILLS", hcvp$Address)] <- "Park Hills"
hcvp$City[grepl("LUDLOW", hcvp$Address)] <- "Ludlow"
hcvp$City[grepl("BROMLEY", hcvp$Address)] <- "Bromley"
hcvp$City[grepl("FLORENCE", hcvp$Address)] <- "Florence"
hcvp$City[grepl("FT. WRIGHT", hcvp$Address)] <- "Ft. Wright"
hcvp$City[grepl("EDGEWOOD", hcvp$Address)] <- "Edgewood"
hcvp$City[grepl("FT WRIGHT", hcvp$Address)] <- "Ft. Wright"
hcvp$City[grepl("RYLAND HEIGHTS", hcvp$Address)] <- "Ryland Heights"
hcvp$City[grepl("WALTON", hcvp$Address)] <- "Walton"
hcvp$City[grepl("MORNINGVIEW", hcvp$Address)] <- "Morningview"

##Add space after commas
hcvp$Address <- gsub(",", ", ", hcvp$Address)

##Revise highway avenue address for geocoding
hcvp$Address <- gsub("HWY AVE", "Highway Avenue", hcvp$Address)

##Geocode addresses using google maps API
hcvp.coordinates <- geocode(hcvp$Address)

##Bind coordinates column to dataframe
hcvp <- cbind(hcvp, hcvp.coordinates)

hcvp$Name <- NULL
##Drop lat and long generated from goolge api
hcvp <- hcvp[c(-4:-5)]

write.csv(hcvp, "C:/Users/tsink/Mapping/Geocoding/HousingVoucher/geocoded.10.27.2016.csv", row.names = FALSE)

####Add this chunk before geocoding in arcmap

##############################################
hcvp <- read.csv("U:/Citywide Performance/Development/Section 8/For Reporting/participants.csv")

hcvp$Street <- str_split_fixed(hcvp$Address, pattern = ', ',  n = 2)

write.csv(hcvp, "U:/Citywide Performance/Development/Section 8/For Reporting/participants.csv")










