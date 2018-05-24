//written by Carlos Padrón, padron.ca@gmail.com, carlos.florez.16@ucl.ac.uk
//it loads  openstreetmap tile service and geojson files

//---------------------libraries
// For map projections.
import org.gicentre.utils.spatial.*;    
//for math
import java.lang.Math.*;

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

//---------------------body
void setup() {
  size(768, 768);
  //instantiates image array and boundary box
  openstreetmap = new PImage[20][1024][1024];
  topLeftCorner = new PVector(0,0);
  bottomRightCorner = new PVector(0,0);
  //initial location (london) in degrees 4326
  coords = new PVector(-8.56, 57.77);
  //loads motorways
  json = loadJSONObject("openstreetmap_motorways_epsg_27700.geojson");
}
void draw()
{
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
  JSONArray values;
  values = json.getJSONArray("features");
  for (int i = 0; i < values.size(); i++) {
    JSONObject features = values.getJSONObject(i); 
    JSONObject properties = features.getJSONObject("properties");
    //gets road number
    String roadRef = properties.getString("ref");
    //println(roadRef);
    //gets coordinates
    JSONObject geometry = features.getJSONObject("geometry");
    JSONArray  coordinates = geometry.getJSONArray("coordinates");
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
  //copyright
  pushStyle();
  fill(0, 0, 0);
  text(copyright, 580, 760);
  popStyle();
  //stops looping
  noLoop();
}
//change location or scale and loop
void keyPressed() {
  if (key == '+') {
    zoom = constrain(zoom + 1, 6, 10);
    println(zoom);
    loop();
  } 
  else if  (key == '-') {
    zoom = constrain(zoom - 1, 6, 10);
    println(zoom);
    loop();
  } 
  else if (key == CODED) {
    if (keyCode == UP) {
      coords.y = constrain(coords.y+(20.0/zoom), 48.92249, 58.813744);
      loop();
    }
    else if (keyCode == DOWN) {
      coords.y = constrain(coords.y-(20.0/zoom), 48.92249, 58.813744);
      loop();
    }
    else if (keyCode == RIGHT) {
      coords.x = constrain(coords.x+(20.0/zoom), -11.25, 5.625 );
      loop();
    }
    else if (keyCode == LEFT) {
      coords.x = constrain(coords.x-(20.0/zoom), -11.25, 5.625 );
      loop();
    }
  }
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
