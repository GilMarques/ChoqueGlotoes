package Processing;

import com.sun.tools.javac.Main;
import processing.core.PApplet;

import java.util.ArrayList;

public class Login {
    final int stateNormal = 0;
    final int stateLoginBox = 1;
    final int stateLoginPasswordBox = 2;
    final int stateRegisterBox = 3;
    final int stateRegisterPasswordBox = 4;
    final int stateWaitLogin = 5;
    final int stateWaitRegister = 6;
    final int stateQueue = 7;
    final int stateGame = 8;
    final int stateDead = 9;
    private final ArrayList<Obstacle> obstacles;
    int MyID;
    PApplet p = MainProcessing.processing;
    TextBox loginbox;
    TextBox loginpassbox;
    TextBox registerpassbox;
    TextBox registerbox;
    int state = stateNormal;
    String resultLogin = "/";
    String resultLPassword = "/";
    String resultRegister = "/";
    String resultRPassword = "/";
    Link l;

    Login(Link x, ArrayList<Obstacle> y) {
        l = x;
        obstacles = y;
    }

    void instantiateBoxes() {
        loginbox = new TextBox(
                "Please enter your name: ",
                p.width / 3, p.height / 4 + p.height / 16,
                p.width / 3, p.height / 2 - p.height / 4 - p.height / 8,
                215, false);

        loginpassbox = new TextBox(
                "Please enter your password: ",
                p.width / 3, p.height / 4 + p.height / 16,
                p.width / 3, p.height / 2 - p.height / 4 - p.height / 8,
                215, true);

        registerpassbox = new TextBox(
                "Please enter your password: ",
                p.width / 3, p.height / 4 + p.height / 16,
                p.width / 3, p.height / 2 - p.height / 4 - p.height / 8,
                215, true);

        registerbox = new TextBox(
                "Please enter your name: ",
                p.width / 3, p.height / 4 + p.height / 16,
                p.width / 3, p.height / 2 - p.height / 4 - p.height / 8,
                215, false);
    }

    class TextBox {
        final short x, y, w, h, xw, yh, lim;

        boolean isFocused;
        String txt = "";
        String title;
        boolean hide;

        TextBox(String tt, int xx, int yy, int ww, int hh, int li, boolean hid) {

            title = tt;

            x = (short) xx;
            y = (short) yy;
            w = (short) ww;
            h = (short) hh;

            lim = (short) li;

            xw = (short) (xx + ww);
            yh = (short) (yy + hh);
            hide = hid;

        }

        void display() {
            p.textSize(16);
            p.textAlign(p.LEFT);
            p.fill(255);
            p.rect(x - 10, y - 90, w + 20, h + 100);

            p.fill(0);
            p.text(title, x, y - 90 + 20);

            // main / inner
            p.fill(200);
            p.rect(x, y, w, h);
            p.fill(0);
            if (hide) {
                p.text("*".repeat(txt.length()) + blinkChar(), x, y, w, h);
            } else p.text(txt + blinkChar(), x, y, w, h);

        }

        void tKeyTyped() {
            char k = p.key;
            if (k == p.ESC) {
                state = stateNormal;
                p.key = 0;
                return;
            }

            if (k == p.CODED) return;

            final int len = txt.length();

            if (k == p.BACKSPACE) txt = txt.substring(0, PApplet.max(0, len - 1));
            else if (len >= lim) return;
            else if (k == p.ENTER || k == p.RETURN) {
                if (state == stateLoginBox) {
                    state = stateLoginPasswordBox;
                    resultLogin = txt;
                } else if (state == stateRegisterBox) {
                    state = stateRegisterPasswordBox;
                    resultRegister = txt;
                    txt = "";
                } else if (state == stateLoginPasswordBox) {
                    state = stateWaitLogin;
                    resultLPassword = txt;
                    txt = "";
                    l.write("Login " + "U: " + resultLogin + " P: " + resultLPassword + " ");
                    String res = l.read();
                    boolean b = Boolean.parseBoolean(res);
                    if (b) {
                        String r;
                        r = l.read();
                        String[] strings = r.split(" ");
                        MyID = Integer.parseInt(strings[0]);
                        obstacles.add(new Obstacle(Float.parseFloat(strings[1]), Float.parseFloat(strings[2]), Float.parseFloat(strings[3])));
                        obstacles.add(new Obstacle(Float.parseFloat(strings[4]), Float.parseFloat(strings[5]), Float.parseFloat(strings[6])));
                        obstacles.add(new Obstacle(Float.parseFloat(strings[7]), Float.parseFloat(strings[8]), Float.parseFloat(strings[9])));
                        obstacles.add(new Obstacle(Float.parseFloat(strings[10]), Float.parseFloat(strings[11]), Float.parseFloat(strings[12])));
                        state = stateGame;
                    }
                } else if (state == stateRegisterPasswordBox) {
                    state = stateWaitRegister;
                    resultRPassword = txt;
                    l.write("Register " + "U: " + resultRegister + " P: " + resultRPassword + " ");
                    String res = l.read();
                    boolean b = Boolean.parseBoolean(res);
                    state = stateNormal;
                    txt = "";
                    if (b) {
                        System.out.println("Success");
                    } else {
                        System.out.println("Fail");
                    }
                } else {
                    txt = "";
                    state = stateNormal;
                }
            } else if (k == p.TAB & len < lim - 3) txt += "    ";
            else if (k == p.DELETE) txt = "";
            else if (k >= ' ') txt += PApplet.str(k);
        }

        void tKeyPressed() {
            if (p.key == p.ESC) {
                state = stateNormal;
                p.key = 0;
            }

            if (p.key != p.CODED) return;

            final int k = p.keyCode;

            final int len = txt.length();

            if (k == p.LEFT) txt = txt.substring(0, PApplet.max(0, len - 1));
            else if (k == p.RIGHT & len < lim - 3) txt += "    ";
        }

        String blinkChar() {
            int x = p.frameCount % 60;
            return (x <= 40) ? "_" : "";
        }
    }

}
