package db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

public class DBContext {

    private Connection conn;
    // Thêm trustServerCertificate=true để tránh lỗi SSL Certificate trên SQL Server
    private final String DB_URL = "jdbc:sqlserver://127.0.0.1:1433;databaseName=OECS;encrypt=false;trustServerCertificate=true;";
    private final String DB_USER = "sa";     // Thay bằng username của bạn
    private final String DB_PWD = "123456";  // Thay bằng password của bạn

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
            // Tự động khởi tạo lại nếu kết nối bị đóng hoặc chưa mở
            if (conn == null || conn.isClosed()) {
                Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
                conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PWD);
            }
        } catch (ClassNotFoundException | SQLException ex) {
            Logger.getLogger(DBContext.class.getName()).log(Level.SEVERE, null, ex);
        }
        return conn;
    }
}