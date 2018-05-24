#######################################################################
# Processing footfall Data UK by City
# Fred Shone
# 26th March 2018

# Code to unpack weather station data onto a given sampling  point grid
# User can define period for analysis

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
#Set up CRS
latlong = "+init=epsg:4326"
ukgrid = "+init=epsg:27700"
google = "+init=epsg:3857"

#######################################################################
# LOAD DATA

# Load data
feb <- fread("feb18I.csv",header=F)
feb$month <- "02"
mar <- fread("mar18I.csv",header=F)
mar$month <- "03"
data <- rbind(feb, mar)
colnames(data) <- c("id","day","hour","min","count","month")

# Load station locations
locations <-  fread("locations.csv", header = T)

# Read boundary
boundary <- geojson_read("../boundaries/UKandIreWGS84.geojson",what="sp") #Read GeoJSON
proj4string(boundary) <- latlong
boundary <- spTransform(boundary, ukgrid)

# Define cities

London <- c(51.5074, -0.1278)
Bristol <- c(51.4545, -2.5879)
Exeter <- c(50.7184, -3.5339)
Southampton <- c(50.9097, -1.4044)
Birmingham <- c(52.4862, -1.8904)
Leicester <- c(52.6369, -1.1398)
Manchester <- c(53.4808, -2.2426)
Durham <- c(54.7753, -1.5849)
Cardiff <- c(51.4816, -3.1791)
Edinburgh <- c(55.9533, -3.1883)
Glasgow <- c(55.8642, -4.2518)

cities <- rbind(London, Bristol, Exeter, Southampton, Birmingham,
                Leicester, Manchester, Durham, Cardiff, Edinburgh, Glasgow)
cities <- as.data.frame(cities)
cities$names <- rownames(cities)

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
# Merge location data
dataLocations <- merge.data.frame(dataSelected, locations, by="id", sort = FALSE)

#######################################################################
# Create empty dataframe
output <- data.frame(timestamp=seq.POSIXt(as.POSIXct(startTime), as.POSIXct(endTime-minutes(15)), by = "15 min"))

# Loop through city buffers
colcity <- 0
for (city in cities$names) {
  
  print(city)
  
  # Crop data
  dataCitySelected <- dataLocations[dataLocations$city == city,]
  
  # Loop through time:
  row <- 0
  t <- startTime
  while (t < endTime) { # Set to less than end time to allow for interpolation
    print(paste(city, "from", t, "to", t+minutes(15)))
    
    dataHour <- dataCitySelected[dataCitySelected$OB_TIME >= t,]
    dataHour <- dataCitySelected[dataCitySelected$OB_TIME < (t+minutes(15)),]

      # Add to dataframe
    row <- row+1
      output[row,(colcity)+2] <- mean(dataHour$count, na.rm=T)

  t = t + minutes(15)
  } # End of time loop
  
  # Normalise column
  output[(colcity)+2] <- (output[(colcity)+2] - min(output[(colcity)+2])) / (max(output[(colcity)+2]) - min(output[(colcity)+2]))
  
  # Add column names
  colnames(output)[(colcity)+2] <- paste0(city, "_footfall")
  
  colcity <- colcity + 1
} # End of city loop

write.csv(output, "city_foot_data.csv")
