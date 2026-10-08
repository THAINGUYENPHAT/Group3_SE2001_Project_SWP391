package dao;

import db.DBContext;
import model.Address;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class AddressDAO extends DBContext {

    private static final Logger LOGGER
            = Logger.getLogger(AddressDAO.class.getName());

    // LAY DANH SACH DIA CHI CHUA BI XOA
    public List<Address> getAddressesByUser(int userId) {
        List<Address> addresses = new ArrayList<>();

        String sql = "SELECT address_id, user_id, recipient_name, "
                + "phone_number, address_line, is_default "
                + "FROM dbo.ADDRESSBOOK "
                + "WHERE user_id = ? AND is_deleted = 0 "
                + "ORDER BY is_default DESC, address_id DESC";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    addresses.add(mapAddress(rs));
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Loi lay danh sach dia chi!", e);
        }

        return addresses;
    }

    // LAY DIA CHI VA KIEM TRA QUYEN SO HUU
    public Address getAddressById(int addressId, int userId) {
        String sql = "SELECT address_id, user_id, recipient_name, "
                + "phone_number, address_line, is_default "
                + "FROM dbo.ADDRESSBOOK "
                + "WHERE address_id = ? AND user_id = ? "
                + "AND is_deleted = 0";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, addressId);
            ps.setInt(2, userId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapAddress(rs);
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Loi lay dia chi theo ID!", e);
        }

        return null;
    }

    // THEM DIA CHI MOI
    public int insertAddress(
            int userId,
            String recipientName,
            String phoneNumber,
            String addressLine
    ) {
        if (userId <= 0
                || recipientName == null
                || phoneNumber == null
                || addressLine == null
                || recipientName.trim().isEmpty()
                || recipientName.trim().length() > 100
                || !phoneNumber.trim().matches("[0-9]{9,11}")
                || addressLine.trim().isEmpty()) {
            return -1;
        }

        String sql = "INSERT INTO dbo.ADDRESSBOOK "
                + "(user_id, recipient_name, phone_number, "
                + "address_line, is_default, is_deleted) "
                + "VALUES (?, ?, ?, ?, 0, 0)";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(
                sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1, userId);
            ps.setString(2, recipientName.trim());
            ps.setString(3, phoneNumber.trim());
            ps.setString(4, addressLine.trim());

            int rows = ps.executeUpdate();

            if (rows == 1) {
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        return rs.getInt(1);
                    }
                }
            }

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Loi them dia chi!", e);
        }

        return -1;
    }

    // SUA DIA CHI CON HOAT DONG VA THUOC DUNG USER
    public boolean updateAddress(
            int addressId,
            int userId,
            String recipientName,
            String phoneNumber,
            String addressLine
    ) throws SQLException {

        if (addressId <= 0
                || userId <= 0
                || recipientName == null
                || recipientName.trim().isEmpty()
                || recipientName.trim().length() > 100
                || phoneNumber == null
                || !phoneNumber.trim().matches("[0-9]{9,11}")
                || addressLine == null
                || addressLine.trim().isEmpty()) {

            throw new IllegalArgumentException(
                    "Thông tin địa chỉ không hợp lệ."
            );
        }

        String sql = "UPDATE dbo.ADDRESSBOOK "
                + "SET recipient_name = ?, phone_number = ?, address_line = ? "
                + "WHERE address_id = ? AND user_id = ? AND is_deleted = 0";

        try (Connection conn = getConnection()) {

            if (conn == null) {
                throw new SQLException("Khong the ket noi database.");
            }

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, recipientName.trim());
                ps.setString(2, phoneNumber.trim());
                ps.setString(3, addressLine.trim());
                ps.setInt(4, addressId);
                ps.setInt(5, userId);

                return ps.executeUpdate() == 1;
            }
        }
    }

    // XOA MEM DIA CHI CUA USER
    public boolean deleteAddress(int addressId, int userId) {
        if (addressId <= 0 || userId <= 0) {
            return false;
        }

        String sql = "UPDATE dbo.ADDRESSBOOK "
                + "SET is_deleted = 1, is_default = 0 "
                + "WHERE address_id = ? "
                + "AND user_id = ? "
                + "AND is_deleted = 0";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, addressId);
            ps.setInt(2, userId);

            return ps.executeUpdate() == 1;

        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Loi xoa dia chi!", e);
            return false;
        }
    }

    // CHI MOT DIA CHI HOAT DONG CUA USER DUOC DAT LAM MAC DINH
    public boolean setDefaultAddress(int addressId, int userId)
            throws SQLException {
        String checkSql = "SELECT address_id FROM dbo.ADDRESSBOOK "
                + "WHERE address_id = ? AND user_id = ? AND is_deleted = 0";
        String updateSql = "UPDATE dbo.ADDRESSBOOK "
                + "SET is_default = CASE WHEN address_id = ? THEN 1 ELSE 0 END "
                + "WHERE user_id = ? AND is_deleted = 0";

        try (Connection conn = getConnection()) {
            if (conn == null) {
                throw new SQLException("Khong the ket noi database.");
            }
            conn.setAutoCommit(false);
            try (PreparedStatement check = conn.prepareStatement(checkSql);
                    PreparedStatement update = conn.prepareStatement(updateSql)) {
                check.setInt(1, addressId);
                check.setInt(2, userId);
                try (ResultSet rs = check.executeQuery()) {
                    if (!rs.next()) {
                        conn.rollback();
                        return false;
                    }
                }

                update.setInt(1, addressId);
                update.setInt(2, userId);
                update.executeUpdate();
                conn.commit();
                return true;
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            }
        }
    }

    // CHUYEN RESULTSET THANH OBJECT ADDRESS
    private Address mapAddress(ResultSet rs) throws SQLException {
        Address address = new Address();

        address.setAddressId(rs.getInt("address_id"));
        address.setUserId(rs.getInt("user_id"));
        address.setRecipientName(rs.getString("recipient_name"));
        address.setPhoneNumber(rs.getString("phone_number"));
        address.setAddressLine(rs.getString("address_line"));
        address.setDefaultAddress(rs.getBoolean("is_default"));

        return address;
    }
}
