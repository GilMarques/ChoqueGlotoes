package Processing;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;

public class Link {
    private Socket sock;
    private BufferedReader in;
    private PrintWriter pw;

    /** Conecta-se ao servidor com o addr e a porta atraves de uma socket **/
    public boolean connect(String addr, int port) {
        try{
            sock = new Socket(addr,port);
            in = new BufferedReader(new InputStreamReader(sock.getInputStream()));
            pw = new PrintWriter(sock.getOutputStream());
            sock.setTcpNoDelay(true);
            System.out.println("S");
            return true;
        } catch(Exception e){
            System.out.println("N");
            return false;}
    }

    public void write(String s){

        pw.println(s);
        pw.flush();
    }

    public String read(){
        String str;
        try{
            str = in.readLine();
            System.out.println(str);
        } catch(Exception e){
            return null;}
        return str;
    }


    public void disconnect(){
        try{
            sock.close();
        }catch(Exception e){}
    }


}
