package Processing;

import org.json.*;
import processing.core.PApplet;
import processing.core.PImage;

import java.util.ArrayList;
import java.util.Arrays;

public class MainProcessing extends PApplet {
    public static PApplet processing;
    private final ArrayList<Player> players = new ArrayList<Player>();
    private final ArrayList<Obstacle> obstacles = new ArrayList<Obstacle>();
    private final ArrayList<Creature> creatures = new ArrayList<Creature>();
    Link l;
    Login log;
    Button logger;
    Button register;
    Battery b;

    private boolean up, left, right;

    public static void main(String[] args) {
        PApplet.main("Processing.MainProcessing", args);
    }

    public void settings() {
        size(1280, 720);
    }

    public void setup() {
        frameRate(60);
        processing = this;

        logger = new Button(width / 3, 50, 400, 200, "Login");
        register = new Button(width / 3, 300, 400, 200, "Register");
        //b = new Battery(40,40, 300,400);
        players.add(new Player());
        players.add(new Player());
        players.add(new Player());

        creatures.add(new Creature());
        creatures.add(new Creature());
        creatures.add(new Creature());
        rectMode(CORNER);
        textAlign(LEFT);
        l = new Link();
        l.connect("localhost", 5027);
        log = new Login(l, obstacles);
        log.instantiateBoxes();
    }

    public void draw() {
        background(255);
        //b.draw();
        String r;
        logger.isOver(mouseX, mouseY);
        register.isOver(mouseX, mouseY);

        if (log.state == log.stateNormal) {
            logger.draw();
            register.draw();
        } else if (log.state == log.stateLoginBox) {
            log.loginbox.display();
        } else if (log.state == log.stateLoginPasswordBox) {
            log.loginpassbox.display();
        } else if (log.state == log.stateRegisterBox) {
            log.registerbox.display();
        } else if (log.state == log.stateRegisterPasswordBox) {
            log.registerpassbox.display();
        } else if (log.state == log.stateQueue) {

        } else if (log.state == log.stateDead) {
            textSize(80);
            text("You Died", width / 3, height / 3);
        } else if (log.state == log.stateGame) {
            for (Obstacle o : obstacles) {
                o.draw();
            }
            if (0 == 0) {
                r = l.read();
                //update positions
                if (r.equals("RIP")) {
                    log.state = log.stateDead;
                } else {
                    String[] division = r.split("_[a-zA-Z]+ ");

                    String[] stringsp = division[0].split(" ");

                    boolean[] ids = {false, false, false};
                    int[] indexes = {0, 0, 0};
                    for (int i = 0; i < stringsp.length; i += 8) {
                        int k = Integer.parseInt(stringsp[i]) - 1;
                        ids[k] = true;
                        indexes[k] = i;
                    }

                    for (int i = 0; i < ids.length; i++) {
                        float x, y, ang, rad;
                        if (ids[i]) {
                            x = Float.parseFloat(stringsp[indexes[i] + 1]);
                            y = Float.parseFloat(stringsp[indexes[i] + 2]);
                            ang = Float.parseFloat(stringsp[indexes[i] + 3]);
                            rad = Float.parseFloat(stringsp[indexes[i] + 4]);
                        } else {
                            x = -99f;
                            y = -99f;
                            ang = 0f;
                            rad = 0f;
                        }
                        players.get(i).update(x, y, ang, rad);
                    }

                    if (division[1].length() > 0) {

                        String[] stringsc = division[1].split(" ");
                        System.out.println(Arrays.toString(stringsc));
                        boolean[] Cids = {false, false, false};
                        int[] indexesC = {0, 0, 0};
                        for (int i = 0; i < stringsc.length; i += 6) {
                            int k = Integer.parseInt(stringsc[i]) - 1;
                            Cids[k] = true;
                            indexesC[k] = i;
                        }

                        for (int i = 0; i < Cids.length; i++) {
                            float x, y, ang, rad;
                            boolean isRed;
                            if (Cids[i]) {
                                x = Float.parseFloat(stringsc[indexesC[i] + 1]);
                                y = Float.parseFloat(stringsc[indexesC[i] + 2]);
                                ang = Float.parseFloat(stringsc[indexesC[i] + 3]);
                                rad = Float.parseFloat(stringsc[indexesC[i] + 4]);
                                isRed = Boolean.parseBoolean(stringsc[indexesC[i] + 5]);
                            } else {
                                x = -99f;
                                y = -99f;
                                ang = 0f;
                                rad = 0f;
                                isRed = true;
                            }
                            creatures.get(i).update(x, y, ang, rad, isRed);
                        }
                    } else {
                        float x = -99f;
                        float y = -99f;
                        float ang = 0f;
                        float rad = 0f;
                        boolean isRed = true;
                        creatures.get(0).update(x, y, ang, rad, isRed);
                        creatures.get(1).update(x, y, ang, rad, isRed);
                        creatures.get(2).update(x, y, ang, rad, isRed);
                    }

                    String[] Scores = division[2].split(" ");
                    text("Scores:", 40, 40);
                    for (int i = 0; i < Scores.length; i += 2) {
                        textSize(12);
                        text(Scores[i]+"  "+Scores[i+1] , 40, 60 + i * 20);

                    }
                    String[] highScore = division[3].split(" ");
                    text("High Score:", 140, 40);
                    textSize(12);
                    text(highScore[0] +"  "+ highScore[1], 140, 60);

                    for (Player p : players) {
                        p.draw();
                    }

                    for (Creature c : creatures) {
                        c.draw();
                    }

                }
            }

            StringBuilder str = new StringBuilder();
            if (up)
                str.append("u ");
            if (left && !right)
                str.append("l ");
            if (!left && right)
                str.append("r ");
            str.append("n");
            l.write(str.toString());
        }

    }

    public void mouseClicked() {
        if (logger.hovered && log.state == log.stateNormal) {
            log.state = log.stateLoginBox;
        } else if (register.hovered && log.state == log.stateNormal) {
            log.state = log.stateRegisterBox;
        }
    }

    public void keyTyped() {
        if (log.state == log.stateNormal) {
        } else if (log.state == log.stateLoginBox) {
            log.loginbox.tKeyTyped();
        } else if (log.state == log.stateLoginPasswordBox) {
            log.loginpassbox.tKeyTyped();
        } else if (log.state == log.stateRegisterBox) {
            log.registerbox.tKeyTyped();
        } else if (log.state == log.stateRegisterPasswordBox) {
            log.registerpassbox.tKeyTyped();
        }
    }

    public void keyPressed() {

        if (log.state == log.stateNormal) {
        } else if (log.state == log.stateLoginBox) {
            log.loginbox.tKeyPressed();
        } else if (log.state == log.stateLoginPasswordBox) {
            log.loginpassbox.tKeyPressed();
        } else if (log.state == log.stateRegisterBox) {
            log.registerbox.tKeyPressed();
        } else if (log.state == log.stateRegisterPasswordBox) {
            log.registerpassbox.tKeyPressed();
        } else if (log.state == log.stateGame) {

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
