
setwd("U:/CityWide Performance/Development/Section 8")

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
library("RSQLite")

###  Port Outs  ###

port.out16 <- read.xlsx("U:/CityWide Performance/Development/Section 8/2016 Port Outs.xlsx", sheetIndex = 1, endRow = 71,  header = TRUE, as.data.frame = TRUE)
port.out16 <- port.out16[c(-4:-5)]
port.out16 <- rename(port.out16, c("Receiving.Agency"="Agency"))

port.out15 <- read.xlsx("U:/CityWide Performance/Development/Section 8/2015 Port Outs.xlsx", sheetIndex = 1, startRow = 2, endRow = 85,  header = TRUE, as.data.frame = TRUE)
port.out15$Request.Rec.d <- NA
port.out15 <- port.out15[,c(2,3,9,4,5,6,7,8)]

port.out14 <- read.xlsx("U:/CityWide Performance/Development/Section 8/2014 Port Outs.xlsx", sheetIndex = 1, startRow = 2, endRow = 63,  header = TRUE, as.data.frame = TRUE)
port.out14$Request.Rec.d <- NA
port.out14 <- port.out14[,c(2,3,9,4,5,6,7,8)]

port.out13 <- read.xlsx("U:/CityWide Performance/Development/Section 8/2013 Port Outs.xlsx", sheetIndex = 1, startRow = 2, endRow = 62,  header = TRUE, as.data.frame = TRUE)
port.out13$Request.Rec.d <- NA
port.out13 <- port.out13[,c(2,3,9,4,5,6,7,8)]

port.out12 <- read.xlsx("U:/CityWide Performance/Development/Section 8/2012 Port Outs.xlsx", sheetIndex = 1, startRow = 3, endRow = 101,  header = TRUE, as.data.frame = TRUE)
port.out12 <- port.out12[-1,]
port.out12$Request.Rec.d <- NA
port.out12 <- port.out12[,c(2,3,9,4,5,6,7,8)]

port.out <- do.call("rbind", list(port.out12, port.out13, port.out14, port.out15, port.out16))

port.out$Status[port.out$Lease.Date == "N/A"] <- "Sent Back/Not Accepted"
port.out$Status[which(is.na(port.out$Lease.Date))] <- "Still in Progress"
port.out$Status[which(is.na(port.out$Status))] <- "Leased"
names(port.out)[1] <- "CW"
port.out$PortIn.PortOut <- "Port Out"

port.out <- port.out[c("CW", "Client.Name", "Agency", "Request.Rec.d", "P.work.Sent", "Lease.Date", "NewDate", "Status", "PortIn.PortOut")]
port.out <- rename(port.out, c("Request.Rec.d"="Request.Received", "P.work.Sent"="PaperWork.Sent.Received", 
                               "NewDate"="NewLeaseDate", "Status"="LeaseStatus"))


####  Port Ins   ####

port.in16 <- read.xlsx("U:/CityWide Performance/Development/Section 8/PORTABILITY.xlsx", sheetName = "2016", rowIndex = 4:44, as.data.frame = TRUE)
port.in16 <- port.in16[c(-1),]

port.in15 <- read.xlsx("U:/CityWide Performance/Development/Section 8/PORTABILITY.xlsx", sheetName = "2015", rowIndex = 4:78, as.data.frame = TRUE)
port.in15 <- port.in15[c(-1),]

port.in14 <- read.xlsx("U:/CityWide Performance/Development/Section 8/PORTABILITY.xlsx", sheetName = "2014", as.data.frame = TRUE)
port.in14 <- port.in14[c(-1),]

port.in13 <- read.xlsx("U:/CityWide Performance/Development/Section 8/PORTABILITY.xlsx", sheetName = "2013", rowIndex = 4:62, as.data.frame = TRUE)

port.in12 <- read.xlsx("U:/CityWide Performance/Development/Section 8/PORTABILITY.xlsx", sheetName = "2012", rowIndex = 4:89, as.data.frame = TRUE)
port.in12 <- port.in12[c(-1:-2),]

port.ins <- do.call("rbind", list( port.in12, port.in13, port.in14, port.in15, port.in16))

port.ins$Status[port.ins$Lease.Date == "N/A"] <- "Sent Back/Not Accepted"
port.ins$Status[which(is.na(port.ins$Lease.Date))] <- "Still in Progress"
port.ins$Status[which(is.na(port.ins$Status))] <- "Leased"
port.ins$CW <-NA
port.ins$Request.Received <- NA
port.ins$PortIn.PortOut <- "Port In"

port.ins <- port.ins[c("CW", "Client.Name", "Initial.H.A.", "Request.Received", "Rec.d.P.work", "Lease.Date", "NewLeaseDate", "Status", "PortIn.PortOut")]
port.ins <- rename(port.ins, c("Initial.H.A."="Agency", "Rec.d.P.work"="PaperWork.Sent.Received", "Status"="LeaseStatus"))


###   Bind Port Outs and Port Ins  ###

ports <- do.call("rbind", list(port.out, port.ins))

write.xlsx (ports,"U:/CityWide Performance/Development/Section 8/For Reporting/PORTABILITY_in_out.xlsx", row.names = FALSE)

portsexport <- ports

portsexport <- as.character(ports.export$Request.Received)

portsexport <- as.character(ports.expor$PaperWork.Sent.Received)
portsexport <-  as.Character(ports.export$NewLeaseDate)


### Subsetting by Date ###
#test <- port.ins[port.ins$NewLeaseDate > as.Date("1899-12-31"),]

#as.Date(x, origin = "1970-01-01")

######################################
###  Connect and write to SQLite  ###
#system("rm test4.db")

ma <- dbDriver("SQLite")
cons <- dbConnect(ma, dbname="PORTS.db")

dbWriteTable(cons, "Port", portsexport)

dbDisconnect(cons)


