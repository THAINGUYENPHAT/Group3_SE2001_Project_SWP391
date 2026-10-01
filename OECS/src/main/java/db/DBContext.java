package db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

public class DBContext {

    private Connection conn;
    // Cập nhật databaseName=OECS
    private final String DB_URL = "jdbc:sqlserver://127.0.0.1:1433;databaseName=OECS;encrypt=false;trustServerCertificate=true;";
    private final String DB_USER = "sa";     // Thay bằng user SQL của bạn
    private final String DB_PWD = "123456";  // Thay bằng password SQL của bạn

    public DBContext() {
        try {
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
            this.conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PWD);
        } catch (ClassNotFoundException | SQLException ex) {
            Logger.getLogger(DBContext.class.getName()).log(Level.SEVERE, "Lỗi kết nối CSDL!", ex);
        }
    }

    public Connection getConnection() {
        try {
            if (conn == null || conn.isClosed()) {
                Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
                conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PWD);
            }
        } catch (ClassNotFoundException | SQLException ex) {
            Logger.getLogger(DBContext.class.getName()).log(Level.SEVERE, null, ex);
        }
        return conn;
    }

    // Hàm main để test nhanh kết nối thành công chưa
    public static void main(String[] args) {
        DBContext db = new DBContext();
        if (db.getConnection() != null) {
            System.out.println("Kết nối OECS thành công!");
        } else {
            System.out.println("Kết nối thất bại!");
        }
    }
}