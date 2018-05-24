#######################################################################
# Processing footfall Data UK wide
# Fred Shone
# 26th March 2018

# Code to unpack weather station data onto a given sampling  point grid

#######################################################################
# INSTALL & LOAD PACKAGES
pkgs <- c("data.table","plyr","dplyr","rgeos","sp",
          "rgdal","maptools","ks","raster","gstat",
          "scales","magrittr",
          "lubridate","png","geojsonio")
for (pkg in pkgs) {
  if(pkg %in% rownames(installed.packages()) == FALSE) {install.packages(pkg)
    lapply(pkgs, require, character.only = TRUE)}
  else {
    lapply(pkgs, require, character.only = TRUE)}
}
rm(pkg,pkgs)

#######################################################################
# USER VARIABLES


#######################################################################
# LOAD DATA

# Load data
feb <- fread("feb18I.csv",header=F)
feb$month <- "02"
mar <- fread("mar18I.csv",header=F)
mar$month <- "03"
data <- rbind(feb, mar)
colnames(data) <- c("id","day","hour","min","count","month")

# Set data classes (timestamps)
data$OB_TIME <- ymd_hms(paste0("2018-",data$month,"-",data$day," ",data$hour,":",data$min,":00 UTC"))

#######################################################################
# Get temporal subset of data

minTime <- min(data$OB_TIME)
minTime <- as.character(minTime)
minTime <- lubridate::ymd_hms(minTime, truncated = 3)
maxTime <- max(data$OB_TIME)

#########################
# USER INPUTS - TIME PERIOD

requestA <- function() {
  print("==========================================")
  
  print(paste0("Available data extends from: ", minTime, " --> ", maxTime,"."))
  
  A <- readline(prompt = "Would you like to specify subset of data? (y/n): ")
  
  if (A %in% c("y","Y","yes","Yes","YES")) {
    startTime <- readline(prompt="Enter requested start day in yyyy-mm-dd format: ")
    startTime <<- ymd(startTime)
    endTime <- readline(prompt="Enter requested end day in yyyy-mm-dd format: ")
    endTime <<- ymd(endTime) + hours(24)
  } else if (A %in% c("n","N","no","No","NO")) {
    startTime <<- minTime
    endTime <<- maxTime
  } else {
    requestA()
  }
}

requestA()

#######################################################################
# Trim to time period

dataSelected <- data[data$OB_TIME >= startTime]
dataSelected <- data[data$OB_TIME < endTime]

#######################################################################
# Create empty dataframe
output <- data.frame(timestamp=seq.POSIXt(as.POSIXct(startTime), as.POSIXct(endTime-minutes(15)), by = "15 min"))

  
  # Loop through time:
  row <- 0
  t <- startTime
  while (t < endTime) { # Set to less than end time to allow for interpolation
    print(paste("from", t, "to", t+minutes(15)))
    
    dataHour <- dataSelected[dataSelected$OB_TIME >= t,]
    dataHour <- dataSelected[dataSelected$OB_TIME < (t+minutes(15)),]

      # Add to dataframe
    row <- row+1
      output[row,2] <- mean(dataHour$count, na.rm=T)

  t = t + minutes(15)
  } # End of time loop
  
  # Normalise column
  output[2] <- (output[2] - min(output[2])) / (max(output[2]) - min(output[2]))
  
  # Add column names
  colnames(output)[2] <- "footfall"

write.csv(output, "foot_data.csv")
