package Processing;
import org.json.*;
import processing.core.PApplet;

import java.util.ArrayList;

public class MainProcessing extends PApplet {
    public static PApplet processing;
    Link l;
    private boolean up, left, right;
    private ArrayList<Player> players = new ArrayList<Player>();
    private ArrayList<Obstacle> obstacles = new ArrayList<Obstacle>();
    private ArrayList<Player> creatures = new ArrayList<Player>();
    public static void main(String[] args) {
        PApplet.main("Processing.MainProcessing", args);
    }

    public void settings() {
        size(1280, 720);
    }

    public void setup() {
        frameRate(60);
        processing = this;
        players.add(new Player());
        players.add(new Player());
        players.add(new Player());
        creatures.add(new Player());
        l = new Link();
        l.connect("localhost", 5026);
        try {
            Thread.sleep(500);
        } catch (InterruptedException e) {
        }
        String jsonString = "{\n" +
                "\"players\" : \n" +
                "{\n" +
                "\"1\" : [50.0,50.0,50.0,50.0],\n" +
                "\"2\" : [X,Y,A,R]\n" +
                "},\n" +
                "\"creatures\":\n" +
                "{\n" +
                "\"1\" : [X,Y,A,R],\n" +
                "\"2\" : [X,Y,A,R]\n" +
                "}\n" +
                "}";
        JSONObject obj = null;
        try {
           obj = new JSONObject(jsonString);
           JSONObject pl = obj.getJSONObject("players");
           JSONArray arr = pl.getJSONArray("1");
        } catch (JSONException e) {}
        try {
            Thread.sleep(500);
        } catch (InterruptedException e) {
        }

        String r;
        r = l.read();
        System.out.println(r);

        String[] strings = r.split(" ");
        obstacles.add(new Obstacle(Float.parseFloat(strings[0]), Float.parseFloat(strings[1]), Float.parseFloat(strings[2])));
        obstacles.add(new Obstacle(Float.parseFloat(strings[3]), Float.parseFloat(strings[4]), Float.parseFloat(strings[5])));
        obstacles.add(new Obstacle(Float.parseFloat(strings[6]), Float.parseFloat(strings[7]), Float.parseFloat(strings[8])));
        obstacles.add(new Obstacle(Float.parseFloat(strings[9]), Float.parseFloat(strings[10]), Float.parseFloat(strings[11])));

    }

