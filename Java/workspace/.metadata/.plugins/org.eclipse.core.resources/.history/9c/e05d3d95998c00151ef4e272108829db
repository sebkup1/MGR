import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

public class DBConnector {
private Connection con;
private Statement st;
private ResultSet rs;

public DBConnector(){
try{
Class.forName("com.mysql.jdbc.Driver");

con = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/TIBI","root","abcd1234");

st = con.createStatement();

}catch(Exception ex){
System.out.println("Error: "+ex);
}
}

public void getData(){
try{

String querry = "Select * from TIBI.markers";
rs = st.executeQuery(querry);
System.out.println("Records from database: ");
while(rs.next()){
String name = rs.getString("name");
String descr = rs.getString("descr");

System.out.println("Name: "+name+" "+"descr: "+descr);
}

}catch(Exception ex){
System.out.println(ex);
}
}
}