// Load and process light data
Table get_footfall() {
  footfall = loadTable("footfall/city_foot_data.csv", "header");
  println(footfall.getRowCount() + " total rows in table");
  return footfall;
}

PVector[] getCityPoints() {

  PVector[] city_locations = {
    new PVector(-14226.63, 6711542), // London
    new PVector(-288083.71, 6702087), // Bristol
    new PVector(-393391.95, 6571632), // Exeter
    new PVector(-156337.09, 6605336), // Southampton
    new PVector(-210438.36, 6888519), // Birmingham
    new PVector(-126881.95, 6916115), // Leicester
    new PVector(-249645.09, 7072433), // Manchester
    new PVector(-176430.26, 7318378), // Durham
    new PVector(-353895.79, 6706929), // Cardiff
    new PVector(-354919.93, 7549125), // Edinburgh
    new PVector(-473308.21, 7531429) // Glasgow
  };

  // Loop through vectors converting to pixel coordinates
  for (PVector point : city_locations) {
    PVector origin_vector = new PVector(origin[0], origin[1]);
    point = (point.sub(origin_vector)).div(scale);
    println(point.x);
    println(point.y);
    println("........");
  }
  return city_locations;
}

// draw city centres
void draw_centres() {
  for (int i = 0; i < city_locations.length; i++) {
    PVector location = city_locations[i];
    canvas.noStroke();
    canvas.fill(100);
    canvas.ellipse(location.x, -location.y, 5, 5);
  }
}

// draw footfall
void draw_footfall(int frameCounter) {

  for (int i = 0; i < city_locations.length; i++) {
    float count = footfall.getFloat(frameCounter, i+2);
    println("Row " + str(frameCounter) + " Column " + str(i+2) + ". Count: " + count);
    PVector location = city_locations[i];

    // Draw Ellipse
    canvas.stroke(255, 170);
    canvas.strokeWeight(2);
    int maxSize = 100;
    int minSize = 20;
    float red = map(count, 0, 1, 50, 120);
    ;
    float green = map(count, 0, 1, 50, 250);
    float blue = map(count, 0, 1, 20, 20);
    ;
    color ellipseColor = color(red, green, blue, 150);
    canvas.fill(ellipseColor);
    canvas.ellipse(location.x, -location.y, ((maxSize-minSize)*count)+minSize, ((maxSize-minSize)*count)+minSize);
  }
}
