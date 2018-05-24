/////////////////////////////////////////////////////////
// Load and process wind raster images

PImage[] loadWindVectors() {

  float maxY = -1000;
  float maxX = -1000;
  float minY = 1000;
  float minX = 1000;

  for (int day = 0; day < days.length; day++) {
    for (int hour = 0; hour < hours.length; hour++) {
      for (int min = 0; min < mins.length; min++) {
        // Load wind vector images
        int rasterIndex = min + (hour * mins.length) + (day * hours.length * mins.length);
        String windPath = "wind" + "_" + days[day] + "_" + hours[hour] + "-" + mins[min] + "-00.png";
        println("Loading " + windPath);
        windRaster[rasterIndex] = loadImage(windPath);
        // Find max and min pixel values
        for (int y = 0; y < windRaster[rasterIndex].height; y++) {
          for (int x = 0; x < windRaster[rasterIndex].width; x++) {
            int pixel = (y * windRaster[rasterIndex].width) + x;
            float tempY = red(windRaster[rasterIndex].pixels[pixel]) / 255;
            float tempX = alpha(windRaster[rasterIndex].pixels[pixel]) / 255;
            if (tempY > maxY) maxY = tempY;
            if (tempX > maxX) maxX = tempX;
            if (tempY < minY) minY = tempY;
            if (tempX < minX) minX = tempX;
          }
        }
      }
    }
  }
  maxV = sqrt(sq(maxX) + sq(maxY));
  minV = sqrt(sq(minX) + sq(minY));
  println("Max Y vector = " + maxY);
  println("Max X vector = " + maxX);
  println("Min Y vector = " + minY);
  println("Min X vector = " + minX);
  println("Max Vector = " + maxV);
  println("Min Vector = " + minV);
  return windRaster;
}

/////////////////////////////////////////////////////////
// Draw wind vectors

void drawWind(int counter) {

  int vectorsX = windRaster[0].width;
  int vectorsY = windRaster[0].height;
  float scaleX = width/vectorsX;
  float scaleY = height/vectorsY;
  float minScale = min(scaleX, scaleY);
  float maxScale = max(scaleX, scaleY);

  for (int y = 0; y < vectorsY; y++) {
    for (int x = 0; x < vectorsX; x++) {
      int pixel = (y * windRaster[counter].width) + x;
      int canvasX = int((x * scaleX) + (scaleX / 2));
      int canvasY = int((y * scaleY) + (scaleY / 2));

      float vectorY = red(windRaster[counter].pixels[pixel]) / 255;
      float vectorX = alpha(windRaster[counter].pixels[pixel]) / 255;
      float bearing = atan(vectorX/vectorY);
      float vel = sqrt(sq(vectorY) + sq(vectorX));
      float normVel = map(vel, minV, maxV, 0, 1);
      float mappedVel = map(normVel, 0, 1, 0, maxScale);

      float red = map(normVel, 0, 1, 70, 255);
      float green = map(normVel, 0, 1, 70, 40);
      float blue = map(normVel, 0, 1, 70, 40);
      color vectorColor = color(red, green, blue, 150);

      stroke(vectorColor);
      fill(vectorColor);
      strokeWeight(map(normVel, 0, 1, 0.5, 2));

      pushMatrix();
      translate(canvasX, canvasY);
      rotate(bearing);
      translate(0, mappedVel/2);
      line(0, 0, 0, -mappedVel/2);
      pushMatrix();
      rotate(PI/4);
      line(0, 0, 0, -mappedVel/8);
      popMatrix();
      pushMatrix();
      rotate(-PI/4);
      line(0, 0, 0, -mappedVel/8);
      popMatrix();
      popMatrix();
    }
  }
}
