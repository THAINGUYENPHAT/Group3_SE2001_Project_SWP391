package dao;

import db.DBContext;

import model.Voucher;
import model.VoucherUsageDTO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;

import java.util.ArrayList;
import java.util.List;

public class VoucherDAO extends DBContext {

    public List<Voucher> getAllVouchers() {

        List<Voucher> list
                = new ArrayList<>();

        String sql
                = "SELECT "
                + "voucher_id, "
                + "code, "
                + "min_order_value, "
                + "valid_from, "
                + "valid_to, "
                + "discount_type, "
                + "discount_value, "
                + "max_discount, "
                + "usage_limit, "
                + "per_user_limit "
                + "FROM VOUCHER "
                + "ORDER BY voucher_id DESC";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql); ResultSet rs
                = ps.executeQuery()) {

            while (rs.next()) {

                list.add(
                        mapVoucher(rs)
                );
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
                + "voucher_id, "
                + "code, "
                + "min_order_value, "
                + "valid_from, "
                + "valid_to, "
                + "discount_type, "
                + "discount_value, "
                + "max_discount, "
                + "usage_limit, "
                + "per_user_limit "
                + "FROM VOUCHER "
                + "WHERE voucher_id = ?";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(
                    1,
                    voucherId
            );

            try (
                    ResultSet rs
                    = ps.executeQuery()) {

                if (rs.next()) {

                    return mapVoucher(rs);
                }
            }

        } catch (SQLException e) {

            e.printStackTrace();
        }

        return null;
    }

    public List<Voucher> getAvailableVouchers(
            double orderTotal,
            int userId) {

        List<Voucher> list
                = new ArrayList<>();

        String sql
                = "SELECT "
                + "v.voucher_id, "
                + "v.code, "
                + "v.min_order_value, "
                + "v.valid_from, "
                + "v.valid_to, "
                + "v.discount_type, "
                + "v.discount_value, "
                + "v.max_discount, "
                + "v.usage_limit, "
                + "v.per_user_limit "
                + "FROM VOUCHER v "
                + "WHERE v.valid_from <= GETDATE() "
                + "AND v.valid_to >= GETDATE() "
                + "AND v.min_order_value <= ? "
                + "AND ( "
                + "v.usage_limit IS NULL "
                + "OR ( "
                + "SELECT COUNT(*) "
                + "FROM VOUCHER_USAGES vu "
                + "WHERE vu.voucher_id = v.voucher_id "
                + ") < v.usage_limit "
                + ") "
                + "AND ( "
                + "v.per_user_limit IS NULL "
                + "OR ( "
                + "SELECT COUNT(*) "
                + "FROM VOUCHER_USAGES vu2 "
                + "WHERE vu2.voucher_id = v.voucher_id "
                + "AND vu2.user_id = ? "
                + ") < v.per_user_limit "
                + ") "
                + "ORDER BY v.discount_value DESC";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setDouble(
                    1,
                    orderTotal
            );

            ps.setInt(
                    2,
                    userId
            );

            try (
                    ResultSet rs
                    = ps.executeQuery()) {

                while (rs.next()) {

                    list.add(
                            mapVoucher(rs)
                    );
                }
            }

        } catch (SQLException e) {

            e.printStackTrace();
        }

        return list;
    }

    public Voucher getValidVoucher(
            String code,
            double orderTotal,
            int userId) {

        if (code == null
                || code.trim().isEmpty()) {

            return null;
        }

        String sql
                = "SELECT "
                + "v.voucher_id, "
                + "v.code, "
                + "v.min_order_value, "
                + "v.valid_from, "
                + "v.valid_to, "
                + "v.discount_type, "
                + "v.discount_value, "
                + "v.max_discount, "
                + "v.usage_limit, "
                + "v.per_user_limit "
                + "FROM VOUCHER v "
                + "WHERE UPPER(v.code) = UPPER(?) "
                + "AND v.valid_from <= GETDATE() "
                + "AND v.valid_to >= GETDATE() "
                + "AND v.min_order_value <= ? "
                + "AND ( "
                + "v.usage_limit IS NULL "
                + "OR ( "
                + "SELECT COUNT(*) "
                + "FROM VOUCHER_USAGES vu "
                + "WHERE vu.voucher_id = v.voucher_id "
                + ") < v.usage_limit "
                + ") "
                + "AND ( "
                + "v.per_user_limit IS NULL "
                + "OR ( "
                + "SELECT COUNT(*) "
                + "FROM VOUCHER_USAGES vu2 "
                + "WHERE vu2.voucher_id = v.voucher_id "
                + "AND vu2.user_id = ? "
                + ") < v.per_user_limit "
                + ")";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setString(
                    1,
                    code.trim()
            );

            ps.setDouble(
                    2,
                    orderTotal
            );

            ps.setInt(
                    3,
                    userId
            );

            try (
                    ResultSet rs
                    = ps.executeQuery()) {

                if (rs.next()) {

                    return mapVoucher(rs);
                }
            }

        } catch (SQLException e) {

            e.printStackTrace();
        }

        return null;
    }

    public Voucher getAvailableVoucherById(
            int voucherId,
            double orderTotal,
            int userId) {

        Voucher voucher
                = getVoucherById(
                        voucherId
                );

        if (voucher == null) {

            return null;
        }

        return getValidVoucher(
                voucher.getCode(),
                orderTotal,
                userId
        );
    }

    public boolean existsCode(
            String code) {

        if (code == null
                || code.trim().isEmpty()) {

            return false;
        }

        String sql
                = "SELECT 1 "
                + "FROM VOUCHER "
                + "WHERE UPPER(code) = UPPER(?)";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setString(
                    1,
                    code.trim()
            );

            try (
                    ResultSet rs
                    = ps.executeQuery()) {

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

        if (code == null
                || code.trim().isEmpty()) {

            return false;
        }

        String sql
                = "SELECT 1 "
                + "FROM VOUCHER "
                + "WHERE UPPER(code) = UPPER(?) "
                + "AND voucher_id <> ?";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setString(
                    1,
                    code.trim()
            );

            ps.setInt(
                    2,
                    voucherId
            );

            try (
                    ResultSet rs
                    = ps.executeQuery()) {

                return rs.next();
            }

        } catch (SQLException e) {

            e.printStackTrace();
        }

        return false;
    }

    public boolean insertVoucher(
            Voucher voucher) {

        if (voucher == null) {

            return false;
        }

        String sql
                = "INSERT INTO VOUCHER ("
                + "code, "
                + "min_order_value, "
                + "valid_from, "
                + "valid_to, "
                + "discount_type, "
                + "discount_value, "
                + "max_discount, "
                + "usage_limit, "
                + "per_user_limit"
                + ") "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(
                        sql,
                        Statement.RETURN_GENERATED_KEYS
                )) {

            ps.setString(
                    1,
                    voucher.getCode()
            );

            ps.setDouble(
                    2,
                    voucher.getMinOrderValue()
            );

            ps.setTimestamp(
                    3,
                    voucher.getValidFrom()
            );

            ps.setTimestamp(
                    4,
                    voucher.getValidTo()
            );

            ps.setString(
                    5,
                    voucher.getDiscountType()
            );

            ps.setDouble(
                    6,
                    voucher.getDiscountValue()
            );

            if (voucher.getMaxDiscount() == null) {

                ps.setNull(
                        7,
                        Types.DECIMAL
                );

            } else {

                ps.setDouble(
                        7,
                        voucher.getMaxDiscount()
                );
            }

            if (voucher.getUsageLimit() == null) {

                ps.setNull(
                        8,
                        Types.INTEGER
                );

            } else {

                ps.setInt(
                        8,
                        voucher.getUsageLimit()
                );
            }

            if (voucher.getPerUserLimit() == null) {

                ps.setNull(
                        9,
                        Types.INTEGER
                );

            } else {

                ps.setInt(
                        9,
                        voucher.getPerUserLimit()
                );
            }

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {

            e.printStackTrace();
        }

        return false;
    }

    public boolean updateVoucher(
            Voucher voucher) {

        if (voucher == null) {

            return false;
        }

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
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setString(
                    1,
                    voucher.getCode()
            );

            ps.setDouble(
                    2,
                    voucher.getMinOrderValue()
            );

            ps.setTimestamp(
                    3,
                    voucher.getValidFrom()
            );

            ps.setTimestamp(
                    4,
                    voucher.getValidTo()
            );

            ps.setString(
                    5,
                    voucher.getDiscountType()
            );

            ps.setDouble(
                    6,
                    voucher.getDiscountValue()
            );

            if (voucher.getMaxDiscount() == null) {

                ps.setNull(
                        7,
                        Types.DECIMAL
                );

            } else {

                ps.setDouble(
                        7,
                        voucher.getMaxDiscount()
                );
            }

            if (voucher.getUsageLimit() == null) {

                ps.setNull(
                        8,
                        Types.INTEGER
                );

            } else {

                ps.setInt(
                        8,
                        voucher.getUsageLimit()
                );
            }

            if (voucher.getPerUserLimit() == null) {

                ps.setNull(
                        9,
                        Types.INTEGER
                );

            } else {

                ps.setInt(
                        9,
                        voucher.getPerUserLimit()
                );
            }

            ps.setInt(
                    10,
                    voucher.getVoucherId()
            );

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {

            e.printStackTrace();
        }

        return false;
    }

    public boolean deleteVoucher(
            int voucherId) {

        String sql
                = "DELETE FROM VOUCHER "
                + "WHERE voucher_id = ?";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(
                    1,
                    voucherId
            );

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {

            e.printStackTrace();
        }

        return false;
    }

    public double calculateDiscount(
            Voucher voucher,
            double orderTotal) {

        if (voucher == null
                || orderTotal <= 0) {

            return 0;
        }

        double discount = 0;

        if ("AMOUNT".equalsIgnoreCase(
                voucher.getDiscountType()
        )) {

            discount
                    = voucher.getDiscountValue();

        } else if ("PERCENT".equalsIgnoreCase(
                voucher.getDiscountType()
        )) {

            discount
                    = orderTotal
                    * voucher.getDiscountValue()
                    / 100.0;


            if (voucher.getMaxDiscount() != null
                    && discount
                    > voucher.getMaxDiscount()) {

                discount
                        = voucher.getMaxDiscount();
            }
        }


        if (discount < 0) {

            discount = 0;
        }


        
        if (discount > orderTotal) {

            discount
                    = orderTotal;
        }

        return discount;
    }

    public boolean saveVoucherUsage(
            int voucherId,
            int orderId,
            int userId) {

        String sql
                = "INSERT INTO VOUCHER_USAGES "
                + "(voucher_id, order_id, user_id) "
                + "VALUES (?, ?, ?)";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(
                    1,
                    voucherId
            );

            ps.setInt(
                    2,
                    orderId
            );

            ps.setInt(
                    3,
                    userId
            );

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {

            e.printStackTrace();
        }

        return false;
    }

    
    public int countUsedVouchers() {

        String sql
                = "SELECT COUNT(DISTINCT voucher_id) "
                + "FROM VOUCHER_USAGES";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql); ResultSet rs
                = ps.executeQuery()) {

            if (rs.next()) {

                return rs.getInt(1);
            }

        } catch (SQLException e) {

            e.printStackTrace();
        }

        return 0;
    }

    
    public int countAllVoucherUsages() {

        String sql
                = "SELECT COUNT(*) "
                + "FROM VOUCHER_USAGES";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql); ResultSet rs
                = ps.executeQuery()) {

            if (rs.next()) {

                return rs.getInt(1);
            }

        } catch (SQLException e) {

            e.printStackTrace();
        }

        return 0;
    }

    
    public int countVoucherUsageLast7Days() {

        String sql
                = "SELECT COUNT(*) "
                + "FROM VOUCHER_USAGES "
                + "WHERE used_at >= "
                + "DATEADD(DAY, -7, GETDATE())";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql); ResultSet rs
                = ps.executeQuery()) {

            if (rs.next()) {

                return rs.getInt(1);
            }

        } catch (SQLException e) {

            e.printStackTrace();
        }

        return 0;
    }

    
    public List<VoucherUsageDTO> getRecentVoucherUsages() {

        List<VoucherUsageDTO> list
                = new ArrayList<>();

        String sql
                = "SELECT "
                + "vu.usage_id, "
                + "vu.voucher_id, "
                + "v.code AS voucher_code, "
                + "vu.order_id, "
                + "vu.user_id, "
                + "vu.used_at "
                + "FROM VOUCHER_USAGES vu "
                + "INNER JOIN VOUCHER v "
                + "ON vu.voucher_id = v.voucher_id "
                + "WHERE vu.used_at >= "
                + "DATEADD(DAY, -7, GETDATE()) "
                + "ORDER BY vu.used_at DESC";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql); ResultSet rs
                = ps.executeQuery()) {

            while (rs.next()) {

                list.add(
                        mapVoucherUsage(rs)
                );
            }

        } catch (SQLException e) {

            e.printStackTrace();
        }

        return list;
    }

    
    public List<VoucherUsageDTO> getAllVoucherUsages() {

        List<VoucherUsageDTO> list
                = new ArrayList<>();

        String sql
                = "SELECT "
                + "vu.usage_id, "
                + "vu.voucher_id, "
                + "v.code AS voucher_code, "
                + "vu.order_id, "
                + "vu.user_id, "
                + "vu.used_at "
                + "FROM VOUCHER_USAGES vu "
                + "INNER JOIN VOUCHER v "
                + "ON vu.voucher_id = v.voucher_id "
                + "ORDER BY vu.used_at DESC";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql); ResultSet rs
                = ps.executeQuery()) {

            while (rs.next()) {

                list.add(
                        mapVoucherUsage(rs)
                );
            }

        } catch (SQLException e) {

            e.printStackTrace();
        }

        return list;
    }

 
    public List<VoucherUsageDTO> getVoucherUsagesByVoucherId(
            int voucherId) {

        List<VoucherUsageDTO> list
                = new ArrayList<>();

        String sql
                = "SELECT "
                + "vu.usage_id, "
                + "vu.voucher_id, "
                + "v.code AS voucher_code, "
                + "vu.order_id, "
                + "vu.user_id, "
                + "vu.used_at "
                + "FROM VOUCHER_USAGES vu "
                + "INNER JOIN VOUCHER v "
                + "ON vu.voucher_id = v.voucher_id "
                + "WHERE vu.voucher_id = ? "
                + "ORDER BY vu.used_at DESC";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(
                    1,
                    voucherId
            );

            try (
                    ResultSet rs
                    = ps.executeQuery()) {

                while (rs.next()) {

                    list.add(
                            mapVoucherUsage(rs)
                    );
                }
            }

        } catch (SQLException e) {

            e.printStackTrace();
        }

        return list;
    }

   
    public int countUsageByVoucherId(
            int voucherId) {

        String sql
                = "SELECT COUNT(*) "
                + "FROM VOUCHER_USAGES "
                + "WHERE voucher_id = ?";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(
                    1,
                    voucherId
            );

            try (
                    ResultSet rs
                    = ps.executeQuery()) {

                if (rs.next()) {

                    return rs.getInt(1);
                }
            }

        } catch (SQLException e) {

            e.printStackTrace();
        }

        return 0;
    }

 
    public int countUsageByUser(
            int voucherId,
            int userId) {

        String sql
                = "SELECT COUNT(*) "
                + "FROM VOUCHER_USAGES "
                + "WHERE voucher_id = ? "
                + "AND user_id = ?";

        try (
                Connection conn
                = getConnection(); PreparedStatement ps
                = conn.prepareStatement(sql)) {

            ps.setInt(
                    1,
                    voucherId
            );

            ps.setInt(
                    2,
                    userId
            );

            try (
                    ResultSet rs
                    = ps.executeQuery()) {

                if (rs.next()) {

                    return rs.getInt(1);
                }
            }

        } catch (SQLException e) {

            e.printStackTrace();
        }

        return 0;
    }

    
    private Voucher mapVoucher(
            ResultSet rs)
            throws SQLException {

        Voucher voucher
                = new Voucher();

        voucher.setVoucherId(
                rs.getInt(
                        "voucher_id"
                )
        );

        voucher.setCode(
                rs.getString(
                        "code"
                )
        );

        voucher.setMinOrderValue(
                rs.getDouble(
                        "min_order_value"
                )
        );

        voucher.setValidFrom(
                rs.getTimestamp(
                        "valid_from"
                )
        );

        voucher.setValidTo(
                rs.getTimestamp(
                        "valid_to"
                )
        );

        voucher.setDiscountType(
                rs.getString(
                        "discount_type"
                )
        );

        voucher.setDiscountValue(
                rs.getDouble(
                        "discount_value"
                )
        );

      
        Object maxDiscount
                = rs.getObject(
                        "max_discount"
                );

        voucher.setMaxDiscount(
                maxDiscount == null
                        ? null
                        : rs.getDouble(
                                "max_discount"
                        )
        );

      
        Object usageLimit
                = rs.getObject(
                        "usage_limit"
                );

        voucher.setUsageLimit(
                usageLimit == null
                        ? null
                        : rs.getInt(
                                "usage_limit"
                        )
        );

        
        Object perUserLimit
                = rs.getObject(
                        "per_user_limit"
                );

        voucher.setPerUserLimit(
                perUserLimit == null
                        ? null
                        : rs.getInt(
                                "per_user_limit"
                        )
        );

        return voucher;
    }

    
    private VoucherUsageDTO mapVoucherUsage(
            ResultSet rs)
            throws SQLException {

        VoucherUsageDTO usage
                = new VoucherUsageDTO();

        usage.setUsageId(
                rs.getInt(
                        "usage_id"
                )
        );

        usage.setVoucherId(
                rs.getInt(
                        "voucher_id"
                )
        );

        usage.setVoucherCode(
                rs.getString(
                        "voucher_code"
                )
        );

        usage.setOrderId(
                rs.getInt(
                        "order_id"
                )
        );

        usage.setUserId(
                rs.getInt(
                        "user_id"
                )
        );

        usage.setUsedAt(
                rs.getTimestamp(
                        "used_at"
                )
        );

        return usage;
    }
}
