/////////////////////////////////////////////////////////
// Draw pixelated background map
void drawMap() {
  // Loop through pixels drawing UK grid
  int pixX = UK.width;
  int pixY = UK.height;
  println(pixX);
  println(pixY);
  float gridX = width / pixX;
  float gridY = height / pixY;
  println(gridX);
  println(gridY);

  for (int y = 0; y < pixY; y++) {
    for (int x = 0; x < pixX; x++) {
      int pixel = (y * UK.width) + x;

      if (alpha(UK.pixels[pixel]) > 0) {

        color fill = color(UK.pixels[pixel]);
        float canvasX = x * gridX;
        float canvasY = y * gridY;

        stroke(255);
        fill(fill);
        strokeWeight(2);
        rect(canvasX, canvasY, gridX, gridY);
      }
    }
  }
}
