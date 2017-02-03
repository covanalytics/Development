

setwd("U:/CityWide Performance/Development/Parks_Recreation")

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
library("XLConnect")

#Load Pool Passes
pool16 <- read.xlsx2("Pool Passes 2016.xlsx", header=TRUE,  stringsAsFactors = FALSE, sheetIndex = 1)

#Within dataframe add new columns
pool16 <- within(pool16, {
  State <- "KY"
  FullAddress <- paste(Street, City, State, Zip, sep = " ")
  Registration <- paste(Registration.Number, Registration.Sub.Number, sep = "-")})

write.csv(pool16, "PoolPass16Geocode.csv", row.names = FALSE)

###########################
## Load daily log files ###
###########################

#load workbook
sheets <- loadWorkbook("2016 daily pool log.xlsx")

goebel <- read.xlsx("2016 daily pool log.xlsx", sheetName = "Goebel", as.data.frame = TRUE, header = TRUE, stringsAsFactors = FALSE)
goebel$Pool <- "Goebel"
randolph <- read.xlsx("2016 daily pool log.xlsx", sheetName = "Randolph", as.data.frame = TRUE, header = TRUE, stringsAsFactors = FALSE)
randolph$Pool <- "Randolph"
waterpark <- read.xlsx("2016 daily pool log.xlsx", sheetName = "Waterpark", as.data.frame = TRUE, header = TRUE, stringsAsFactors = FALSE)
waterpark$Pool <- "Waterpark"


#get sheet names
#sheet_names <- getSheets(sheets)
#names(sheet_names) <- sheet_names

#put sheets into a list of data frames
#sheet_list <- lapply(sheet_names, function(.sheet){readWorksheet(object=sheets, .sheet)})

#bind list of sheets together in a data frame and make a few changes for visulization
daily_log  <- do.call("rbind", list(goebel, randolph, waterpark))
daily_log <- daily_log[,c(-4)]
daily_log$Guest <- ifelse(is.na(daily_log$Guest), 0, 1)
daily_log$Number <- gsub(" ", "", daily_log$Number)

##########################
## Load Pool Passes ######
##########################

pool_passes <- read.xlsx2("Pool2016GeocodeExport.xlsx", sheetIndex = 1, as.data.frame = TRUE, header = TRUE, stringsAsFactors = FALSE)

pool_passes$Registration <- gsub(" ", "", pool_passes$Registration)
pool_passes$NbhdLabel[pool_passes$NbhdLabel == ""] <- "Unknown/Outside City"

# merge location of pass holder with usage data
pool_usage <- merge(x = daily_log, y = pool_passes, by.x = "Number", by.y = "Registration", all.x = TRUE)
pool_usage$RegisteredNumber <- ifelse(is.na(pool_usage$NbhdLabel),"Not Listed/Misspelled", "Listed")
pool_usage$NbhdLabel <- ifelse(is.na(pool_usage$NbhdLabel),"Not Listed/Misspelled", as.character(pool_usage$NbhdLabel))

write.csv(pool_usage, "PoolUsageTableau.csv", row.names = FALSE)




