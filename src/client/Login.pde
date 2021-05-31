

final StringDict accounts = new StringDict(
new String[] {
  "baptiste", "tanguy", "alexis"
}
, new String[] {
  "bap", "guy", "ex"
}
);
 
final JPasswordField pwd = new JPasswordField();
 
{
  println(accounts);
}
  
String askUser() {
  String id = showInputDialog("Please enter user:");
 
  if (id == null)
    showMessageDialog(null, "You've canceled login operation!"
      , "Alert", ERROR_MESSAGE);
 
  else if ("".equals(id))
    showMessageDialog(null, "Empty user input!"
      , "Alert", ERROR_MESSAGE);
 
  else if (!accounts.hasKey(id = id.toLowerCase()))
    showMessageDialog(null, "Unknown \"" + id + "\" user!" + (id = "")
      , "Alert", ERROR_MESSAGE);
 
  return id;
}
 
boolean askPass(String id) {
  boolean isLogged = false;
  pwd.setText("");
 
  int action = showConfirmDialog(null, pwd
    , "Now enter password:", OK_CANCEL_OPTION);
 
  if (action != OK_OPTION) {
    showMessageDialog(null, "Password input canceled!"
      , "Alert", ERROR_MESSAGE);
 
    return false;
  }
 
  String phrase = pwd.getText();
  //String phrase = new String(pwd.getPassword());
 
  if ("".equals(phrase))
    showMessageDialog(null, "Empty password input!"
      , "Alert", ERROR_MESSAGE);
 
  else if (accounts.get(id).equals(phrase)) {
    showMessageDialog(null, "Welcome \"" + id + "\"!\nYou're logged in!"
      , "Info", INFORMATION_MESSAGE);
 
    isLogged = true;
  }
 
  else
    showMessageDialog(null, "Password \"" + phrase + "\" mismatch!"
      , "Alert", ERROR_MESSAGE);
 
  return isLogged;
}
 
