//written by Carlos Padrón, padron.ca@gmail.com, carlos.florez.16@ucl.ac.uk
//it loads  openstreetmap tile service and geojson files

//---------------------libraries
// For map projections.
import org.gicentre.utils.spatial.*;    
//for math
import java.lang.Math.*;

Table lightchange;
int i = 0;
String[] datetime = new String[1248];

boolean start = false;
//---------------------global variable
//copyright
String copyright = "© OpenStreetMap contributors";
//upper-left corner coordinates 
PVector coords;
PVector projCoords;
int [] tiles;
PVector topLeftCorner;
PVector bottomRightCorner;
//zoom level (0 to 19)
int zoom = 6;
//openstreetmap cache (zoom, x, y)
PImage [][][] openstreetmap;
//motorways
JSONObject json;

String[] days = {"Feb25", "Feb26", "Feb27", "Feb28", 
  "Mar1", "Mar2", "Mar3", "Mar4", "Mar5", 
  "Mar6", "Mar7"};
String[] hours = {"0", "1", "2", "3", "5", "6", "7", "8", 
  "9", "10", "11", "12", "13", "14", 
  "15", "16", "17", "18", "19", "20", 
  "21", "22", "23"};

//---------------------body
void setup() {
  size(768, 768);
  //instantiates image array and boundary box
  openstreetmap = new PImage[20][1024][1024];
  topLeftCorner = new PVector(0, 0);
  bottomRightCorner = new PVector(0, 0);
  //initial location (london) in degrees 4326
  coords = new PVector(-8.56, 57.77);
  //loads motorways
  json = loadJSONObject("motorways_days.json");

  // day night transition
  frameRate(10);

  lightchange = loadTable("Daynight.csv", "header");
  println(lightchange.getRowCount() + " total rows in table"); 

  for (int i = 0; i < lightchange.getRowCount(); i++) {
    datetime[i] = lightchange.getString(i, 0);
  }
}
void draw()
{
  int frameCounter = (frameCount % 961);
  //day night transition
  println(frameCount);

  fill(0);
  textSize(24);
  text(datetime[frameCounter], 450, 50);

  noStroke();
  if (lightchange.getInt(frameCounter, 1) == 0) {
    tint(255, 100);
    image(loadImage("l0.png"), 0, 0);
  } else if (lightchange.getInt(frameCounter, 1) == 1) {
    tint(255, 100);
    image(loadImage("l1.png"), 0, 0);
  } else if (lightchange.getInt(frameCounter, 1) == 2) {
    tint(255, 100);
    image(loadImage("l2.png"), 0, 0);
  } else if (lightchange.getInt(frameCounter, 1) == 3) {
    tint(255, 100);
    image(loadImage("l3.png"), 0, 0);
  } else if (lightchange.getInt(frameCounter, 1) == 4) {
    tint(255, 100);
    image(loadImage("l4.png"), 0, 0);
  } 
  

  //gets tile numbers
  tiles = tile(coords.x, coords.y);  
  //draws all tiles (3x3)
  for (int i=0; i<3; i++) {
    for (int j=0; j<3; j++) {
      String sZoom = str(zoom);
      String x = str(tiles[0]+i);
      String y = str(tiles[1]+j);      
      String url = "https://tile.openstreetmap.org/"+sZoom+"/"+x+"/"+y+".png";
      //checks cache
      if (openstreetmap[zoom][tiles[0]+i][tiles[1]+j] == null) {
        openstreetmap[zoom][tiles[0]+i][tiles[1]+j] = loadImage(url, "png");
      }
      // Load image from openstreetmap
      image(openstreetmap[zoom][tiles[0]+i][tiles[1]+j], 256*i, 256*j);
      //for user information
      println(url);
    }
  }

  //draw motorways
  int frameCounter_hour = (frameCount % 241);
  int index = 0;
  Integer Value;
  JSONArray values;
  float transparency;
  values = json.getJSONArray("features");

  //iterate over all the entries in json file
  for (int i = 0; i < values.size(); i++) {
    JSONObject features = values.getJSONObject(i); 
    JSONObject properties = features.getJSONObject("properties");
    String roadRef = properties.getString("RoadNumber");
    //gets coordinates
    JSONObject geometry = features.getJSONObject("geometry");
    JSONArray  coordinates = geometry.getJSONArray("coordinates");

    //for (int d = 0; d < 9; d++) {
      //for (int h = 0; h < 23; h++) { 
        //String timestamp = days[d] + "_" + hours[h];
        //index = h + d * 24;
        // set trend value to transparency 
        Value = properties.getInt("Mar2_12");
        transparency = map(Value, 0, 7000, 20, 255);      
        
        strokeWeight(2);
        stroke(255, 0, 0, transparency);
        // draw motorways
        beginShape();
        for (int j = 0; j < coordinates.size(); j++) {
          JSONArray coord = coordinates.getJSONArray(j);
          PVector coordVector = new PVector(coord.getFloat(0), coord.getFloat(1));
          //transform epsg:27700 to epsg:3857
          OSGB geo = new OSGB();
          WebMercator proj = new WebMercator();
          PVector geoCoords = geo.invTransformCoords(coordVector);   
          PVector projCoords = proj.transformCoords(geoCoords);  
          PVector projTopLeftCorner = proj.transformCoords(topLeftCorner);       
          PVector projBottomRightCorner = proj.transformCoords(bottomRightCorner);       
          float x = map(projCoords.x, projTopLeftCorner.x, projBottomRightCorner.x, 0, width);
          float y = height-map(projCoords.y, projBottomRightCorner.y, projTopLeftCorner.y, 0, height);
          vertex(x, y);
        }
        endShape();
     }
    //}
  //}  
}


//transform epsg:4326 coordinates to tile numbers
int[] tile(float x, float y) {
  //calculates amount of tiles
  float n = pow(2, zoom);
  //transform to tiles
  int xtile = floor((x + 180)/360 * n);
  int ytile = floor((1 - log(tan(radians(y)) + 1/cos(radians(y)))/PI)/2 * n);
  if (xtile < 0) {
    xtile = floor(pow(2, zoom)-1);
  } else if (xtile > floor(pow(2, zoom)-1)) {
    xtile = 0;
  }
  if (ytile < 0) {
    ytile = floor(pow(2, zoom)-1);
  } else if (ytile > floor(pow(2, zoom)-1)) {
    ytile = 0;
  }
  //calculates boundary box
  topLeftCorner.x = xtile / n * 360.0 - 180.0;
  double n2 = PI - (2.0 * PI * ytile) / pow(2.0, zoom);
  topLeftCorner.y = (float)Math.toDegrees(Math.atan(Math.sinh(n2)));
  bottomRightCorner.x = (xtile + 3) / n * 360.0 - 180.0;
  double n3 = PI - (2.0 * PI * (ytile + 3)) / pow(2.0, zoom);
  bottomRightCorner.y = (float)Math.toDegrees(Math.atan(Math.sinh(n3)));
  println(topLeftCorner.x);
  println(topLeftCorner.y);  
  println(bottomRightCorner.x);
  println(bottomRightCorner.y);  
  //returns tiles
  int[] result = {xtile, ytile}; 
  return result;
}