package dao;

import db.DBContext;
import model.Address;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;

import java.util.ArrayList;
import java.util.List;

public class AddressDAO extends DBContext {

    // ===============================
    // LAY DIA CHI CUA USER
    // ===============================
    public List<Address> getAddressesByUser(int userId) {

        List<Address> list = new ArrayList<>();

        String sql
                = "SELECT address_id, user_id, recipient_name, "
                + "phone_number, address_line, is_default "
                + "FROM ADDRESSBOOK "
                + "WHERE user_id = ? "
                + "ORDER BY is_default DESC, address_id DESC";

        try (
                Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)
        ) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    Address address = new Address();

                    address.setAddressId(
                            rs.getInt("address_id")
                    );

                    address.setUserId(
                            rs.getInt("user_id")
                    );

                    address.setRecipientName(
                            rs.getString("recipient_name")
                    );

                    address.setPhoneNumber(
                            rs.getString("phone_number")
                    );

                    address.setAddressLine(
                            rs.getString("address_line")
                    );

                    address.setDefaultAddress(
                            rs.getBoolean("is_default")
                    );

                    list.add(address);
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return list;
    }


    // ===============================
    // LAY 1 DIA CHI CUA USER
    // ===============================
    public Address getAddressById(int addressId, int userId) {

        String sql
                = "SELECT address_id, user_id, recipient_name, "
                + "phone_number, address_line, is_default "
                + "FROM ADDRESSBOOK "
                + "WHERE address_id = ? "
                + "AND user_id = ?";

        try (
                Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)
        ) {

            ps.setInt(1, addressId);
            ps.setInt(2, userId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    Address address = new Address();

                    address.setAddressId(
                            rs.getInt("address_id")
                    );

                    address.setUserId(
                            rs.getInt("user_id")
                    );

                    address.setRecipientName(
                            rs.getString("recipient_name")
                    );

                    address.setPhoneNumber(
                            rs.getString("phone_number")
                    );

                    address.setAddressLine(
                            rs.getString("address_line")
                    );

                    address.setDefaultAddress(
                            rs.getBoolean("is_default")
                    );

                    return address;
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return null;
    }


    // ===============================
    // THEM DIA CHI MOI
    // ===============================
    public int insertAddress(
            int userId,
            String recipientName,
            String phoneNumber,
            String addressLine) {

        String sql
                = "INSERT INTO ADDRESSBOOK "
                + "(user_id, recipient_name, phone_number, "
                + "address_line, is_default) "
                + "VALUES (?, ?, ?, ?, 0)";

        try (
                Connection conn = getConnection();
                PreparedStatement ps = conn.prepareStatement(
                        sql,
                        Statement.RETURN_GENERATED_KEYS
                )
        ) {

            ps.setInt(1, userId);
            ps.setString(2, recipientName);
            ps.setString(3, phoneNumber);
            ps.setString(4, addressLine);

            if (ps.executeUpdate() > 0) {

                try (ResultSet rs = ps.getGeneratedKeys()) {

                    if (rs.next()) {
                        return rs.getInt(1);
                    }
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return -1;
    }
}