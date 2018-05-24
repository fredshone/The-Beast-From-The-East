#######################################################################
# Rasterising weather station data - AIR TEMPERATURE
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
selected <- c("AIR_TEMPERATURE") #"WIND_SPEED","AIR_TEMPERATURE","","AIR_TEMPERATURE"

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

#LOAD REGULAR POINT GRID
#See London_grid.R for reference
regpoints <- fread("bboxUKGrid_5_km.csv",header=T) #Load regular point grid
#Convert to SP
coordinates(regpoints) <- ~ x + y
proj4string(regpoints) <- google

# Capture bbox for later cropping
b <- bbox(regpoints)

#######################################################################
# Add headers to data
for (i in seq_along(headers)) {
  #print(headers[1,i,with=F])
  colnames(data)[i] <- as.character(headers[1,i,with=F])
}

#######################################################################
# PRELIM DATA CLEAN

# Remove old versions
v0count <- data[data$VERSION_NUM == 0] %>% nrow()
v1count <- data[data$VERSION_NUM == 1] %>% nrow()

v01count <- data[(data$VERSION_NUM == 0) & (data$ID %in% data$ID[data$VERSION_NUM == 1])] %>% nrow()
v1missing <- v0count - v01count

if (v1missing>0) {print("WARNING:")}
print(paste((v1missing), "version 1 rows missing."))

dataV1 <- data[data$VERSION_NUM == 1]

# Set data classes (timestamps)
dataV1$OB_TIME <- lubridate::ymd_hms(dataV1$OB_TIME, truncated = 1)
dataV1$METO_STMP_TIME <- lubridate::ymd_hms(dataV1$METO_STMP_TIME, truncated = 1)

# Set NA SNOW_DEPTH values to 0
dataV1$SNOW_DEPTH <- as.numeric(dataV1$SNOW_DEPTH)
dataV1$SNOW_DEPTH[is.na(dataV1$SNOW_DEPTH)] <- 0


#######################################################################
# Select variable subset of data

default <- c("OB_TIME","ID","ID_TYPE","MET_DOMAIN_NAME","SRC_ID")
dataSelected <- dataV1[,append(default,selected),with=F]

#######################################################################
# Select spatial extends (trim away data from Canary Islands and so on...)

# Merge location data
dataSelected <- merge.data.frame(dataSelected, locations, by.x="SRC_ID", by.y="src_id", sort = FALSE)
# Convert to SP
coordinates(dataSelected) <- ~ Longitude + Latitude
proj4string(dataSelected) <- latlong

#Transform to google
dataSelected = spTransform(dataSelected, google)

# Trim using grid bounding box
dataSelected <- crop(dataSelected, b)

# Return to dataframe
dataSelected <-  as.data.frame(dataSelected)

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

if (length(selected) == 1) {
  
  mins <- min(dataSelected[,selected], na.rm=TRUE)
  maxs <- max(dataSelected[,selected], na.rm=TRUE)
  
} else if (length(selected) > 1) {

mins <- apply(dataSelected[,selected], 2, function(x) min(x,na.rm=TRUE))
maxs <- apply(dataSelected[,selected,with=F], 2, function(x) max(x,na.rm=TRUE))

} 

if (length(selected) >0) {
  minmax <- rbind(mins,maxs) %>% as.data.frame(stringsAsFactors = F)
  names(minmax) <- selected
  minmax[minmax==""] <- 0
  } else {
  print("No data selected?")
}

print("==========================================")

print(minmax)

#######################################################################
# Quantile

q25 <- quantile(dataSelected$VISIBILITY, na.rm=T)[2]
q50 <- quantile(dataSelected$VISIBILITY, na.rm=T)[3]
q75 <- quantile(dataSelected$VISIBILITY, na.rm=T)[4]

#######################################################################
# Min-max standardisation

dataSelected[,selected] <- (dataSelected[,selected]-mins)/(maxs-mins)

#######################################################################
# Set up session output directory
subDir <- paste0(as.character(now()),"_",selected)
subDir <- gsub(" ", "_", subDir, fixed = TRUE)
subDir <- gsub(":", "-", subDir, fixed = TRUE)

dir.create(file.path(subDir), FALSE)

#######################################################################
# Loop through timestamps

t <- startTime
while (t < endTime) { # Set to less than end time to allow for interpolation
  print(paste("From", t, "to", t+hours(1)))
  
  dataHour <- dataSelected[dataSelected$OB_TIME == t,]
  nextHour <- dataSelected[dataSelected$OB_TIME == t + hours(1),]
  
  # Create timestamp character string
  tString <- as.character(t)
  # Add 00:00:00 if required
  if (nchar(tString) < 15) {tString <- paste(tString, "00:00:00")}
  tString <- substr(tString,1,13)
  
  tString <- gsub(" ", "_", tString, fixed = TRUE)
  tString <- gsub(":", "-", tString, fixed = TRUE)

  #######################################################################
  
  i <- selected
  
  # Select Data
  dataHourSelected <- dataHour[,c(default,i)]
  nextHourSelected <- nextHour[,c(default,i)]
  print(i)
  # Rename as WEATHER for future modelling
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
  coordinates(nextHourSelected) <- ~ Longitude + Latitude
  
  proj4string(dataHourSelected) <- latlong
  proj4string(nextHourSelected) <- latlong
  
  #Transform to google
  dataHourSelected = spTransform(dataHourSelected, google)
  nextHourSelected = spTransform(nextHourSelected, google) 
  
  #######################################################################
  # Inverse Distance Weighted
  
  # https://mgimond.github.io/Spatial/spatial-interpolation.html
  
  sample.idw = idw(WEATHER~1, dataHourSelected, regpoints, idp = 4) %>% as.data.frame()
  nextSample.idw = idw(WEATHER~1, nextHourSelected, regpoints, idp = 4) %>% as.data.frame()
  
  # Convert to raster
  raster <- rasterFromXYZ(sample.idw[,c(1:3)], crs=google)
  nextRaster <- rasterFromXYZ(nextSample.idw[,c(1:3)], crs=google)
  changeRaster <- (nextRaster - raster)/4
  
  # Loop through interpediate timetamps
  for (m in 1:4) {
    
    dict <- c("00","15","30","45")
    
    # Interpolate raster
    tempRaster <- raster + (changeRaster*(m-1))
  
    # Colour array (low value = low temp)
    colourArray <- as.array(tempRaster)

    # Convert to 3d array
    array <- array(0, dim=c(nrow(tempRaster),ncol(tempRaster),4))
    
    array[,,1] <- 0.08 + (0.92 * colourArray)
    array[,,2] <- 0.08 + (0.92 * colourArray)
    array[,,3] <- 0.9 + (0.1 * colourArray)
    
    array[,,4] <- 0.8 - (colourArray * 0.8)
    
    writePNG(array, paste0(subDir,"/","air_temp_",tString,"-",dict[m],"-00.png"))
  
  }
  
  # Next timestamp
  t = t+hours(1)  
}



