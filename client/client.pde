void setup(){
  size(960,540);
}

void draw() {
  background(255);
  if (mousePressed) {
    fill(0);
  } else {
    fill(255);
  }
  ellipse(mouseX, mouseY, 80, 80);
}
