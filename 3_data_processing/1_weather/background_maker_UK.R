#######################################################################
# Rasteriser used to make simple background maps
# Fred Shone
# 26th March 2018

# Code to unpack weather station data onto a given sampling  point grid

#######################################################################

# Packages
pkgs <- c("rgeos","raster","sp","rgdal","geojsonio")
for (pkg in pkgs) {
  if(pkg %in% rownames(installed.packages()) == FALSE) {install.packages(pkg)
    lapply(pkgs, require, character.only = TRUE)}
  else {
    lapply(pkgs, require, character.only = TRUE)}
}
rm(pkg,pkgs)

# Coordinate reference systems
latlong = "+init=epsg:4326"
ukgrid = "+init=epsg:27700"
google = "+init=epsg:3857"

# UK sample viz bounding box:
topLeft <- c(-11.25, 58.813744) # x y
bottomRight <- c(5.625, 48.922497) # x y

bbox_x <- c(-11.25, 5.625)
bbox_y <- c(48.9, 58.8)

# Euro sample viz bounding box:
bbbox_x <- c(-12, 24)
bbbox_y <- c(42.5, 64.5)

bbox <-  cbind(bbox_x, bbox_y)
bbox <- bbox(bbox)
bbox

bbbox <-  cbind(bbbox_x, bbbox_y)
bbbox <- bbox(bbbox)
bbbox

# Setup
pixelSize <- 0.5 # degrees

# Read boundary
boundary <- geojson_read("../boundaries/Europe.geojson",what="sp") #Read GeoJSON
proj4string(boundary) <- latlong

# Create Polygon
pbbox <- as(raster::extent(bbox), "SpatialPolygons")
proj4string(pbbox) <- latlong

pbbbox <- as(raster::extent(bbbox), "SpatialPolygons")
proj4string(pbbbox) <- latlong

# Plot
plot(pbbbox)
plot(pbbox, add = T)
plot(boundary, add= T)


#Set seed (used for random component in point generation)
set.seed(5000)

system.time(
  points<- spsample(pbbbox,type="regular", pretty = TRUE, cellsize = pixelSize, offset=c(0.5,0.5)) #Define bounding box
)

points <- as.data.frame(cbind(seq(1:length(points)),points@coords[,1],points@coords[,2]))
points$z <- 1
colnames(points) <- c("id","x","y","z")

raster <- rasterFromXYZ(points[,c(2:4)], crs=latlong)
raster <- mask(raster, boundary)
plot(raster)
plot(boundary, add=TRUE)

# Colour array (low value = high snow)
colourArray <- as.array(raster)

# Convert to 3d array
array <- array(0, dim=c(nrow(raster),ncol(raster),4))
array[,,1] <- colourArray * 49/255
array[,,2] <- colourArray * 163/255
array[,,3] <- colourArray * 84/255
array[,,4] <- colourArray

writePNG(array, "Europe_0_5deg.png")
