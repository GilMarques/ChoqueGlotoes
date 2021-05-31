
import static javax.swing.JOptionPane.*;
import javax.swing.JPasswordField;
Player player;
void setup(){
  size(960,540);
  player = new Player();

}

 
void draw() {
  background(255);
  player.draw();
  player.angle+=0.1;

}
