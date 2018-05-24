/////////////////////////////////////////////////////////
// Load raster images
PImage[] vectorArrayLoader(String path_in, String extension, float[] extends_in) {

  PImage[] image_in = new PImage[frames];

  for (int day = 0; day < days.length; day++) {
    for (int hour = 0; hour < hours.length; hour++) {
      for (int min = 0; min < mins.length; min++) { 
        int rasterIndex = min + (hour * mins.length) + (day * hours.length * mins.length);
        String rasterPath = path_in + "_" + days[day] + "_" + hours[hour] + "-" + mins[min] + "-00." + extension;
        image_in[rasterIndex] = loadImage(rasterPath);
        // tries to use previous image if null
        if (image_in[rasterIndex] == null) image_in[rasterIndex] = image_in[rasterIndex-1];
        //println("Loaded: " + rasterPath);
      }
    }
  } 
  // Calc twf
  float[] twf = calculateTWF(image_in[0], extends_in);

  // Trim
  image_in = vector_cutter(image_in, twf);

  println(image_in.length + " images loaded and trimmed from: " + path_in);
  return image_in;
}

/////////////////////////////////////////////////////////
// Process wind vectors
void getWindVectorsMaxMin() {

  float maxY = -1000;
  float maxX = -1000;
  float minY = 1000;
  float minX = 1000;

  for (int day = 0; day < days.length; day++) {
    for (int hour = 0; hour < hours.length; hour++) {
      for (int min = 0; min < mins.length; min++) {
        int rasterIndex = min + (hour * mins.length) + (day * hours.length * mins.length);
        // Find max and min pixel values
        for (int y = 0; y < wind_images[rasterIndex].height; y++) {
          for (int x = 0; x < wind_images[rasterIndex].width; x++) {
            int pixel = (y * wind_images[rasterIndex].width) + x;
            float tempY = red(wind_images[rasterIndex].pixels[pixel]) / 255;
            float tempX = alpha(wind_images[rasterIndex].pixels[pixel]) / 255;
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
}


/////////////////////////////////////////////////////////
// Draw wind vectors

void drawWind(int counter) {

  int vectorsX = wind_images[0].width;
  int vectorsY = wind_images[0].height;
  float scaleX = width/vectorsX;
  float scaleY = height/vectorsY;
  float minScale = min(scaleX, scaleY);
  float maxScale = max(scaleX, scaleY)*1.2;

  for (int y = 0; y < vectorsY; y++) {
    for (int x = 0; x < vectorsX; x++) {
      int pixel = (y * wind_images[counter].width) + x;
      int canvasX = int((x * scaleX) + (scaleX / 2));
      int canvasY = int((y * scaleY) + (scaleY / 2));

      float vectorY = red(wind_images[counter].pixels[pixel]) / 255;
      float vectorX = alpha(wind_images[counter].pixels[pixel]) / 255;
      float bearing = atan(vectorX/vectorY);
      float vel = sqrt(sq(vectorY) + sq(vectorX));
      float normVel = map(vel, minV, maxV, 0, 1);
      float mappedVel = map(normVel, 0, 1, 0, maxScale);

      float red = map(normVel, 0, 1, 100, 255);
      float green = map(normVel, 0, 1, 100, 40);
      float blue = map(normVel, 0, 1, 255, 40);

      if (show_visibility) { // Use lighter colours
        red = map(normVel, 0, 1, 200, 255);
        green = map(normVel, 0, 1, 200, 40);
        blue = map(normVel, 0, 1, 255, 40);
      }
      color vectorColor = color(red, green, blue, 150);

      canvas.stroke(vectorColor);
      canvas.fill(vectorColor);
      canvas.strokeWeight(map(normVel, 0, 1, 0, 5));

      canvas.pushMatrix();
      canvas.translate(canvasX, canvasY);
      canvas.rotate(bearing);
      canvas.translate(0, mappedVel/2);
      canvas.line(0, 0, 0, -mappedVel);
      canvas.pushMatrix();
      canvas.rotate(PI/4);
      canvas.line(0, 0, 0, -mappedVel/6);
      canvas.popMatrix();
      canvas.pushMatrix();
      canvas.rotate(-PI/4);
      canvas.line(0, 0, 0, -mappedVel/6);
      canvas.popMatrix();
      canvas.popMatrix();
    }
  }
}
