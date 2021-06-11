package Processing;

import processing.core.PApplet;
import processing.core.PImage;

public class Battery {
    float capacity = 1f;
    float x,y,w,h;
    PApplet p = MainProcessing.processing;
    PImage img;

    Battery(int x,int y ,int w,int h){
        img = p.loadImage("lib/battery.png");
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
    }

    void update(float newcapacity){
        capacity = newcapacity;
    }

    void draw(){
        p.fill(0,255,0);
        p.rect(x+w/4,2.35f*y,w/2,h*capacity-2.35f*y,20);
        p.image(img,x,y,w,h);
        p.fill(0);
        p.text((int) (capacity * 100f) +"%",x+w/2,y+0.8f*h);
    }

}
