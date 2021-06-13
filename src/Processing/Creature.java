package Processing;

import processing.core.PVector;
import processing.core.*;

public class Creature {
    public PVector pos = new PVector();
    PApplet p = MainProcessing.processing;
    float red;
    float green;
    private float radius = 20.0f;
    private float angle = 0f;

    Creature() {
        pos.x = -99;
        pos.y = -99;
    }

    public void update(float x, float y, float a, float r, boolean isRed) {
        pos.x = x;
        pos.y = y;
        angle = a;
        radius = r;
        if (isRed) {
            red = 255f;
            green = 0f;
        } else {
            red = 0f;
            green = 255f;
        }
    }

    public void draw() {
        //p.ellipse(pos.x + radius * PApplet.cos(angle), pos.y + radius * PApplet.sin(angle), radius / 2, radius / 2);
        p.pushMatrix();
        p.rotate(angle);
        p.popMatrix();
        p.fill(red, green, 0f);
        p.circle(pos.x, pos.y, radius * 2);
    }
}
