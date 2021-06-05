package Processing;

import processing.core.PApplet;
import processing.core.PVector;

public class Obstacle {
    public PVector pos = new PVector();
    private float radius;

    PApplet p = MainProcessing.processing;
    Obstacle(float x,float y,float size) {
        pos.x = x;
        pos.y = y;
        radius = size;
    }
    public void draw() {
        p.fill(0,0,0);
        p.ellipse(pos.x, pos.y, radius*2, radius*2);
    }

}
