
setwd("U:/CityWide Performance/CovStat/CovStat Projects/Development/Public Improvements/Urban Forestry/WorkOrders")

library("xlsx")
library("plyr")
library("dplyr")
library("tidyr")
library("reshape")
library("reshape2")
library("stringr")
library("zoo")
library("lubridate")
library("readxl")

#Create a character vector of all EXCEL files
filenames <- list.files(pattern=".xls", full.names=T)

#Read the contents of all EXCEl worksheets into a data.frame
df.lists  <- lapply(filenames, function(x) read.xlsx(file=x, sheetIndex=1, startRow=8,  as.data.frame=TRUE, header=FALSE))

#Bind the rows of the data.frame lists created from the EXCEL sheets
worders  <- rbind.fill(df.lists)

## Remove rows with NAs
worders <- worders[!is.na(worders$X19) & !is.na(worders$X16),]

## Keep only needed columns
keeps <- names(worders) %in% c("X2", "X5", "X13", "X16", "X19")
worders <- worders[keeps]
names(worders)[1:5] <- c("Code", "Task", "Frequency", "Cost", "Month")

## change month to character for SQLite storage
worders$Month <- as.character(worders$Month)

######################
### SQLite Storage ###
######################
cons.development <- dbConnect(drv=RSQLite::SQLite(), dbname="O:/AllUsers/CovStat/Data Portal/repository/Data/Database Files/Development.db")
dbWriteTable(cons.development, "UForestry_WorkOrders", worders, overwrite = TRUE)
dbDisconnect(cons.development)

## Write for Tableau ##
write.csv(worders,"U:/CityWide Performance/CovStat/CovStat Projects/Development/Tableau Files/UF_W_orders.csv", row.names = FALSE)

## Write for CovStat ##
write.csv(worders, "O:/AllUsers/CovStat/Data Portal/Repository/Data/PublicImprovements/UrbanForestry/UF_Work_Orders.csv",
                     row.names = FALSE)