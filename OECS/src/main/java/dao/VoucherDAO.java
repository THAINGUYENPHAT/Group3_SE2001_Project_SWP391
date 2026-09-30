package dao;

import db.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import model.Voucher;

public class VoucherDAO extends DBContext {

    // =============================================
    // 1. Lấy tất cả Voucher
    // =============================================
    public List<Voucher> getAllVouchers() {

        List<Voucher> list = new ArrayList<>();

        String sql = "SELECT voucher_id, code, discount_amount, "
                   + "min_order_value, valid_from, valid_to "
                   + "FROM VOUCHER "
                   + "ORDER BY voucher_id DESC";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {

                Voucher voucher = new Voucher();

                voucher.setVoucherId(
                        rs.getInt("voucher_id")
                );

                voucher.setCode(
                        rs.getString("code")
                );

                voucher.setDiscountAmount(
                        rs.getDouble("discount_amount")
                );

                voucher.setMinOrderValue(
                        rs.getDouble("min_order_value")
                );

                voucher.setValidFrom(
                        rs.getTimestamp("valid_from")
                );

                voucher.setValidTo(
                        rs.getTimestamp("valid_to")
                );

                list.add(voucher);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return list;
    }


    // =============================================
    // 2. Tìm Voucher theo ID
    // =============================================
    public Voucher getVoucherById(int voucherId) {

        String sql = "SELECT voucher_id, code, discount_amount, "
                   + "min_order_value, valid_from, valid_to "
                   + "FROM VOUCHER "
                   + "WHERE voucher_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, voucherId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    Voucher voucher = new Voucher();

                    voucher.setVoucherId(
                            rs.getInt("voucher_id")
                    );

                    voucher.setCode(
                            rs.getString("code")
                    );

                    voucher.setDiscountAmount(
                            rs.getDouble("discount_amount")
                    );

                    voucher.setMinOrderValue(
                            rs.getDouble("min_order_value")
                    );

                    voucher.setValidFrom(
                            rs.getTimestamp("valid_from")
                    );

                    voucher.setValidTo(
                            rs.getTimestamp("valid_to")
                    );

                    return voucher;
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }


    // =============================================
    // 3. Tìm Voucher theo CODE
    // =============================================
    public Voucher getVoucherByCode(String code) {

        String sql = "SELECT voucher_id, code, discount_amount, "
                   + "min_order_value, valid_from, valid_to "
                   + "FROM VOUCHER "
                   + "WHERE code = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, code);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    Voucher voucher = new Voucher();

                    voucher.setVoucherId(
                            rs.getInt("voucher_id")
                    );

                    voucher.setCode(
                            rs.getString("code")
                    );

                    voucher.setDiscountAmount(
                            rs.getDouble("discount_amount")
                    );

                    voucher.setMinOrderValue(
                            rs.getDouble("min_order_value")
                    );

                    voucher.setValidFrom(
                            rs.getTimestamp("valid_from")
                    );

                    voucher.setValidTo(
                            rs.getTimestamp("valid_to")
                    );

                    return voucher;
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }


    // =============================================
    // 4. Kiểm tra code đã tồn tại
    // =============================================
    public boolean existsCode(String code) {

        String sql = "SELECT voucher_id "
                   + "FROM VOUCHER "
                   + "WHERE code = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, code);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    // =============================================
    // 5. Tạo Voucher
    // =============================================
    public boolean insertVoucher(Voucher voucher) {

        String sql = "INSERT INTO VOUCHER "
                   + "(code, discount_amount, min_order_value, "
                   + "valid_from, valid_to) "
                   + "VALUES (?, ?, ?, ?, ?)";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(
                    1,
                    voucher.getCode()
            );

            ps.setDouble(
                    2,
                    voucher.getDiscountAmount()
            );

            ps.setDouble(
                    3,
                    voucher.getMinOrderValue()
            );

            ps.setTimestamp(
                    4,
                    voucher.getValidFrom()
            );

            ps.setTimestamp(
                    5,
                    voucher.getValidTo()
            );

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    // =============================================
    // 6. Update Voucher
    // =============================================
    public boolean updateVoucher(Voucher voucher) {

        String sql = "UPDATE VOUCHER "
                   + "SET code = ?, "
                   + "discount_amount = ?, "
                   + "min_order_value = ?, "
                   + "valid_from = ?, "
                   + "valid_to = ? "
                   + "WHERE voucher_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(
                    1,
                    voucher.getCode()
            );

            ps.setDouble(
                    2,
                    voucher.getDiscountAmount()
            );

            ps.setDouble(
                    3,
                    voucher.getMinOrderValue()
            );

            ps.setTimestamp(
                    4,
                    voucher.getValidFrom()
            );

            ps.setTimestamp(
                    5,
                    voucher.getValidTo()
            );

            ps.setInt(
                    6,
                    voucher.getVoucherId()
            );

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    // =============================================
    // 7. Delete Voucher
    // =============================================
    public boolean deleteVoucher(int voucherId) {

        String sql = "DELETE FROM VOUCHER "
                   + "WHERE voucher_id = ?";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, voucherId);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    // =============================================
    // 8. Kiểm tra Voucher hợp lệ
    // =============================================
    public Voucher getValidVoucher(String code,
                                   double cartTotal) {

        String sql = "SELECT voucher_id, code, discount_amount, "
                   + "min_order_value, valid_from, valid_to "
                   + "FROM VOUCHER "
                   + "WHERE code = ? "
                   + "AND GETDATE() BETWEEN valid_from AND valid_to "
                   + "AND ? >= min_order_value";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, code);
            ps.setDouble(2, cartTotal);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    Voucher voucher = new Voucher();

                    voucher.setVoucherId(
                            rs.getInt("voucher_id")
                    );

                    voucher.setCode(
                            rs.getString("code")
                    );

                    voucher.setDiscountAmount(
                            rs.getDouble("discount_amount")
                    );

                    voucher.setMinOrderValue(
                            rs.getDouble("min_order_value")
                    );

                    voucher.setValidFrom(
                            rs.getTimestamp("valid_from")
                    );

                    voucher.setValidTo(
                            rs.getTimestamp("valid_to")
                    );

                    return voucher;
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }
}