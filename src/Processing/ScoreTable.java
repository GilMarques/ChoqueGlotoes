package Processing;

import processing.core.PApplet;
import processing.core.PVector;

import java.util.Arrays;

public class ScoreTable {
    PVector pos= new PVector();
    String[] Scores;
    String Text;
    PApplet p = MainProcessing.processing;
    ScoreTable(int x,int y,String s){
        pos.x = x;
        pos.y = y;
        Text = s;
    }
    void update(String[] scores) {
        Scores = scores;
    }

    void draw() {
        p.fill(0);
        p.text(Text, pos.x, pos.y);
        for (int i = 0; i < Scores.length; i += 2) {
            p.textSize(12);
            p.text(Scores[i] + "  " + Scores[i + 1], pos.x, pos.y+20 + i * 10);
        }

    }

}
