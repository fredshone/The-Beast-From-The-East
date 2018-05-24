/////////////////////////////////////////////////////////
// Weather Visualisation Test
// Fred Shone 26/4/18
// Script for loading and displaying weather rasters, including drawing wind vectors.
// Weather Images are pre processed in R and exported to Processing as .png

//INPUT EXTENDS
//CHECK PATHS
//ADJUST BBOXES


/////////////////////////////////////////////////////////
// USER SETTINGS
boolean record = true;
String outputPath = "cancellations_AT/frame_";

boolean show_background = false; //Else transparent canvas
boolean show_basemap = true;
boolean show_snow = true;
boolean show_transition = true;

//Data Options
boolean show_speed = false;
boolean show_flow = false;
boolean show_google = false;
boolean show_rail = true;
boolean show_footfall = false;

//Weather Options
boolean show_temp = true;
boolean show_visibility = false;
boolean show_wind = false;

//Extras
boolean show_time = true;
boolean show_centres = false;
boolean show_labels = true;

/////////////////////////////////////////////////////////
// Setup sketch dimensions
//// UK crop, omitts most of ireland and northern scotland. Fits Google network well
float[] origin = {-750000.0, 7600000.0}; // xmin ymax (WGS 3857)
int scale = 1500; //m per pix

// England crop, omitts most of ireland and scotland. Fits Road network well
//float[] origin = {-600000.0, 7300000.0}; // xmin ymax (WGS 3857)
//int scale = 1100; //m per pix

/////////////////////////////////////////////////////////
// Setup projections (WGS 3857)
float[] background_twf;
float[] label_twf;
float[] weather_twf;
float[] road_twf;
float[] google_twf;
float[] rail_twf;

/////////////////////////////////////////////////////////
// Paths
String basemapPath = "basemap/basemap.png";
String labelsPath = "basemap/basemap_text.png";
String snowPath = "weather/snow_depth/snow_depth";
String airTempPath = "weather/air_temp/air_temp";
String visibilityPath = "weather/visibility/visibility";
String windPath = "weather/wind/wind";
String avgSpeedPath = "road/avg_speed/avg_speed";
String avgFlowPath = "road/total_volume2/total_volume";
String googleTrendsPath = "google_trends/google_trend";
String railPath = "rail/google_trend";

/////////////////////////////////////////////////////////
// Canvas
PGraphics canvas;
// Images
PImage background;
PImage[] snow_images;
PImage[] temp_images;
PImage[] visibility_images;
PImage[] wind_images;
PImage[] speed_images;
PImage[] flow_images;
PImage[] google_images;
PImage[] rail_images;
PImage labels;

/////////////////////////////////////////////////////////
// Wind Vectors
float maxV;
float minV;

/////////////////////////////////////////////////////////
// Light paths
Table lightchange;
String[] datetime;

/////////////////////////////////////////////////////////
// Footfall paths
Table footfall;
PVector[] city_locations;

/////////////////////////////////////////////////////////
// Clock Setup
String[] days = {"2018-02-26", "2018-02-27", "2018-02-28", "2018-03-01", "2018-03-02", "2018-03-03", "2018-03-04", "2018-03-05"};

//String[] days = {"2018-02-26"};

String[] hours = {"00", "01", "02", "03", "04", "05", 
  "06", "07", "08", "09", "10", "11", 
  "12", "13", "14", "15", "16", "17", 
  "18", "19", "20", "21", "22", "23"};

String[] mins = {"00", "15", "30", "45"};
//String[] mins = {"00"};

PFont font;
int frames = days.length * hours.length * mins.length;

String[] days_long = {
  "Monday, 26th of February", "Tuesday, 27th of February", "Wednesday, 28th of February", 
  "Thursday, 1st of March", "Friday, 2nd of March", "Saturday, 3rd of March", "Sunday, 4th of March", 
  "Monday, 5th of March"};

//String[] days_long = {"Monday, 26th of February"};

String[] timeStamps;

/////////////////////////////////////////////////////////

