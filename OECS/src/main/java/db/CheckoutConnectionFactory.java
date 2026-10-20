package db;

import java.sql.Connection;
import java.sql.SQLException;

/** Opens one independent connection per checkout/order operation. */
@FunctionalInterface
public interface CheckoutConnectionFactory {
    Connection open() throws SQLException;
}