    public void draw() {
        background(255);
        String r;
        for (Obstacle o : obstacles) {
            o.draw();
        }
        if (frameCount % 1 == 0) {
            r = l.read();
            //update positions
            String[] division = r.split("Creatures");
            String[] stringsp = division[0].split(" ");
            int nj = stringsp.length / 5;

            switch (nj) {
                case (1) -> {
                    int p1 = Integer.parseInt(stringsp[0]);
                    float x = Float.parseFloat(stringsp[1]);
                    float y = Float.parseFloat(stringsp[2]);
                    float ang = Float.parseFloat(stringsp[3]);
                    float rad = Float.parseFloat(stringsp[4]);
                    players.get(p1 - 1).update(x, y, ang, rad);

                }

                case (2) -> {
                    int p1 = Integer.parseInt(stringsp[0]);
                    float x = Float.parseFloat(stringsp[1]);
                    float y = Float.parseFloat(stringsp[2]);
                    float ang = Float.parseFloat(stringsp[3]);
                    float rad = Float.parseFloat(stringsp[4]);
                    players.get(p1 - 1).update(x, y, ang, rad);
                    p1 = Integer.parseInt(stringsp[5]);
                    x = Float.parseFloat(stringsp[6]);
                    y = Float.parseFloat(stringsp[7]);
                    ang = Float.parseFloat(stringsp[8]);
                    rad = Float.parseFloat(stringsp[9]);
                    players.get(p1 - 1).update(x, y, ang, rad);


                }
                case (3) -> {
                    int p1 = Integer.parseInt(stringsp[0]);
                    float x = Float.parseFloat(stringsp[1]);
                    float y = Float.parseFloat(stringsp[2]);
                    float ang = Float.parseFloat(stringsp[3]);
                    float rad = Float.parseFloat(stringsp[4]);
                    players.get(p1 - 1).update(x, y, ang, rad);
                     p1 = Integer.parseInt(stringsp[5]);
                     x = Float.parseFloat(stringsp[6]);
                     y = Float.parseFloat(stringsp[7]);
                     ang = Float.parseFloat(stringsp[8]);
                     rad = Float.parseFloat(stringsp[9]);
                    players.get(p1 - 1).update(x, y, ang, rad);
                     p1 = Integer.parseInt(stringsp[10]);
                     x = Float.parseFloat(stringsp[11]);
                     y = Float.parseFloat(stringsp[12]);
                     ang = Float.parseFloat(stringsp[13]);
                     rad = Float.parseFloat(stringsp[14]);
                    players.get(p1 - 1).update(x, y, ang, rad);

                }
            }


            String[] stringsc = division[1].split(" ");
            int nc = stringsc.length / 5;

            switch (nc) {
                case (1) -> {
                    int p1 = 1;
                    float x = Float.parseFloat(stringsc[1]);
                    float y = Float.parseFloat(stringsc[2]);
                    float ang = Float.parseFloat(stringsc[3]);
                    float rad = Float.parseFloat(stringsc[4]);
                    creatures.get(p1 - 1).update(x, y, ang, rad);

                }

                case (2) -> {
                    int p1 = Integer.parseInt(stringsc[0]);
                    float x = Float.parseFloat(stringsc[1]);
                    float y = Float.parseFloat(stringsc[2]);
                    float ang = Float.parseFloat(stringsc[3]);
                    float rad = Float.parseFloat(stringsc[4]);
                    players.get(p1 - 1).update(x, y, ang, rad);
                    p1 = Integer.parseInt(stringsc[5]);
                    x = Float.parseFloat(stringsc[6]);
                    y = Float.parseFloat(stringsc[7]);
                    ang = Float.parseFloat(stringsc[8]);
                    rad = Float.parseFloat(stringsc[9]);
                    players.get(p1 - 1).update(x, y, ang, rad);


                }
                case (3) -> {
                    int p1 = Integer.parseInt(stringsc[0]);
                    float x = Float.parseFloat(stringsc[1]);
                    float y = Float.parseFloat(stringsc[2]);
                    float ang = Float.parseFloat(stringsc[3]);
                    float rad = Float.parseFloat(stringsc[4]);
                    players.get(p1 - 1).update(x, y, ang, rad);
                    p1 = Integer.parseInt(stringsc[5]);
                    x = Float.parseFloat(stringsc[6]);
                    y = Float.parseFloat(stringsc[7]);
                    ang = Float.parseFloat(stringsc[8]);
                    rad = Float.parseFloat(stringsc[9]);
                    players.get(p1 - 1).update(x, y, ang, rad);
                    p1 = Integer.parseInt(stringsc[10]);
                    x = Float.parseFloat(stringsc[11]);
                    y = Float.parseFloat(stringsc[12]);
                    ang = Float.parseFloat(stringsc[13]);
                    rad = Float.parseFloat(stringsc[14]);
                    players.get(p1 - 1).update(x, y, ang, rad);

                }



            }

            for (Player p : players) {
                p.draw();
            }

            for (Player p : creatures) {
                p.draw();
            }
        }


        StringBuffer str = new StringBuffer();
        if (up)
            str.append("u ");
        if (left && !right)
            str.append("l ");
        if (!left && right)
            str.append("r ");
        str.append("n");
        l.write(str.toString());


    }

    public void keyPressed() {
        switch (keyCode) {
            case UP:
                up = true;
                break;
            case LEFT:
                left = true;
                break;
            case RIGHT:
                right = true;
                break;


        }

    }

    public void keyReleased() {
        switch (keyCode) {
            case UP:
                up = false;
                break;
            case LEFT:
                left = false;
                break;
            case RIGHT:
                right = false;
                break;


        }

    }


}
