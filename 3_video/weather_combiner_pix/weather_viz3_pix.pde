/////////////////////////////////////////////////////////
// Weather Visualisation Test
// Fred Shone 26/4/18
// Script for loading and displaying weather rasters, including drawing wind vectors.
// Weather rasters are pre processed in R and exported to Processing as .png

// Bounding box (WGS 84):
// topLeft <- c(-11.25, 58.813744) # x y
// bottomRight <- c(5.625, 48.922497) # x y

// Settings
// all rasters and vectors will be loaded as images but draw can be switched below:
boolean[] show_raster = {true, true, false}; // {snow, air_temp, visibility}
boolean show_wind = true;

/////////////////////////////////////////////////////////
// Rasters
PImage UK;
PImage[][] rasters; // {"snow_depth", "air_temp", "visibility"}
PImage[] windRaster;

/////////////////////////////////////////////////////////
// Wind Vectors
float maxV;
float minV;

/////////////////////////////////////////////////////////
// Weather paths
String[] rasterPaths = {"snow_depth", "air_temp", "visibility"};
String windPath = "wind";

/////////////////////////////////////////////////////////
// Clock Setup
String[] days = {"2018-02-27", 
  "2018-02-28"};
String[] hours = {"00", "01", "02", "03", "04", "05", 
  "06", "07", "08", "09", "10", "11", 
  "12", "13", "14", "15", "16", "17", 
  "18", "19", "20", "21", "22", "23"}; 
String[] mins = {"00", "15", "30", "45"};
String[] timeStamps;
int frames = days.length * hours.length * mins.length;

/////////////////////////////////////////////////////////

void setup() {

  size(800, 800);
  background(#FEFF00);

  /////////////////////////////////////////////////////////
  // Load UK map
  UK = loadImage("UK_0_25deg.png");

  /////////////////////////////////////////////////////////
  // Load time stamps
  timeStamps = new String[frames];
  loadTimeStamps();

  /////////////////////////////////////////////////////////
  // Load raster images
  rasters = new PImage[frames][rasterPaths.length];
  rasters = loadWeatherRasters();

  /////////////////////////////////////////////////////////
  // Load and process wind raster images
  windRaster = new PImage[frames];
  windRaster = loadWindVectors();

  frameRate(6);
}

void draw() {
  background(158,202,225);
  int frameCounter = (frameCount % (frames));

  /////////////////////////////////////////////////////////
  // Draw UK
  drawMap();
    
  //image(UK, 0, 0, width, height);

  /////////////////////////////////////////////////////////
  // Draw weather rasters
  drawRasters(frameCounter);

  /////////////////////////////////////////////////////////
  // Draw wind vectors
  if (show_wind) drawWind(frameCounter);

  /////////////////////////////////////////////////////////
  // Draw timeStamp
  drawTimeStamp(frameCounter);
  
  //saveFrame("video/###.png");
}
