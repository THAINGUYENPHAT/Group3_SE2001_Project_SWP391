//package controller;
//
//import dao.VoucherDAO;
//
//import java.io.IOException;
//import java.sql.Timestamp;
//import java.time.LocalDateTime;
//import java.time.format.DateTimeFormatter;
//import java.util.List;
//import jakarta.servlet.ServletException;
//import jakarta.servlet.annotation.WebServlet;
//import jakarta.servlet.http.HttpServlet;
//import jakarta.servlet.http.HttpServletRequest;
//import jakarta.servlet.http.HttpServletResponse;
//
//import model.Voucher;
//
//@WebServlet(
//        name = "VoucherServlet",
//        urlPatterns = {"/admin/voucher"}
//)
//public class VoucherServlet
//        extends HttpServlet {
//
//    private VoucherDAO voucherDAO;
//
//    @Override
//    public void init()
//            throws ServletException {
//        voucherDAO
//                = new VoucherDAO();
//    }
//    @Override
//    protected void doGet(
//            HttpServletRequest request,
//            HttpServletResponse response)
//            throws ServletException,
//            IOException {
//
//        String action
//                = request.getParameter(
//                        "action");
//
//        if (action == null
//                || action.trim().isEmpty()) {
//
//            action = "list";
//        }
//
//        switch (action) {
//
//            case "edit":
//
//                showEdit(
//                        request,
//                        response);
//
//                break;
//
//            case "delete":
//
//                deleteVoucher(
//                        request,
//                        response);
//
//                break;
//
//            default:
//
//                showList(
//                        request,
//                        response);
//
//                break;
//        }
//    }
//
//    @Override
//    protected void doPost(
//            HttpServletRequest request,
//            HttpServletResponse response)
//            throws ServletException,
//            IOException {
//
//        request.setCharacterEncoding(
//                "UTF-8");
//
//        String action
//                = request.getParameter(
//                        "action");
//
//        if ("create".equals(action)) {
//
//            saveVoucher(
//                    request,
//                    response,
//                    false);
//
//        } else if ("update".equals(action)) {
//
//            saveVoucher(
//                    request,
//                    response,
//                    true);
//
//        } else {
//
//            redirect(
//                    request,
//                    response);
//        }
//    }
//
//    private void showList(
//            HttpServletRequest request,
//            HttpServletResponse response)
//            throws ServletException,
//            IOException {
//
//        List<Voucher> list
//                = voucherDAO.getAllVouchers();
//
//        request.setAttribute(
//                "vouchers",
//                list);
//
//        request.getRequestDispatcher(
//                "/WEB-INF/admin/voucher.jsp"
//        ).forward(
//                request,
//                response);
//    }
//
//    private void showEdit(
//            HttpServletRequest request,
//            HttpServletResponse response)
//            throws ServletException,
//            IOException {
//
//        try {
//
//            int id
//                    = Integer.parseInt(
//                            request.getParameter(
//                                    "id"));
//
//            Voucher voucher
//                    = voucherDAO
//                            .getVoucherById(id);
//
//            if (voucher == null) {
//
//                redirect(
//                        request,
//                        response);
//
//                return;
//            }
//
//            request.setAttribute(
//                    "editVoucher",
//                    voucher);
//
//            DateTimeFormatter formatter
//                    = DateTimeFormatter
//                            .ofPattern(
//                                    "yyyy-MM-dd'T'HH:mm");
//
//            request.setAttribute(
//                    "validFromValue",
//                    voucher.getValidFrom()
//                            .toLocalDateTime()
//                            .format(formatter));
//
//            request.setAttribute(
//                    "validToValue",
//                    voucher.getValidTo()
//                            .toLocalDateTime()
//                            .format(formatter));
//
//            showList(
//                    request,
//                    response);
//
//        } catch (NumberFormatException e) {
//
//            redirect(
//                    request,
//                    response);
//        }
//    }
//
//    private void saveVoucher(
//            HttpServletRequest request,
//            HttpServletResponse response,
//            boolean update)
//            throws IOException {
//
//        try {
//
//            Voucher voucher
//                    = new Voucher();
//
//            int voucherId = 0;
//
//            if (update) {
//
//                voucherId
//                        = Integer.parseInt(
//                                request.getParameter(
//                                        "voucherId"));
//
//                voucher.setVoucherId(
//                        voucherId);
//            }
//
//            String code
//                    = request.getParameter(
//                            "code")
//                            .trim()
//                            .toUpperCase();
//
//            String discountType
//                    = request.getParameter(
//                            "discountType");
//
//            double discountValue
//                    = Double.parseDouble(
//                            request.getParameter(
//                                    "discountValue"));
//
//            double minOrderValue
//                    = Double.parseDouble(
//                            request.getParameter(
//                                    "minOrderValue"));
//
//            Timestamp validFrom
//                    = convertTimestamp(
//                            request.getParameter(
//                                    "validFrom"));
//
//            Timestamp validTo
//                    = convertTimestamp(
//                            request.getParameter(
//                                    "validTo"));
//
//            Double maxDiscount
//                    = parseNullableDouble(
//                            request.getParameter(
//                                    "maxDiscount"));
//
//            Integer usageLimit
//                    = parseNullableInteger(
//                            request.getParameter(
//                                    "usageLimit"));
//
//            Integer perUserLimit
//                    = parseNullableInteger(
//                            request.getParameter(
//                                    "perUserLimit"));
//
//            if (code.isEmpty()) {
//
//                fail(
//                        request,
//                        "Mã Voucher không được để trống.");
//
//                redirect(
//                        request,
//                        response);
//
//                return;
//            }
//
//            boolean duplicate
//                    = update
//                            ? voucherDAO
//                                    .existsCodeExceptId(
//                                            code,
//                                            voucherId)
//                            : voucherDAO
//                                    .existsCode(code);
//
//            if (duplicate) {
//
//                fail(
//                        request,
//                        "Mã Voucher đã tồn tại.");
//
//                redirect(
//                        request,
//                        response);
//
//                return;
//            }
//
//            if (!"AMOUNT".equals(discountType)
//                    && !"PERCENT".equals(discountType)) {
//
//                fail(
//                        request,
//                        "Loại giảm giá không hợp lệ.");
//
//                redirect(
//                        request,
//                        response);
//
//                return;
//            }
//
//            if (discountValue <= 0) {
//
//                fail(
//                        request,
//                        "Giá trị giảm phải lớn hơn 0.");
//
//                redirect(
//                        request,
//                        response);
//
//                return;
//            }
//
//            if ("PERCENT".equals(discountType)
//                    && discountValue > 100) {
//
//                fail(
//                        request,
//                        "Phần trăm không được lớn hơn 100.");
//
//                redirect(
//                        request,
//                        response);
//
//                return;
//            }
//
//            if ("AMOUNT".equals(discountType)) {
//                maxDiscount = null;
//            }
//
//            if (minOrderValue < 0) {
//
//                fail(
//                        request,
//                        "Đơn tối thiểu không hợp lệ.");
//
//                redirect(
//                        request,
//                        response);
//
//                return;
//            }
//
//            if (!validTo.after(validFrom)) {
//
//                fail(
//                        request,
//                        "Ngày kết thúc phải sau ngày bắt đầu.");
//
//                redirect(
//                        request,
//                        response);
//
//                return;
//            }
//
//            voucher.setCode(code);
//
//            voucher.setDiscountType(
//                    discountType);
//
//            voucher.setDiscountValue(
//                    discountValue);
//
//            voucher.setMinOrderValue(
//                    minOrderValue);
//
//            voucher.setValidFrom(
//                    validFrom);
//
//            voucher.setValidTo(
//                    validTo);
//
//            voucher.setMaxDiscount(
//                    maxDiscount);
//
//            voucher.setUsageLimit(
//                    usageLimit);
//
//            voucher.setPerUserLimit(
//                    perUserLimit);
//
//            boolean success;
//
//            if (update) {
//
//                success
//                        = voucherDAO
//                                .updateVoucher(
//                                        voucher);
//
//            } else {
//
//                success
//                        = voucherDAO
//                                .insertVoucher(
//                                        voucher);
//            }
//
//            if (success) {
//
//                request.getSession()
//                        .setAttribute(
//                                "successMessage",
//                                update
//                                        ? "Cập nhật Voucher thành công."
//                                        : "Tạo Voucher thành công.");
//
//            } else {
//
//                fail(
//                        request,
//                        "Không thể lưu Voucher.");
//            }
//
//        } catch (Exception e) {
//
//            e.printStackTrace();
//
//            fail(
//                    request,
//                    "Dữ liệu Voucher không hợp lệ.");
//        }
//
//        redirect(
//                request,
//                response);
//    }
//
//    private void deleteVoucher(
//            HttpServletRequest request,
//            HttpServletResponse response)
//            throws IOException {
//
//        try {
//
//            int id
//                    = Integer.parseInt(
//                            request.getParameter(
//                                    "id"));
//
//            boolean success
//                    = voucherDAO
//                            .deleteVoucher(id);
//
//            if (success) {
//
//                request.getSession()
//                        .setAttribute(
//                                "successMessage",
//                                "Đã xóa Voucher.");
//
//            } else {
//
//                fail(
//                        request,
//                        "Không thể xóa Voucher.");
//            }
//
//        } catch (Exception e) {
//
//            fail(
//                    request,
//                    "Voucher không hợp lệ.");
//        }
//
//        redirect(
//                request,
//                response);
//    }
//
//    private Timestamp convertTimestamp(
//            String value) {
//
//        LocalDateTime dateTime
//                = LocalDateTime.parse(
//                        value,
//                        DateTimeFormatter.ofPattern(
//                                "yyyy-MM-dd'T'HH:mm"));
//
//        return Timestamp.valueOf(
//                dateTime);
//    }
//
//    private Double parseNullableDouble(
//            String value) {
//
//        if (value == null
//                || value.trim().isEmpty()) {
//
//            return null;
//        }
//
//        return Double.parseDouble(
//                value);
//    }
//
//    private Integer parseNullableInteger(
//            String value) {
//
//        if (value == null
//                || value.trim().isEmpty()) {
//
//            return null;
//        }
//
//        return Integer.parseInt(
//                value);
//    }
//
//    private void fail(
//            HttpServletRequest request,
//            String message) {
//
//        request.getSession()
//                .setAttribute(
//                        "errorMessage",
//                        message);
//    }
//
//    private void redirect(
//            HttpServletRequest request,
//            HttpServletResponse response)
//            throws IOException {
//
//        response.sendRedirect(
//                request.getContextPath()
//                + "/admin/voucher");
//    }
//}
