package db;

import java.sql.Connection;
import java.sql.SQLException;

@FunctionalInterface
public interface CheckoutConnectionFactory {
    Connection open() throws SQLException;
}
