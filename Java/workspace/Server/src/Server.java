import java.io.*;
import java.net.*;
import java.awt.*;
import java.awt.event.*;

import javax.swing.*;

//@SuppressWarnings("serial")
public class Server extends JFrame{
	
	private JTextField userText;
	private JTextArea chatWindow;
	private ObjectOutputStream output;
	private ObjectInputStream input;
	private ServerSocket server;
	private Socket connection;
	private DBConnector con;
	
	//constructor
	public Server(){
			super("LPC MySql Connector");
			userText = new JTextField();
			userText.setEditable(false);
			
			userText.addActionListener(
					new ActionListener(){
						public void actionPerformed(ActionEvent event){
							sendMessage(event.getActionCommand());
							userText.setText("");
						}
					}
				);
			getContentPane().add(userText, BorderLayout.NORTH);
			chatWindow = new JTextArea();
			JScrollPane scrollPane = new JScrollPane(chatWindow);
			getContentPane().add(scrollPane);
			setSize(300,150);
			setVisible(true);
			
			//MySql Connection
			con = new DBConnector();
			con.sendLog("wszczety");
	}
	
	//set up and run the server
	public void startRunning(){
		try{
			server = new ServerSocket(50000, 100);
			//backlog - ile osób mo¿e siê pod³¹czyæ
			while(true){
				try{
					waitForConnection();
					setupStreams();
					whileChatting();
				}catch(EOFException eofException){
					showMessage("\n Server ended the connection! ");
					System.out.println("Rzucony wyjatek");
				}finally{
					closeCrap();
				}
			}
			
		}catch(IOException ioException){
			ioException.printStackTrace();
		}
	}
	//wait for connection, then display connection information
	private void waitForConnection() throws IOException{
		showMessage("Waiting for some to connect...\n");
		connection = server.accept();
		showMessage(" Now connected to "+ connection.getInetAddress().getHostName());
		
	}
	
	//get stream to send and recieve data
	private void setupStreams() throws IOException{
		output = new ObjectOutputStream(connection.getOutputStream());
		output.flush();
		input = new ObjectInputStream(connection.getInputStream());
		
		showMessage("\n Streams are now setup\n"); 
		
	}
	
	//during the chat converstaion 
	private void whileChatting() throws IOException{
		String message = " You are now connected!";
		sendMessage(message);
		ableToType(true);
		do{
			//have a conversation
		try{
				message = (String) input.readObject();
				showMessage("\n" + message);
				con.sendLog(message);
			}catch(ClassNotFoundException classNotFoundException){
				showMessage("\n idk wtf what user send!");
			}
		}while(!message.equals("END")); //gdy klient co takiego napisze to roz³¹czam po³¹czenie
	}
	
	//close strams and sockets after done chatting
	private void closeCrap(){
		showMessage("\n Closing connections...\n");
		
		ableToType(false);
		try{
			output.close();
			input.close();
			connection.close();
		}catch(IOException ioException){
			ioException.printStackTrace();
		}
	}
	
	//sending message to client
	private void sendMessage(String message){
		try{
			output.writeObject(" "+message);
			output.flush();
			showMessage("\n SERVER - " + message);
		}catch(IOException ioException){
			chatWindow.append("\n ERROR: Can't send message");
			
		}
	}
	
	//displays the message
	private void showMessage(final String text){
		SwingUtilities.invokeLater(
		new Runnable(){ //nowy watek
			public void run(){
				chatWindow.append(text);
				
			}
		}
		);
	}
	
	//let the user type staff into their box
	private void ableToType(final boolean tof){
		SwingUtilities.invokeLater(
			new Runnable(){ //nowy watek
				public void run(){
						userText.setEditable(tof);
					}
				}
			);
		
	}
}