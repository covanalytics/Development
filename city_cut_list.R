
library("xlsx")
library("plyr")
library("tidyverse")
library("readxl")


load_excel_sheet <- function(fileName, sheetName, ...){
  # load file
  outName <- read_excel(fileName, sheet = sheetName, col_names = TRUE)
  # remove rows with all NA
  outName <- outName[rowSums(is.na(outName)) < 10,]
  # remove columns with all NA
  outName <- outName[, colSums(is.na(outName)) < nrow(outName)]
}

#load the file
cut_list <- load_excel_sheet("O:/AllUsers/Vacant Property List/MasterVacantPropertyList.xlsx", "Property Listing")

# keeping only records that are on the cut list
cut_list <- subset(cut_list, `City Cut List` == "X")

# changing column to date format and creating current 
# date column that shows number of days between last visit and current date
cut_list$`Last Visited` <- as.Date(cut_list$`Last Visited`, format = "%Y/%m/%d")
cut_list$Time <- difftime(cut_list$CurrentDate, cut_list$`Last Visited`, units = "days")

# Write for Tableau
write.csv(cut_list, "U:/CityWide Performance/CovStat/CovStat Projects/Development/Tableau Files/CutList.csv",
          row.names = FALSE)

# -------------------------------------------------------------------------------------------------------

# Load files with days between cuts 
cut_date16 <- load_excel_sheet("I:/Property list Mike Yeager all files/Property Maintenance Charges 2016.xlsx", 
                             "Individual Grass Cuts 2016")

cut_date15 <- load_excel_sheet("I:/Property list Mike Yeager all files/Property Maintenance Charges 2015.xlsx", 
                               "Individual Grass Cuts 2015")

# Change cut date format class to be the needed format 
cut_date16$`CUT DATE` <- as.Date(cut_date16$`CUT DATE`, format = "%Y-%m-%d")
cut_date15$`CUT DATE` <- as.Date(cut_date15$`CUT DATE`, format = "%Y-%m-%d")

# Assign a PIDN group to those properties without a listed PIDN 
cut_date16$PIDN[(cut_date16$STREET == "ALTAMONT RD") & is.na(cut_date16$PIDN)] <- "NO PIDN1"
cut_date16$PIDN[(cut_date16$STREET == "12TH ST E") & is.na(cut_date16$PIDN)] <- "NO PIDN2"
cut_date16$PIDN[(cut_date16$STREET == "16TH ST E") & is.na(cut_date16$PIDN)] <- "NO PIDN3"

# Calculate days between cuts for 2016 and 2015
cut16 <- cut_date16 %>%
  arrange(PIDN, `CUT DATE`)%>%
  group_by(PIDN) %>%
  mutate(day_gap = round(c(NA, diff(`CUT DATE`)), 1), Year = "2016")
  

cut15 <- cut_date15 %>%
  arrange(PIDN, `CUT DATE`)%>%
  group_by(PIDN) %>%
  mutate(day_gap = round(c(NA, diff(`CUT DATE`)), 1), Year = "2015")
  
# Combine dataframes
cuts_all <- rbind(cut15, cut16)

# Pull PIDN shapefile with Neighborhods ------------------------
receive_arcgis <- function(fromPath) {
  arc.check_product()
  ## Read GIS Features 
  read <- arc.open(fromPath)
  ## Create Data.Frame from GIS data 
  dataframeName <- arc.select(read)
}
 pdin_neighborhoood <- receive_arcgis("M:/Parcel_Neighborhood.shp")
 
# Key with PIDN and neighborhood
pdin_key <- pdin_neighborhoood[, c(5, 60)]

# Join key with cut list records and delete any extra rows created from the join
cuts_all <- cuts_all %>%
  left_join(pdin_key, by = "PIDN")%>%
  unique()

cuts_all$`CUT DATE` <-as.character(cuts_all$`CUT DATE`)
cuts_all <- arrange(cuts_all[, -c(7:8)], Year, PIDN)
cuts_all <-as.data.frame(cuts_all)

# Write Files ----------------------------------------------------------
sql_write <- function(connection, dbName, dbGname, Rfile, dbPull, RepoPath, TablPath, ...) {
  library("RSQLite")
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
dbPull <- 'select * from Cut_List'
RepoPath <- "O:/AllUsers/CovStat/Data Portal/Repository/Data/Development/CodeEnforcement/Cut_list.csv"
TablPath <- "U:/CityWide Performance/CovStat/CovStat Projects/Development/Tableau Files/Cut_list.csv"
sql_write(connection, dbName, "Cut_List", Rfile = cuts_all, dbPull, RepoPath, TablPath, overwrite= TRUE)








