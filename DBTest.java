import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

public class DBTest {
    public static void main(String[] args) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/p2p_fileshare", "root", "");
            Statement stmt = conn.createStatement();
            
            // Check peers
            ResultSet rs = stmt.executeQuery("SELECT * FROM peers");
            while(rs.next()) {
                System.out.println("Peer: " + rs.getInt("peer_id") + " " + rs.getString("peer_name"));
            }
            
            // Check files
            rs = stmt.executeQuery("SELECT * FROM shared_files");
            while(rs.next()) {
                System.out.println("File: " + rs.getLong("file_id") + " " + rs.getString("original_name") + " Active: " + rs.getBoolean("is_active"));
            }
            
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