void setup() {

  size(800, 800, P2D);
  canvas = createGraphics(width, height, P2D);

  /////////////////////////////////////////////////////////
  // Setup background projection (WGS 3857) twf taken from QGIS
  background_twf = new float[6];
  //pixel size in the x-direction in map units/pixel
  background_twf[0] = 2670.61814085945024999;
  //rotation about y-axis
  background_twf[1] = 0 ;
  //rotation about x-axis
  background_twf[2] = 0 ;
  //pixel size in the y-direction in map units, almost always negative
  background_twf[3] = -2670.61814085945024999;
  //x-coordinate of the center of the upper left pixel
  background_twf[4] = -1511144.12523297197185457;
  //y-coordinate of the center of the upper left pixel
  background_twf[5] = 7691125.90109036676585674;

  /////////////////////////////////////////////////////////
  // SETUP BACKGROUND IMAGE
  if (show_basemap) {
    background = loadImage(basemapPath);
    //cutting pixels  
    background = image_cutter(background, background_twf);
    println("Background Image loaded and clipped.");
  }

  /////////////////////////////////////////////////////////
  // Setup label projection (WGS 3857) twf taken from QGIS
  label_twf = new float[6];
  //pixel size in the x-direction in map units/pixel
  background_twf[0] = 296.370968044234;
  //rotation about y-axis
  background_twf[1] = 0 ;
  //rotation about x-axis
  background_twf[2] = 0 ;
  //pixel size in the y-direction in map units, almost always negative
  background_twf[3] = -296.407185931077;
  //x-coordinate of the center of the upper left pixel
  background_twf[4] = -560074.276688364334;
  //y-coordinate of the center of the upper left pixel
  background_twf[5] = 7584518.442815987393;

  /////////////////////////////////////////////////////////
  // SETUP LABELS IMAGE
  if (show_labels) {
    labels = loadImage(labelsPath);
    //cutting pixels  
    labels = image_cutter(labels, background_twf);
    println("Labels Image loaded and clipped.");
  }

  /////////////////////////////////////////////////////////
  // SETUP WEATHER IMAGES
  float[] weather_extent = {-1335834.0, 667916.9, 6106855.0, 8180387.0}; // (xmin, xmax, ymin, ymax) extracted from R sampling sketch
  if (show_snow) snow_images = imageArrayLoader(snowPath, "png", weather_extent);
  if (show_temp) temp_images = imageArrayLoader(airTempPath, "png", weather_extent);
  if (show_visibility) visibility_images = imageArrayLoader(visibilityPath, "png", weather_extent);
  if (show_wind) {
    wind_images = vectorArrayLoader(windPath, "png", weather_extent);
    getWindVectorsMaxMin();
  }

  /////////////////////////////////////////////////////////
  // SETUP ROAD IMAGES
  float[] road_extent = {-375925.32, 129427.87, 6589251.88, 7136936.77}; // (xmin, xmax, ymin, ymax) extracted from R sampling sketch
  if (show_speed) speed_images = imageArrayLoader(avgSpeedPath, "gif", road_extent);
  if (show_flow) flow_images = imageArrayLoader(avgFlowPath, "gif", road_extent);

  /////////////////////////////////////////////////////////
  // SETUP GOOGLE TREND IMAGES
  float[] google_extent = {-511170.8933515555108897,175829.1066484444891103, 6558876.7133811684325337, 7637876.7133811684325337}; // (xmin, xmax, ymin, ymax) extracted from R sampling sketch
  if (show_google) google_images = imageArrayLoader(googleTrendsPath, "gif", google_extent);

  /////////////////////////////////////////////////////////
  // SETUP RAIL IMAGES
  float[] rail_extent = {-705625.6734469067305326, 264374.3265530932694674, 6467413.8877543359994888, 8094413.8877543359994888}; // (xmin, xmax, ymin, ymax) extracted from QGIS
  if (show_rail) rail_images = imageArrayLoader(railPath, "gif", rail_extent);

  /////////////////////////////////////////////////////////
  // TIME STAMPS
  if (show_time) font = createFont("Dialog", 16);
  if (show_time) canvas.textFont(font);
  if (show_time) timeStamps = new String[frames];
  if (show_time) loadTimeStamps();

  /////////////////////////////////////////////////////////
  // LIGHT TRANSITION
  if (show_transition) lightchange = get_transition();

  /////////////////////////////////////////////////////////
  // Load and process footfall data
  if (show_footfall) footfall = get_footfall();
  if (show_footfall) city_locations = getCityPoints();

  /////////////////////////////////////////////////////////
  frameRate(12);
}

void draw() {
  background(255);
  canvas.beginDraw();
  canvas.clear();

  if (show_background) background(158, 202, 225);

  int frameCounter = ((frameCount-1) % (frames));

  println(timeStamps[frameCounter]);

  /////////////////////////////////////////////////////////
  // Draw basemap
  if (show_basemap) canvas.image(background, 0, 0, width, height);
  // Draw snow
  if (show_snow) drawImage(snow_images, frameCounter);
  // Draw transition
  if (show_transition) draw_transition(frameCounter); // CURRENTLY ASSUMES 15min INTERVALS

  // Draw Data
  if (show_speed) drawImage(speed_images, frameCounter);
  if (show_flow) drawImage(flow_images, frameCounter);
  if (show_google) drawImage(google_images, frameCounter);
  if (show_rail) drawImage(rail_images, frameCounter);
  if (show_footfall) draw_footfall(frameCounter); // CURRENTLY ASSUMES 15min INTERVALS

  // Draw weather
  if (show_temp) drawImage(temp_images, frameCounter);
  if (show_visibility) drawImage(visibility_images, frameCounter);

  // draw wind
  if (show_wind) drawWind(frameCounter);
  // Draw labels
  if (show_labels) canvas.image(labels, 0, 0, width, height);
  // draw city centres
  if (show_centres) draw_centres();
  // Draw timeStamp
  if (show_time) drawTimeStamp(frameCounter);


  /////////////////////////////////////////////////////////
  // Draw canvas
  canvas.tint(255);
  canvas.endDraw();
  image(canvas, 0, 0);

  if (record) canvas.save(outputPath + nf(frameCounter, 4) + ".png");
  if (frameCounter == frames-1) noLoop();
}
