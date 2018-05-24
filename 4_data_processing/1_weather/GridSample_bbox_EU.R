#######################################################################
# Make Sample Grid from given bbox EUROPE
# Fred Shone
# 26th March 2018

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

# UK sample viz bounding box:
bbox_x <- c(-11.25, 5.625)
bbox_y <- c(48.9, 58.8)

# manually buffer bounding box
bbbox_x <- c(-12, 6)
bbbox_y <- c(48, 59)

# Euro sample viz bounding box:
bbbox_x <- c(-12, 48)
bbbox_y <- c(38, 62)

bbox <-  cbind(bbox_x, bbox_y)
bbox <- bbox(bbox)
bbox

bbbox <-  cbind(bbbox_x, bbbox_y)
bbbox <- bbox(bbbox)
bbbox

# Coordinate reference systems
latlong = "+init=epsg:4326"
ukgrid = "+init=epsg:27700"
google = "+init=epsg:3857"

# Setup
pixelSize <- 200000 # m
fileName <- "bboxEuroGrid_200_km.csv"

# Read boundary
boundary <- geojson_read("../boundaries/Europe.geojson",what="sp") #Read GeoJSON
boundary <- spTransform(boundary, google)

# Create Polygon
pbbox <- as(raster::extent(bbox), "SpatialPolygons")
proj4string(pbbox) <- latlong
pbbox <- spTransform(pbbox, google)

pbbbox <- as(raster::extent(bbbox), "SpatialPolygons")
proj4string(pbbbox) <- latlong
pbbbox <- spTransform(pbbbox, google)

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
colnames(points) <- c("id","x","y")

write.csv(points, fileName)

# Final bbox
finalbbox <- bbox(pbbbox)
print(finalbbox)
width <- (finalbbox[1,2] - finalbbox[1,1])
height <- (finalbbox[2,2] - finalbbox[2,1])
print(paste("width = ", width,"m"))
print(paste("height = ", height,"m"))
pWidth <- (finalbbox[1,2] - finalbbox[1,1])/pixelSize
pHeight <- (finalbbox[2,2] - finalbbox[2,1])/pixelSize
print(paste("width = ", pWidth,"pixels"))
print(paste("height = ", pHeight,"pixels"))
