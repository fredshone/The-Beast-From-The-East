// Load and process light data
Table get_transition() {
  lightchange = loadTable("transition/Daynight.csv", "header");
  println(lightchange.getRowCount() + " total rows in table");
  return lightchange;
}

// draw transition
void draw_transition(int frameCounter) {
  int dark = lightchange.getInt(frameCounter*4, 1);
  canvas.noStroke();
  canvas.fill(40, 10, 60, 28*dark);
  canvas.rect(0, 0, width, height);
}
