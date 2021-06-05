package Processing;

import processing.core.PVector;
import processing.core.*;


public class Player {
    public PVector pos = new PVector();
    private  float radius = 20.0f;
    private  float angle = 0f;
    PApplet p = MainProcessing.processing;
    float red =  p.random(0, 255);
    float green =  p.random(0, 255);
    float blue =  p.random(0, 255);

    Player() {
        pos.x = -99;
        pos.y = -99;
    }

    public void update(float x, float y, float a, float r) {
        pos.x = x;
        pos.y = y;
        angle = a;
        radius = r;
    }

    public void draw() {
        p.ellipse(pos.x + 2*radius * PApplet.cos(angle), pos.y + 2*radius * PApplet.sin(angle), 1, 1);
        p.pushMatrix();
        p.rotate(angle);
        p.popMatrix();
        p.fill(red,green,blue,50f);
        p.ellipse(pos.x, pos.y, radius*2, radius*2);
    }
}
