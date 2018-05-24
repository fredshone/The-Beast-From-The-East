#######################################################################
# Summarise weather station data at City Level
# Fred Shone
# 26th March 2018

# Code to unpack weather station data into city summaries

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

# Select data
selected <- c("AIR_TEMPERATURE", "SNOW_DEPTH", "VISIBILITY", "WIND_SPEED") #"WIND_SPEED","AIR_TEMPERATURE","","AIR_TEMPERATURE"

#######################################################################
#Set up CRS
latlong = "+init=epsg:4326"
ukgrid = "+init=epsg:27700"
google = "+init=epsg:3857"

#######################################################################
# LOAD DATA

# Load headers
headers <- fread("WH_Column_Headers.txt",header=F)

# Load data
data <- fread("midas_wxhrly_201801-201812a.txt",header=F)

# Load station locations
locations <-  fread("weather_stations.csv", header = T)

# Read boundary
boundary <- geojson_read("../boundaries/UKandIreWGS84.geojson",what="sp") #Read GeoJSON
proj4string(boundary) <- latlong
boundary <- spTransform(boundary, ukgrid)

#LOAD REGULAR POINT GRID
#See London_grid.R for reference
regpoints <- fread("bboxUKGrid_5_km.csv",header=T) #Load regular point grid
#Convert to SP
coordinates(regpoints) <- ~ x + y
proj4string(regpoints) <- google
# Capture bbox for later cropping
b <- bbox(regpoints)

# Define cities
London <- c(51.5074, -0.1278)
Bristol <- c(51.4545, -2.5879)
Exeter <- c(50.7184, -3.5339)
Southampton <- c(50.9097, -1.4044)
Birmingham <- c(52.4862, -1.8904)
Leicester <- c(52.6369, -1.1398)
Manchester <- c(53.4808, -2.2426)
Durham <- c(54.7753, -1.5849)
Carlisle <- c(54.8925, -2.9329)
Cardiff <- c(51.4816, -3.1791)
Edinburgh <- c(55.9533, -3.1883)
Glasgow <- c(55.8642, -4.2518)

cities <- rbind(London, Bristol, Exeter, Southampton, Birmingham,
                Leicester, Manchester, Durham, Carlisle, Cardiff, Edinburgh, Glasgow)
cities <- as.data.frame(cities)
colnames(cities) <- c('y', 'x')
cities$names <- rownames(cities)
cities_df <- cities

#Convert to SP
coordinates(cities) <- ~ x + y
proj4string(cities) <- latlong
cities <- spTransform(cities, ukgrid)

#######################################################################
# Add headers to data
for (i in seq_along(headers)) {
  #print(headers[1,i,with=F])
  colnames(data)[i] <- as.character(headers[1,i,with=F])
}

#######################################################################
# STATIONS

station_ids <- c(9621, 676, 674, 9406, 886, 18912, 56956, 62083, 5612, 709, 708, 18929, 18911, 725, 711, 726, 697, 12103,
                 12122, 1135, 57199, 1135, 1125, 1936, 17182, 527, 1070, 1066, 19260, 246, 61991, 971) # src_ids

# select stations

# data <- data[data$SRC_ID %in% station_ids]
# stations <- dplyr::group_by(data, MET_DOMAIN_NAME, SRC_ID)
# dplyr::summarize(stations, max_ws = max(WIND_SPEED), min_at = max(AIR_TEMPERATURE))

# Get version 1
dataV1 <- data[data$VERSION_NUM == 1]

# Set data classes (timestamps)
dataV1$OB_TIME <- lubridate::ymd_hms(dataV1$OB_TIME, truncated = 1)
dataV1$METO_STMP_TIME <- lubridate::ymd_hms(dataV1$METO_STMP_TIME, truncated = 1)

# Set NA SNOW_DEPTH values to 0
dataV1$SNOW_DEPTH <- as.numeric(dataV1$SNOW_DEPTH)
# dataV1$SNOW_DEPTH[is.na(dataV1$SNOW_DEPTH)] <- 0
dataV1$SNOW_DEPTH[dataV1$SNOW_DEPTH > 75] <- 75

#######################################################################
# Select variable subset of data

default <- c("OB_TIME","ID","ID_TYPE","MET_DOMAIN_NAME","SRC_ID")
dataSelected <- dataV1[,append(default,selected),with=F]


