package Processing;

import org.json.*;
import processing.core.PApplet;

import java.util.ArrayList;

public class MainProcessing extends PApplet {
    public static PApplet processing;
    Link l;
    Login log;
    Button logger;
    Button register;
    Battery b;
    private boolean up, left, right;
    private final ArrayList<Player> players = new ArrayList<Player>();
    private final ArrayList<Obstacle> obstacles = new ArrayList<Obstacle>();
    private final ArrayList<Player> creatures = new ArrayList<Player>();

    public static void main(String[] args) {
        PApplet.main("Processing.MainProcessing", args);
    }

    public void settings() {
        size(1280, 720);
    }

    public void setup() {
        frameRate(60);
        processing = this;

        logger = new Button(width/3,50,400,200,"Login");
        register = new Button(width/3,300,400,200,"Register");
        //b = new Battery(40,40, 300,400);
        players.add(new Player());
        players.add(new Player());
        players.add(new Player());
        creatures.add(new Player());
        rectMode(CORNER);
        textAlign(LEFT);
        l = new Link();
        l.connect("localhost", 5026);
        log = new Login(l,obstacles);
        log.instantiateBoxes();
    }

    public void draw() {
        background(255);
        //b.draw();
        String r;
        logger.isOver(mouseX,mouseY);
        register.isOver(mouseX,mouseY);

        if (log.state == log.stateNormal) {
            logger.draw();
            register.draw();
        } else if (log.state == log.stateLoginBox) {
            log.loginbox.display();
        }else if (log.state == log.stateLoginPasswordBox) {
            log.loginpassbox.display();
        }
        else if (log.state == log.stateRegisterBox) {
            log.registerbox.display();
        }else if (log.state == log.stateRegisterPasswordBox) {
            log.registerpassbox.display();
        }else if (log.state == log.stateGame) {
            for (Obstacle o : obstacles) {
                o.draw();
            }
            if (0 == 0) {
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
        if(logger.hovered && log.state == log.stateNormal){
            log.state = log.stateLoginBox;
        }
        else if (register.hovered && log.state == log.stateNormal) {
            log.state = log.stateRegisterBox;
        }
    }

    public void keyTyped() {
        if (log.state == log.stateNormal) {
        } else if (log.state == log.stateLoginBox) {
            log.loginbox.tKeyTyped();
        }else if (log.state == log.stateLoginPasswordBox) {
            log.loginpassbox.tKeyTyped();
        }else if (log.state == log.stateRegisterBox) {
            log.registerbox.tKeyTyped();
        }else if (log.state == log.stateRegisterPasswordBox) {
            log.registerpassbox.tKeyTyped();
        }
    }

    public void keyPressed() {

        if (log.state == log.stateNormal) {
        } else if (log.state == log.stateLoginBox) {
            log.loginbox.tKeyPressed();
        }else if (log.state == log.stateLoginPasswordBox) {
            log.loginpassbox.tKeyPressed();
        }else if (log.state == log.stateRegisterBox) {
            log.registerbox.tKeyPressed();
        }else if (log.state == log.stateRegisterPasswordBox) {
            log.registerpassbox.tKeyPressed();
        }else if (log.state == log.stateGame) {

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
