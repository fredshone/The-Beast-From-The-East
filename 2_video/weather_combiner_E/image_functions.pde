/////////////////////////////////////////////////////////
// Load raster images
PImage[] imageArrayLoader(String path_in, String extension, float[] extends_in) {

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
  image_in = image_cutter(image_in, twf);

  println(image_in.length + " images loaded and trimmed from: " + path_in);
  return image_in;
}


/////////////////////////////////////////////////////////
// Display rasters

void drawImage(PImage[] images_in, int counter) {  
  canvas.image(images_in[counter], 0, 0, width, height);
}