#######################################################################
# Get temporal subset of data

minTime <- min(dataSelected$OB_TIME)
minTime <- as.character(minTime)
minTime <- lubridate::ymd_hms(minTime, truncated = 3)

maxTime <- max(dataSelected$OB_TIME)

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

dataSelected <- dataSelected[dataSelected$OB_TIME >= startTime]
dataSelected <- dataSelected[dataSelected$OB_TIME < endTime]

#######################################################################
# Merge location data
dataLocations <- merge.data.frame(dataSelected, locations, by.x="SRC_ID", by.y="src_id", sort = FALSE)

# Convert to SP
coordinates(dataLocations) <- ~ Longitude + Latitude
proj4string(dataLocations) <- latlong

#Transform to google
dataLocations = spTransform(dataLocations, ukgrid)

#######################################################################
# Create empty dataframe
output <- data.frame(timestamp=seq.POSIXt(as.POSIXct(startTime), as.POSIXct(endTime-minutes(15)), by = "15 min"))

plot(cities)
plot(boundary, add=T)

# Loop through city buffers
colcity <- 0
for (city in cities_df$names) {
  
  print(city)
  city_buffer <- cities[city,]
  city_buffer <- buffer(city_buffer, 50000)
  
  # Crop data
  dataCitySelected <- crop(dataLocations, city_buffer)
  
  dataCitySelected_df <- as.data.frame(dataCitySelected)
  
  # plot(dataCitySelected, add=T)
  # 
  plot(city_buffer, add=T)
  
  # Loop through time:
  row <- 0
  t <- startTime
  while (t < endTime) { # Set to less than end time to allow for interpolation
    print(paste("From", t, "to", t+hours(1)))
    
    dataHour <- dataCitySelected_df[dataCitySelected_df$OB_TIME == t,]
    nextHour <- dataCitySelected_df[dataCitySelected_df$OB_TIME == t + hours(1),]
    
    # c("AIR_TEMPERATURE", "SNOW_DEPTH", "VISIBILITY", "WIND_SPEED")
    av_hour_AT <- mean(dataHour$AIR_TEMPERATURE, na.rm=T)
    av_hour_SD <- mean(dataHour$SNOW_DEPTH, na.rm=T)
    av_hour_VZ <- mean(dataHour$VISIBILITY, na.rm=T)
    av_hour_WS <- mean(dataHour$WIND_SPEED, na.rm=T)
    
    av_next_AT <- mean(nextHour$AIR_TEMPERATURE, na.rm=T)
    av_next_SD <- mean(nextHour$SNOW_DEPTH, na.rm=T)
    av_next_VZ <- mean(nextHour$VISIBILITY, na.rm=T)
    av_next_WS <- mean(nextHour$WIND_SPEED, na.rm=T)

    av_trans_AT <- (av_next_AT-av_hour_AT)/4
    av_trans_SD <- (av_next_SD-av_hour_SD)/4
    av_trans_VZ <- (av_next_VZ-av_hour_VZ)/4
    av_trans_WS <- (av_next_WS-av_hour_WS)/4
    
    # Loop through 15min intervals interpolating
    for (m in 1:4) {
      row <- row+1
      
      av_AT <- av_hour_AT + (m-1)*av_trans_AT
      av_SD <- av_hour_SD + (m-1)*av_trans_SD
      av_VZ <- av_hour_VZ + (m-1)*av_trans_VZ
      av_WS <- av_hour_WS + (m-1)*av_trans_WS
      
      # Add to dataframe
      output[row,(colcity*4)+2] <- av_AT
      output[row,(colcity*4)+3] <- av_SD
      output[row,(colcity*4)+4] <- av_VZ
      output[row,(colcity*4)+5] <- av_WS
    } # End of hour loop
  t = t + hours(1)
  } # End of time loop
  
  # Add column names
  colnames(output)[(colcity*4)+2] <- paste0(city, "_AT")
  colnames(output)[(colcity*4)+3] <- paste0(city, "_SD")
  colnames(output)[(colcity*4)+4] <- paste0(city, "_VZ")
  colnames(output)[(colcity*4)+5] <- paste0(city, "_WS")
  
  colcity <- colcity + 1
} # End of city loop

write.csv(output, "city_data.csv")
