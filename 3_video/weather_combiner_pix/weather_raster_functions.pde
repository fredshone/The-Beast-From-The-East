/////////////////////////////////////////////////////////
// Load raster images
PImage[][] loadWeatherRasters() {

  for (int day = 0; day < days.length; day++) {
    for (int hour = 0; hour < hours.length; hour++) {
      for (int min = 0; min < mins.length; min++) { 
        for (int raster = 0; raster < rasterPaths.length; raster++) {
          int rasterIndex = min + (hour * mins.length) + (day * hours.length * mins.length);
          String rasterPath = rasterPaths[raster] + "_" + days[day] + "_" + hours[hour] + "-" + mins[min] + "-00.png";
          println("Loading " + rasterPath);
          rasters[rasterIndex][raster] = loadImage(rasterPath);
        }
      }
    }
  }
  return rasters;
}

/////////////////////////////////////////////////////////
// Display rasters

void drawRasters(int counter) {
  for (int raster = 0; raster < rasterPaths.length; raster++) {
    if (show_raster[raster]) image(rasters[counter][raster], 0, 0, width, height);
  }
}
