// Function to calculate twf from example image and extends (xmin, xmax, ymin, ymax)
float[] calculateTWF(PImage image_in, float[] extends_in) {
  
  float size_x = extends_in[1] - extends_in[0];
  float size_y = extends_in[3] - extends_in[2];

  // Get example image pixel size
  int pix_x = image_in.width;
  int pix_y = image_in.height;

  float[] twf_out = new float[6];
  //pixel size in the x-direction in map units/pixel
  twf_out[0] = size_x / pix_x;
  //rotation about y-axis
  twf_out[1] = 0 ;
  //rotation about x-axis
  twf_out[2] = 0 ;
  //pixel size in the y-direction in map units, almost always negative
  twf_out[3] = - size_y / pix_y;
  //x-coordinate of the center of the upper left pixel
  twf_out[4] = extends_in[0];
  //y-coordinate of the center of the upper left pixel
  twf_out[5] = extends_in[3];
  
  return twf_out;
}

/////////////////////////////////////////////////////
// Functions to cut images to canvas size
PImage image_cutter(PImage image_in, float[] twf_in) {
  float x = (origin[0] - twf_in[4])/twf_in[0];
  float y = (origin[1] - twf_in[5])/twf_in[3];
  float cut_x = (width*scale) / twf_in[0];
  float cut_y = - (height*scale) / twf_in[3];   
  image_in = image_in.get(int(x), int(y), int(cut_x), int(cut_y));
  image_in.resize(width, height);
  return image_in;
}

// For Array
PImage[] image_cutter(PImage image_in[], float[] twf_in) {
  float x = (origin[0] - twf_in[4])/twf_in[0];
  float y = (origin[1] - twf_in[5])/twf_in[3];
  float cut_x = (width*scale) / twf_in[0];
  float cut_y = - (height*scale) / twf_in[3];
  for (int rasterIndex = 0; rasterIndex < image_in.length; rasterIndex++) {
    image_in[rasterIndex] = image_in[rasterIndex].get(int(x), int(y), int(cut_x), int(cut_y));
    image_in[rasterIndex].resize(width, height);
  }
  return image_in;
}

// For Vector Array
PImage[] vector_cutter(PImage image_in[], float[] twf_in) {
  float x = (origin[0] - twf_in[4])/twf_in[0];
  float y = (origin[1] - twf_in[5])/twf_in[3];
  float cut_x = (width*scale) / twf_in[0];
  float cut_y = - (height*scale) / twf_in[3];
  for (int rasterIndex = 0; rasterIndex < image_in.length; rasterIndex++) {
    image_in[rasterIndex] = image_in[rasterIndex].get(int(x), int(y), int(cut_x), int(cut_y));
  }
  return image_in;
}
