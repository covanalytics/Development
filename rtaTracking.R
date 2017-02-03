
setwd("U:/CityWide Performance/CovStat/CovStat Projects/Development/Section 8/RTA Tracking")

library("xlsx")
library("plyr")
library("dplyr")
library("tidyr")
library("reshape")
library("reshape2")
library("stringr")
library("zoo")
library("lubridate")
library("RSQLite")
library("ggmap")


rta <- read.csv("RTA Tracking(1.23.17).csv", header = FALSE,  stringsAsFactors = FALSE)

#Remove empty rows and columns at ends 
rta <- rta[c(-1:-2), c(-1, -12:-13)]


rta$V2[rta$V2==""] <- NA
rta <- subset(rta, !is.na(V2))

names(rta) <- c("Name", "Unit Address", "Rec'd RTA in Office", "Good Standing Review", 
                     "Forwarded to Service Rep", "Forwarded to Inspector", "1st Inspection Scheduled",
                     "Pass Date", "Lease Date", "Notes")



#Trim white space
rta$`Good Standing Review` <- trimws(rta$`Good Standing Review`, "both")

#Assign city designation based on blank good standing review cell
rta$City <- ifelse(rta$`Good Standing Review`== "", "no", "yes")

#rta$Name <- NULL

write.csv (rta, 'U:/CityWide Performance/CovStat/CovStat Projects/Development/Tableau Files/rtaTracking_tableau.csv', 
           row.names = FALSE)

#############
## Storage ##
#############
library("RSQLite")
cons.rta <- dbConnect(drv=RSQLite::SQLite(), dbname="O:/AllUsers/CovStat/Data Portal/repository/Data/Database Files/Section8.db")
dbWriteTable(cons.rta, "RTA", rta)
dbDisconnect(cons.rta)

