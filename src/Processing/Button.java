package Processing;

import processing.core.PApplet;

public class Button {
    PApplet p = MainProcessing.processing;
    int x, y, w, h;
    String s;
    public boolean hovered = false;
    Button(int x, int y, int w, int h, String t) {
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.s = t;
    }

    void draw() {
        p.fill(hovered ? 200 : 255);
        p.rect(x, y, w, h);
        p.textAlign(p.CENTER, p.CENTER);
        p.fill(0);
        p.textSize(32);
        p.text(s, x + w / 2, y + h / 2);
    }

    void isOver(int mx, int my) {
        hovered = mx >= x && mx <= x + w && my >= y && my <= y + h;
    }
}
