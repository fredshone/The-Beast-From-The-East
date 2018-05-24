#######################################################################
# Rasterising weather station data WIND SPEED AND DIRECTION - EUROPE
# Fred Shone
# 26th March 2018

# Code to unpack weather station data onto a given sampling  point grid

#######################################################################
# INSTALL & LOAD PACKAGES
pkgs <- c("data.table","dplyr","plyr","rgeos","sp",
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
selected <- c("WIND_SPEED", "WIND_DIRECTION") #"WIND_SPEED","SNOW_DEPTH","","AIR_TEMPERATURE"

#######################################################################
#Set up CRS
latlong = "+init=epsg:4326"
ukgrid = "+init=epsg:27700"
google = "+init=epsg:3857"

#######################################################################
# LOAD EUROPE DATA

# Load headers
headersEurope <- fread("world_data/GL_Column_Headers.csv",header=F)

# Load data
dataEurope <- fread("world_data/midas_glblwx-europe_201801-201812.txt",header=F)

# Load station locations
locationsEurope <-  fread("world_data/excel_list_station_details.csv", header = T)

#######################################################################
# Read boundary
boundary <- geojson_read("../boundaries/Europe.geojson",what="sp") #Read GeoJSON
boundary <- spTransform(boundary, google)

#######################################################################
# LOAD UK DATA

# Load headers
headersUK <- fread("WH_Column_Headers.txt",header=F)

# Load data
dataUK <- fread("midas_wxhrly_201801-201812a.txt",header=F)

# Load station locations
locationsUK <-  fread("weather_stations.csv", header = T)

#######################################################################
# Combine locations
locations <- rbind(locationsEurope, locationsUK)

#######################################################################
#LOAD REGULAR POINT GRID
#See London_grid.R for reference
regpoints <- fread("bboxEuroGrid_200_km.csv",header=T) #Load regular point grid
#Convert to SP
coordinates(regpoints) <- ~ x + y
proj4string(regpoints) <- google
# Capture bbox for later cropping
b <- bbox(regpoints)

#######################################################################
# Add headers to data
for (i in seq_along(headersEurope)) {
  #print(headers[1,i,with=F])
  colnames(dataEurope)[i] <- as.character(headersEurope[1,i,with=F])
}

for (i in seq_along(headersUK)) {
  #print(headers[1,i,with=F])
  colnames(dataUK)[i] <- as.character(headersUK[1,i,with=F])
}

#######################################################################
# PRELIM DATA CLEAN

# Remove old versions from UK data
v0count <- dataUK[dataUK$VERSION_NUM == 0] %>% nrow()
v1count <- dataUK[dataUK$VERSION_NUM == 1] %>% nrow()

v01count <- dataUK[(dataUK$VERSION_NUM == 0) & (dataUK$ID %in% dataUK$ID[dataUK$VERSION_NUM == 1])] %>% nrow()
v1missing <- v0count - v01count

if (v1missing>0) {print("WARNING:")}
print(paste((v1missing), "version 1 rows missing."))

dataUKV1 <- dataUK[dataUK$VERSION_NUM == 1]

# No old versions in Europe data
dataEuropeV1 <- dataEurope

#dataV2 <- data[!is.na(data$SNOW_DEPTH)] ################# EDIT


# Set data classes (timestamps)
dataEuropeV1$OB_TIME <- lubridate::ymd_hms(dataEuropeV1$OB_TIME, truncated = 1)
dataUKV1$OB_TIME <- lubridate::ymd_hms(dataUKV1$OB_TIME, truncated = 1)
# dataV1$METO_STMP_TIME <- lubridate::ymd_hms(dataV1$METO_STMP_TIME, truncated = 1)

# Set NA SNOW_DEPTH values to 0
dataEuropeV1$SNOW_DEPTH <- as.numeric(dataEuropeV1$SNOW_DEPTH)
dataUKV1$SNOW_DEPTH <- as.numeric(dataUKV1$SNOW_DEPTH)
dataEuropeV1$SNOW_DEPTH[is.na(dataEuropeV1$SNOW_DEPTH)] <- 0
dataUKV1$SNOW_DEPTH[is.na(dataUKV1$SNOW_DEPTH)] <- 0

#######################################################################
# Select variable subset of data

default <- c("OB_TIME","ID","ID_TYPE","MET_DOMAIN_NAME","SRC_ID")

dataSelectedEurope <- dataEuropeV1[,append(default,selected),with=F]
dataSelectedEurope <- merge.data.frame(dataSelectedEurope, locationsEurope, by.x="SRC_ID", by.y="src_id", sort = FALSE)
coordinates(dataSelectedEurope) <- ~ Longitude + Latitude
proj4string(dataSelectedEurope) <- latlong

dataSelectedUK <- dataUKV1[,append(default,selected),with=F]
dataSelectedUK <- merge.data.frame(dataSelectedUK, locationsUK, by.x="SRC_ID", by.y="src_id", sort = FALSE)
coordinates(dataSelectedUK) <- ~ Longitude + Latitude
proj4string(dataSelectedUK) <- latlong

dataSelected <- rbind(dataSelectedEurope, dataSelectedUK) ######## EDIT
print(paste(nrow(dataSelected), "rows selected." ))
print(paste("UK:", nrow(dataSelectedUK)))
print(paste("EUROPE:", nrow(dataSelectedEurope)))

#Transform to google
dataSelected = spTransform(dataSelected, google)

# Trim using grid bounding box
dataSelected <- crop(dataSelected, b)

# Return to dataframe
dataSelected <-  as.data.frame(dataSelected)
print(paste(nrow(dataSelected), "rows remaining after spatial trim" ))

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
# Get data extends

mins <- min(dataSelected[,"WIND_SPEED"], na.rm=TRUE)
maxs <- max(dataSelected[,"WIND_SPEED"], na.rm=TRUE)

minmax <- rbind(mins,maxs) %>% as.data.frame(stringsAsFactors = F)
names(minmax) <- "WIND_SPEED"
#minmax[minmax==""] <- 0

print("==========================================")

print(minmax)

#######################################################################
# Min-max standardisation of wind speed

dataSelected[,"WIND_SPEED"] <- (dataSelected[,"WIND_SPEED"]-mins)/(maxs-mins)


#######################################################################
# Calculate Easting and Northing Vectors

dataSelected[,"RAD"] <- dataSelected[,"WIND_DIRECTION"] * 2 * pi / 360
dataSelected[,"N_VECTOR"] <- dataSelected[,"WIND_SPEED"] * cos(dataSelected[,"RAD"])
dataSelected[,"E_VECTOR"] <- dataSelected[,"WIND_SPEED"] * sin(dataSelected[,"RAD"])

#######################################################################
# Set up session output directory
subDir <- paste0(as.character(now()),"_Euro_","WIND_VECTORS")
subDir <- gsub(" ", "_", subDir, fixed = TRUE)
subDir <- gsub(":", "-", subDir, fixed = TRUE)

dir.create(file.path(subDir), FALSE)

#######################################################################
# Loop through timestamps

t <- startTime
while (t < endTime) { # Set to less than end time to allow for interpolation
  print(paste("From", t, "to", t+hours(3)))
  
  dataHour <- dataSelected[dataSelected$OB_TIME == t + hours(0),]
  nextHour <- dataSelected[dataSelected$OB_TIME == t + hours(3),]
  
  #######################################################################
  
  I <- c("N_VECTOR", "E_VECTOR")
  
  # Set up correctly dimensioned array
  tempReg <- as.data.frame(regpoints)
  tempRaster <- rasterFromXYZ(tempReg[,c(3,4,1)], crs=google ) # CHECK
  nowArray <- array(0, dim=c(nrow(tempRaster),ncol(tempRaster),2))
  nextArray <- array(0, dim=c(nrow(tempRaster),ncol(tempRaster),2))
  
  n <- 0
  for (i in I) {
    
    # Index
    n <- n + 1
    
    # Select Data
    print(i)
    dataHourSelected <- dataHour[,c(default,i)]
    nextHourSelected <- nextHour[,c(default,i)]
    
    # Rename as WEATHER for model
    names(dataHourSelected)[names(dataHourSelected) == i] <- "WEATHER"
    names(nextHourSelected)[names(nextHourSelected) == i] <- "WEATHER"
    
    # Trim NaNs
    dataHourSelected <- dataHourSelected[complete.cases(dataHourSelected[ ,"WEATHER"]),]
    nextHourSelected <- nextHourSelected[complete.cases(nextHourSelected[ ,"WEATHER"]),]
    
    #######################################################################
    # Merge
    dataHourSelected <- merge.data.frame(dataHourSelected, locations, by.x="SRC_ID", by.y="src_id", sort = FALSE)
    nextHourSelected <- merge.data.frame(nextHourSelected, locations, by.x="SRC_ID", by.y="src_id", sort = FALSE)
    
    # Convert to SP
    coordinates(dataHourSelected) <- ~ Longitude + Latitude
    proj4string(dataHourSelected) <- latlong
    
    coordinates(nextHourSelected) <- ~ Longitude + Latitude
    proj4string(nextHourSelected) <- latlong
    
    #Transform to google
    dataHourSelected = spTransform(dataHourSelected, google)
    nextHourSelected = spTransform(nextHourSelected, google)
    
    #######################################################################
    # Inverse Distance Weighted
    
    # https://mgimond.github.io/Spatial/spatial-interpolation.html
    sample.idw = idw(WEATHER~1, dataHourSelected, regpoints, idp = 3) %>% as.data.frame()
    nextSample.idw = idw(WEATHER~1, nextHourSelected, regpoints, idp = 3) %>% as.data.frame()
    
    # Convert to raster
    
    nowRaster <- rasterFromXYZ(sample.idw[,c(1:3)], crs=google)
    nextRaster <- rasterFromXYZ(nextSample.idw[,c(1:3)], crs = google)
    
    nowArray[,,n] <- as.array(nowRaster)
    nextArray[,,n] <- as.array(nextRaster)
    
  }
  
  changeArray <- (nextArray - nowArray) / 3
  
  # Loop through interpediate timetamps
  for (m in 1:3) {
    
    # Interpolate raster
    tempArray <- nowArray + (changeArray*(m-1))
    
    # Create timestamp character string
    time_temp = t + hours(1*(m-1))
    tString <- as.character(time_temp)
    # Add 00:00:00 if required
    if (nchar(tString) < 15) {tString <- paste(tString, "00:00:00")}
    
    tString <- gsub(" ", "_", tString, fixed = TRUE)
    tString <- gsub(":", "-", tString, fixed = TRUE)
    
    writePNG(tempArray, paste0(subDir,"/","wind_",tString,".png"))
    
  }
  
  # Next timestamp
  t = t+hours(3)  
}
