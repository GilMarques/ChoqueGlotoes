package Processing;
import processing.core.PApplet;
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
    Battery LeftBattery, RightBattery, MiddleBattery;
    private ScoreTable scores;
    private ScoreTable hscore;
    private boolean up, left, right;
    private boolean canDraw = false;

    public static void main(String[] args) {
        PApplet.main("Processing.MainProcessing", args);
    }

    public void settings() {
        size(1280, 900);
    }

    public void setup() {
        frameRate(60);
        processing = this;
        logger = new Button(width / 3, 50, 400, 200, "Login");
        register = new Button(width / 3, 300, 400, 200, "Register");

        players.add(new Player());
        players.add(new Player());
        players.add(new Player());

        creatures.add(new Creature());
        creatures.add(new Creature());
        creatures.add(new Creature());

        scores = new ScoreTable(40, 40, "Scores:");
        hscore = new ScoreTable(200, 40, "High Score:");

        LeftBattery = new Battery(width / 4 - 100, 720, 200, 200);
        RightBattery = new Battery(3 * width / 4 - 100, 720, 200, 200);
        MiddleBattery = new Battery(width / 2 - 100, 720, 200, 200);

        rectMode(CORNER);
        textAlign(LEFT);
        l = new Link();
        l.connect("localhost", 5027);
        log = new Login(l, obstacles);
        log.instantiateBoxes();
        thread("threadrun");
    }

    public void draw() {
        background(255);
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
            textSize(80);
            text("In Queue", width / 3, height / 2);
        } else if (log.state == log.stateDead) {
            textSize(80);
            text("You Died", width / 3, height / 2);
        } else if (log.state == log.stateGame && canDraw) {
            for (Obstacle o : obstacles) {
                o.draw();
            }
            fill(200);
            rect(0,720,width,900-720);

            synchronized (players) {
                for (Player p : players) {

                    p.draw();

                }
            }
            synchronized (creatures) {
                for (Creature c : creatures) {
                    c.draw();
                }
            }

            synchronized (scores) {
                scores.draw();
            }

            synchronized (hscore) {
                hscore.draw();
            }

            synchronized (LeftBattery) {
                LeftBattery.draw();
            }
            synchronized (RightBattery) {
                RightBattery.draw();
            }
            synchronized (MiddleBattery) {
                MiddleBattery.draw();
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

    public void threadrun() throws InterruptedException {
        while (true) {
            String r;
            if (log.state == log.stateQueue) {
                r = l.read();
                String[] strings = r.split(" ");
                log.MyID = Integer.parseInt(strings[0]);
                obstacles.add(new Obstacle(Float.parseFloat(strings[1]), Float.parseFloat(strings[2]), Float.parseFloat(strings[3])));
                obstacles.add(new Obstacle(Float.parseFloat(strings[4]), Float.parseFloat(strings[5]), Float.parseFloat(strings[6])));
                obstacles.add(new Obstacle(Float.parseFloat(strings[7]), Float.parseFloat(strings[8]), Float.parseFloat(strings[9])));
                obstacles.add(new Obstacle(Float.parseFloat(strings[10]), Float.parseFloat(strings[11]), Float.parseFloat(strings[12])));
                log.state = log.stateGame;
            } else if (log.state == log.stateWaitLogin) {
                String res = l.read();
                boolean b = Boolean.parseBoolean(res);
                if (b) {
                    r = l.read();
                    if (r.equals("Q")) {
                        log.state = log.stateQueue;
                    } else {
                        String[] strings = r.split(" ");
                        log.MyID = Integer.parseInt(strings[0]);
                        obstacles.add(new Obstacle(Float.parseFloat(strings[1]), Float.parseFloat(strings[2]), Float.parseFloat(strings[3])));
                        obstacles.add(new Obstacle(Float.parseFloat(strings[4]), Float.parseFloat(strings[5]), Float.parseFloat(strings[6])));
                        obstacles.add(new Obstacle(Float.parseFloat(strings[7]), Float.parseFloat(strings[8]), Float.parseFloat(strings[9])));
                        obstacles.add(new Obstacle(Float.parseFloat(strings[10]), Float.parseFloat(strings[11]), Float.parseFloat(strings[12])));
                        log.state = log.stateGame;
                    }
                }else log.state = log.stateNormal;
            } else if (log.state == log.stateGame) {
                if (!canDraw) canDraw = true;
                r = l.read();
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
                        synchronized (players) {
                            players.get(i).update(x, y, ang, rad);
                        }
                    }

                    synchronized (LeftBattery) {
                        LeftBattery.update(Float.parseFloat(stringsp[indexes[log.MyID-1] + 5]) / 100f);
                    }

                    synchronized (RightBattery) {
                        RightBattery.update(Float.parseFloat(stringsp[indexes[log.MyID-1] + 6]) / 100f);
                    }

                    synchronized (MiddleBattery) {
                        MiddleBattery.update(Float.parseFloat(stringsp[indexes[log.MyID-1] + 7]) / 100f);
                    }

                    if (division[1].length() > 0) {

                        String[] stringsc = division[1].split(" ");
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
                            synchronized (creatures) {
                                creatures.get(i).update(x, y, ang, rad, isRed);
                            }

                        }
                    } else {
                        float x = -99f;
                        float y = -99f;
                        float ang = 0f;
                        float rad = 0f;
                        creatures.get(0).update(x, y, ang, rad, true);
                        creatures.get(1).update(x, y, ang, rad, true);
                        creatures.get(2).update(x, y, ang, rad, true);
                    }

                    String[] Scores = division[2].split(" ");
                    synchronized (scores) {
                        scores.update(Scores);
                    }

                    String[] highScore = division[3].split(" ");
                    synchronized (hscore) {
                        hscore.update(highScore);
                    }

                }
            }
            Thread.sleep(16);
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
