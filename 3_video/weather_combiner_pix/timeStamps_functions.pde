/////////////////////////////////////////////////////////
// Load time stamps
void loadTimeStamps() {

  for (int day = 0; day < days.length; day++) {
    for (int hour = 0; hour < hours.length; hour++) {
      for (int min = 0; min < mins.length; min++) { 
        int index = min + (hour * mins.length) + (day * hours.length * mins.length);
        String timeStamp = days[day] + " " + hours[hour] + ":" + mins[min] + ":00";
        timeStamps[index] = timeStamp;
      }
    }
  }
}

/////////////////////////////////////////////////////////
// Draw timeStamp
void drawTimeStamp(int counter) {
  fill(0);
  text(timeStamps[counter], 0, 20);
}
