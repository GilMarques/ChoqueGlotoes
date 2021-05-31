class Player {
  float x=10, y=10;
  float angle=0;
  float radius=20;
  color colr = color (random(0, 255), random(0, 255), random(0, 255));
  public void update() {
  }

  public void draw() {
    ellipseMode(RADIUS);
    this.x = mouseX;
    this.y = mouseY;
    fill(colr);
    ellipse(this.x, this.y, this.radius, this.radius);
    fill(0);
    ellipse(this.x+this.radius*cos(this.angle), this.y-this.radius*sin(this.angle), 2, 2);
    noFill();
  }
}
