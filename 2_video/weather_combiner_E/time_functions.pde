/////////////////////////////////////////////////////////
// Load time stamps (long format)
void loadTimeStamps() {

  for (int day = 0; day < days_long.length; day++) {
    for (int hour = 0; hour < hours.length; hour++) {
      for (int min = 0; min < mins.length; min++) { 
        int index = min + (hour * mins.length) + (day * hours.length * mins.length);
        String timeStamp = days_long[day] + "  " + hours[hour] + ":" + mins[min] + ":00";
        timeStamps[index] = timeStamp;
      }
    }
  }
}

/////////////////////////////////////////////////////////
// Draw timeStamp
void drawTimeStamp(int counter) {
  canvas.noStroke();
  canvas.fill(255);
  canvas.rect(1200,90,350,44,5);
  canvas.textSize(32);
  canvas.textAlign(RIGHT);
  canvas.fill(0);
  canvas.textFont(font);
  canvas.text(timeStamps[counter], width-90, 115);
}
