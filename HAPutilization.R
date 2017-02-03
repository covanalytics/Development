
##########################################
### HCV Utilization Tracking to SQLite ###
##########################################

## load the google sheet
library(gsheet)
url <- 'https://docs.google.com/spreadsheets/d/1Gnbhkwo5drR6xDfU2shYRZbiJxyQ95pEKP0RJbaRrcg/edit#gid=0'
utilization <- gsheet2tbl(url)

## Send to SQLite 
cons.utilization <- dbConnect(drv=RSQLite::SQLite(), dbname="O:/AllUsers/CovStat/Data Portal/repository/Data/Database Files/Development.db")
dbWriteTable(cons.utilization, "HCV_Utilization_Tracking", utilization, overwrite = TRUE)
dbDisconnect(cons.utilization)