package dao;

import db.DBContext;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

import java.util.ArrayList;
import java.util.List;

import model.Voucher;

public class VoucherDAO extends DBContext {

    public List<Voucher> getAllVouchers() {

        List<Voucher> list
                = new ArrayList<>();

        String sql
                = "SELECT "
                + "voucher_id, code, min_order_value, "
                + "valid_from, valid_to, "
                + "discount_type, discount_value, "
                + "max_discount, usage_limit, per_user_limit "
                + "FROM VOUCHER "
                + "ORDER BY voucher_id DESC";

        try (
                Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                list.add(mapVoucher(rs));
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return list;
    }

    public Voucher getVoucherById(
            int voucherId) {

        String sql
                = "SELECT "
                + "voucher_id, code, min_order_value, "
                + "valid_from, valid_to, "
                + "discount_type, discount_value, "
                + "max_discount, usage_limit, per_user_limit "
                + "FROM VOUCHER "
                + "WHERE voucher_id = ?";

        try (
                Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, voucherId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return mapVoucher(rs);
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }

    public boolean existsCode(
            String code) {

        String sql
                = "SELECT 1 "
                + "FROM VOUCHER "
                + "WHERE code = ?";

        try (
                Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, code);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    public boolean existsCodeExceptId(
            String code,
            int voucherId) {

        String sql
                = "SELECT 1 "
                + "FROM VOUCHER "
                + "WHERE code = ? "
                + "AND voucher_id <> ?";

        try (
                Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, code);
            ps.setInt(2, voucherId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    public boolean insertVoucher(
            Voucher voucher) {

        String sql
                = "INSERT INTO VOUCHER "
                + "(code, min_order_value, valid_from, valid_to, "
                + "discount_type, discount_value, max_discount, "
                + "usage_limit, per_user_limit) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (
                Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            setVoucherParameters(
                    ps,
                    voucher);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    public boolean updateVoucher(
            Voucher voucher) {

        String sql
                = "UPDATE VOUCHER SET "
                + "code = ?, "
                + "min_order_value = ?, "
                + "valid_from = ?, "
                + "valid_to = ?, "
                + "discount_type = ?, "
                + "discount_value = ?, "
                + "max_discount = ?, "
                + "usage_limit = ?, "
                + "per_user_limit = ? "
                + "WHERE voucher_id = ?";

        try (
                Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            setVoucherParameters(
                    ps,
                    voucher);

            ps.setInt(
                    10,
                    voucher.getVoucherId());

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    private void setVoucherParameters(
            PreparedStatement ps,
            Voucher voucher)
            throws SQLException {

        ps.setString(
                1,
                voucher.getCode());

        ps.setDouble(
                2,
                voucher.getMinOrderValue());

        ps.setTimestamp(
                3,
                voucher.getValidFrom());

        ps.setTimestamp(
                4,
                voucher.getValidTo());

        ps.setString(
                5,
                voucher.getDiscountType());

        ps.setDouble(
                6,
                voucher.getDiscountValue());

        if (voucher.getMaxDiscount() == null) {

            ps.setNull(
                    7,
                    Types.DECIMAL);

        } else {

            ps.setDouble(
                    7,
                    voucher.getMaxDiscount());
        }

        if (voucher.getUsageLimit() == null) {

            ps.setNull(
                    8,
                    Types.INTEGER);

        } else {

            ps.setInt(
                    8,
                    voucher.getUsageLimit());
        }

        if (voucher.getPerUserLimit() == null) {

            ps.setNull(
                    9,
                    Types.INTEGER);

        } else {

            ps.setInt(
                    9,
                    voucher.getPerUserLimit());
        }
    }

    public boolean deleteVoucher(
            int voucherId) {

        String sql
                = "DELETE FROM VOUCHER "
                + "WHERE voucher_id = ?";

        try (
                Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, voucherId);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    // ==================================================
    // CUSTOMER APPLY
    // ==================================================
    public Voucher getValidVoucher(
            String code,
            double cartTotal,
            int userId) {

        String sql
                = "SELECT "
                + "voucher_id, code, min_order_value, "
                + "valid_from, valid_to, "
                + "discount_type, discount_value, "
                + "max_discount, usage_limit, per_user_limit "
                + "FROM VOUCHER "
                + "WHERE code = ? "
                + "AND GETDATE() BETWEEN valid_from AND valid_to "
                + "AND ? >= min_order_value";

        try (
                Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(
                    1,
                    code);

            ps.setDouble(
                    2,
                    cartTotal);

            try (ResultSet rs = ps.executeQuery()) {

                if (!rs.next()) {
                    return null;
                }

                Voucher voucher
                        = mapVoucher(rs);

                if (!checkTotalUsage(voucher)) {
                    return null;
                }

                if (!checkUserUsage(
                        voucher,
                        userId)) {

                    return null;
                }

                return voucher;
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }

    private boolean checkTotalUsage(
            Voucher voucher) {

        if (voucher.getUsageLimit() == null) {
            return true;
        }

        String sql
                = "SELECT COUNT(*) AS total "
                + "FROM VOUCHER_USAGES "
                + "WHERE voucher_id = ?";

        try (
                Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(
                    1,
                    voucher.getVoucherId());

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    int used
                            = rs.getInt("total");

                    return used
                            < voucher.getUsageLimit();
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    private boolean checkUserUsage(
            Voucher voucher,
            int userId) {

        if (voucher.getPerUserLimit() == null) {
            return true;
        }

        String sql
                = "SELECT COUNT(*) AS total "
                + "FROM VOUCHER_USAGES "
                + "WHERE voucher_id = ? "
                + "AND user_id = ?";

        try (
                Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(
                    1,
                    voucher.getVoucherId());

            ps.setInt(
                    2,
                    userId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    int used
                            = rs.getInt("total");

                    return used
                            < voucher.getPerUserLimit();
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    public double calculateDiscount(
            Voucher voucher,
            double total) {

        if (voucher == null) {
            return 0;
        }

        double discount = 0;

        if ("AMOUNT".equalsIgnoreCase(
                voucher.getDiscountType())) {

            discount
                    = voucher.getDiscountValue();

        } else if ("PERCENT".equalsIgnoreCase(
                voucher.getDiscountType())) {

            discount
                    = total
                    * voucher.getDiscountValue()
                    / 100.0;

            if (voucher.getMaxDiscount() != null
                    && discount > voucher.getMaxDiscount()) {

                discount
                        = voucher.getMaxDiscount();
            }
        }

        if (discount > total) {
            discount = total;
        }

        return discount;
    }

    // ==================================================
    // SAU CHECKOUT THÀNH CÔNG
    // ==================================================
    public boolean saveVoucherUsage(
            int voucherId,
            int orderId,
            int userId) {

        String sql
                = "INSERT INTO VOUCHER_USAGES "
                + "(voucher_id, order_id, user_id, used_at) "
                + "VALUES (?, ?, ?, GETDATE())";

        try (
                Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(
                    1,
                    voucherId);

            ps.setInt(
                    2,
                    orderId);

            ps.setInt(
                    3,
                    userId);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    private Voucher mapVoucher(
            ResultSet rs)
            throws SQLException {

        Voucher voucher
                = new Voucher();

        voucher.setVoucherId(
                rs.getInt("voucher_id"));

        voucher.setCode(
                rs.getString("code"));

        voucher.setMinOrderValue(
                rs.getDouble("min_order_value"));

        voucher.setValidFrom(
                rs.getTimestamp("valid_from"));

        voucher.setValidTo(
                rs.getTimestamp("valid_to"));

        voucher.setDiscountType(
                rs.getString("discount_type"));

        voucher.setDiscountValue(
                rs.getDouble("discount_value"));

        double maxDiscount
                = rs.getDouble("max_discount");

        if (rs.wasNull()) {
            voucher.setMaxDiscount(null);
        } else {
            voucher.setMaxDiscount(maxDiscount);
        }

        int usageLimit
                = rs.getInt("usage_limit");

        if (rs.wasNull()) {
            voucher.setUsageLimit(null);
        } else {
            voucher.setUsageLimit(usageLimit);
        }

        int perUserLimit
                = rs.getInt("per_user_limit");

        if (rs.wasNull()) {
            voucher.setPerUserLimit(null);
        } else {
            voucher.setPerUserLimit(perUserLimit);
        }

        return voucher;
    }
}
