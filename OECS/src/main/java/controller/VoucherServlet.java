package controller;

import dao.VoucherDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;

import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import model.User;
import model.Voucher;

import java.io.IOException;

import java.sql.Timestamp;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@WebServlet(
        name = "VoucherServlet",
        urlPatterns = {"/staff/voucher"}
)
public class VoucherServlet extends HttpServlet {

    private VoucherDAO voucherDAO;

    private final DateTimeFormatter formatter
            = DateTimeFormatter.ofPattern(
                    "yyyy-MM-dd'T'HH:mm"
            );

    // =====================================================
    // INIT
    // =====================================================
    @Override
    public void init()
            throws ServletException {

        voucherDAO
                = new VoucherDAO();
    }

    // =====================================================
    // GET
    //
    // /staff/voucher
    // /staff/voucher?view=create
    // /staff/voucher?view=edit&id=1
    // /staff/voucher?view=delete&id=1
    // =====================================================
    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding(
                "UTF-8"
        );

        // Chỉ Staff
        if (!checkStaff(
                request,
                response
        )) {

            return;
        }

        String view
                = request.getParameter(
                        "view"
                );

        if (view == null
                || view.trim().isEmpty()) {

            view = "list";
        }

        switch (view) {

            case "create":

                showCreate(
                        request,
                        response
                );

                break;

            case "edit":

                showEdit(
                        request,
                        response
                );

                break;

            case "delete":

                showDelete(
                        request,
                        response
                );

                break;
            case "usage":

                showUsage(
                        request,
                        response
                );

                break;

            case "list":

            default:

                showList(
                        request,
                        response
                );

                break;
        }
    }

    // =====================================================
    // POST
    // =====================================================
    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding(
                "UTF-8"
        );

        // Chỉ Staff
        if (!checkStaff(
                request,
                response
        )) {

            return;
        }

        String action
                = request.getParameter(
                        "action"
                );

        if (action == null
                || action.trim().isEmpty()) {

            redirectList(
                    request,
                    response
            );

            return;
        }

        switch (action) {

            case "create":

                createVoucher(
                        request,
                        response
                );

                break;

            case "update":

                updateVoucher(
                        request,
                        response
                );

                break;

            case "delete":

                deleteVoucher(
                        request,
                        response
                );

                break;

            default:

                redirectList(
                        request,
                        response
                );

                break;
        }
    }

    // =====================================================
    // CHECK STAFF
    // =====================================================
    private boolean checkStaff(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        HttpSession session
                = request.getSession(false);

        if (session == null) {

            response.sendRedirect(
                    request.getContextPath()
                    + "/login"
            );

            return false;
        }

        Object value
                = session.getAttribute(
                        "loggedInUser"
                );

        if (!(value instanceof User)) {

            response.sendRedirect(
                    request.getContextPath()
                    + "/login"
            );

            return false;
        }

        User loggedInUser
                = (User) value;

        if (!loggedInUser.isStaff()) {

            session.setAttribute(
                    "toastMessage",
                    "Chỉ Staff mới có quyền quản lý Voucher!"
            );

            session.setAttribute(
                    "toastType",
                    "error"
            );

            response.sendRedirect(
                    request.getContextPath()
                    + "/home"
            );

            return false;
        }

        return true;
    }

    // =====================================================
    // LIST
    // =====================================================
    private void showList(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        // Tất cả Voucher
        request.setAttribute(
                "vouchers",
                voucherDAO.getAllVouchers()
        );

        // Số mã Voucher đã từng được sử dụng
        request.setAttribute(
                "usedVoucherCount",
                voucherDAO.countUsedVouchers()
        );

        // Chỉ lấy lịch sử sử dụng trong 7 ngày gần nhất
        request.setAttribute(
                "recentVoucherUsages",
                voucherDAO.getRecentVoucherUsages()
        );

        request.getRequestDispatcher(
                "/WEB-INF/voucher/list.jsp"
        ).forward(
                request,
                response
        );
    }

    // =====================================================
// SHOW ALL VOUCHER USAGE HISTORY
// =====================================================
    private void showUsage(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setAttribute(
                "voucherUsages",
                voucherDAO.getAllVoucherUsages()
        );

        request.getRequestDispatcher(
                "/WEB-INF/voucher/usage.jsp"
        ).forward(
                request,
                response
        );
    }

    // =====================================================
    // SHOW CREATE
    // =====================================================
    private void showCreate(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.getRequestDispatcher(
                "/WEB-INF/voucher/create.jsp"
        ).forward(
                request,
                response
        );
    }

    // =====================================================
    // CREATE
    // =====================================================
    private void createVoucher(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        try {

            Voucher voucher
                    = getVoucherFromRequest(
                            request
                    );

            String error
                    = validateVoucher(
                            voucher,
                            false
                    );

            if (error != null) {

                setErrorMessage(
                        request,
                        error
                );

                redirectCreate(
                        request,
                        response
                );

                return;
            }

            boolean success
                    = voucherDAO
                            .insertVoucher(
                                    voucher
                            );

            if (success) {

                setSuccessMessage(
                        request,
                        "Tạo Voucher thành công."
                );

                redirectList(
                        request,
                        response
                );

            } else {

                setErrorMessage(
                        request,
                        "Không thể tạo Voucher."
                );

                redirectCreate(
                        request,
                        response
                );
            }

        } catch (Exception e) {

            e.printStackTrace();

            setErrorMessage(
                    request,
                    "Dữ liệu Voucher không hợp lệ."
            );

            redirectCreate(
                    request,
                    response
            );
        }
    }

    // =====================================================
    // SHOW EDIT
    // =====================================================
    private void showEdit(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        try {

            int voucherId
                    = Integer.parseInt(
                            request.getParameter(
                                    "id"
                            )
                    );

            Voucher voucher
                    = voucherDAO
                            .getVoucherById(
                                    voucherId
                            );

            if (voucher == null) {

                setErrorMessage(
                        request,
                        "Không tìm thấy Voucher."
                );

                redirectList(
                        request,
                        response
                );

                return;
            }

            request.setAttribute(
                    "voucher",
                    voucher
            );

            if (voucher.getValidFrom()
                    != null) {

                request.setAttribute(
                        "validFromValue",
                        voucher
                                .getValidFrom()
                                .toLocalDateTime()
                                .format(
                                        formatter
                                )
                );
            }

            if (voucher.getValidTo()
                    != null) {

                request.setAttribute(
                        "validToValue",
                        voucher
                                .getValidTo()
                                .toLocalDateTime()
                                .format(
                                        formatter
                                )
                );
            }

            request.getRequestDispatcher(
                    "/WEB-INF/voucher/edit.jsp"
            ).forward(
                    request,
                    response
            );

        } catch (NumberFormatException e) {

            setErrorMessage(
                    request,
                    "ID Voucher không hợp lệ."
            );

            redirectList(
                    request,
                    response
            );
        }
    }

    // =====================================================
    // UPDATE
    // =====================================================
    private void updateVoucher(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        int voucherId = -1;

        try {

            voucherId
                    = Integer.parseInt(
                            request.getParameter(
                                    "voucherId"
                            )
                    );

            Voucher oldVoucher
                    = voucherDAO
                            .getVoucherById(
                                    voucherId
                            );

            if (oldVoucher == null) {

                setErrorMessage(
                        request,
                        "Voucher không tồn tại."
                );

                redirectList(
                        request,
                        response
                );

                return;
            }

            Voucher voucher
                    = getVoucherFromRequest(
                            request
                    );

            voucher.setVoucherId(
                    voucherId
            );

            String error
                    = validateVoucher(
                            voucher,
                            true
                    );

            if (error != null) {

                setErrorMessage(
                        request,
                        error
                );

                redirectEdit(
                        request,
                        response,
                        voucherId
                );

                return;
            }

            boolean success
                    = voucherDAO
                            .updateVoucher(
                                    voucher
                            );

            if (success) {

                setSuccessMessage(
                        request,
                        "Cập nhật Voucher thành công."
                );

                redirectList(
                        request,
                        response
                );

            } else {

                setErrorMessage(
                        request,
                        "Cập nhật Voucher thất bại."
                );

                redirectEdit(
                        request,
                        response,
                        voucherId
                );
            }

        } catch (Exception e) {

            e.printStackTrace();

            setErrorMessage(
                    request,
                    "Dữ liệu Voucher không hợp lệ."
            );

            if (voucherId > 0) {

                redirectEdit(
                        request,
                        response,
                        voucherId
                );

            } else {

                redirectList(
                        request,
                        response
                );
            }
        }
    }

    // =====================================================
    // SHOW DELETE
    // =====================================================
    private void showDelete(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        try {

            int voucherId
                    = Integer.parseInt(
                            request.getParameter(
                                    "id"
                            )
                    );

            Voucher voucher
                    = voucherDAO
                            .getVoucherById(
                                    voucherId
                            );

            if (voucher == null) {

                setErrorMessage(
                        request,
                        "Không tìm thấy Voucher."
                );

                redirectList(
                        request,
                        response
                );

                return;
            }

            request.setAttribute(
                    "voucher",
                    voucher
            );

            request.getRequestDispatcher(
                    "/WEB-INF/voucher/delete.jsp"
            ).forward(
                    request,
                    response
            );

        } catch (NumberFormatException e) {

            setErrorMessage(
                    request,
                    "ID Voucher không hợp lệ."
            );

            redirectList(
                    request,
                    response
            );
        }
    }

    // =====================================================
    // DELETE
    // =====================================================
    private void deleteVoucher(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        try {

            int voucherId
                    = Integer.parseInt(
                            request.getParameter(
                                    "voucherId"
                            )
                    );

            Voucher voucher
                    = voucherDAO
                            .getVoucherById(
                                    voucherId
                            );

            if (voucher == null) {

                setErrorMessage(
                        request,
                        "Voucher không tồn tại."
                );

                redirectList(
                        request,
                        response
                );

                return;
            }

            boolean success
                    = voucherDAO
                            .deleteVoucher(
                                    voucherId
                            );

            if (success) {

                setSuccessMessage(
                        request,
                        "Xóa Voucher thành công."
                );

            } else {

                setErrorMessage(
                        request,
                        "Không thể xóa Voucher."
                );
            }

        } catch (Exception e) {

            e.printStackTrace();

            setErrorMessage(
                    request,
                    "Không thể xóa Voucher. "
                    + "Voucher có thể đã được sử dụng trong đơn hàng."
            );
        }

        redirectList(
                request,
                response
        );
    }

    // =====================================================
    // GET FORM DATA
    // =====================================================
    private Voucher getVoucherFromRequest(
            HttpServletRequest request) {

        Voucher voucher
                = new Voucher();

        // CODE
        String code
                = request.getParameter(
                        "code"
                );

        if (code != null) {

            code
                    = code.trim()
                            .toUpperCase();
        }

        voucher.setCode(
                code
        );

        // TYPE
        String discountType
                = request.getParameter(
                        "discountType"
                );

        if (discountType != null) {

            discountType
                    = discountType
                            .trim()
                            .toUpperCase();
        }

        voucher.setDiscountType(
                discountType
        );

        // VALUE
        double discountValue
                = Double.parseDouble(
                        request.getParameter(
                                "discountValue"
                        )
                );

        voucher.setDiscountValue(
                discountValue
        );

        // MIN ORDER
        double minOrderValue
                = Double.parseDouble(
                        request.getParameter(
                                "minOrderValue"
                        )
                );

        voucher.setMinOrderValue(
                minOrderValue
        );

        // DATE
        Timestamp validFrom
                = parseTimestamp(
                        request.getParameter(
                                "validFrom"
                        )
                );

        voucher.setValidFrom(
                validFrom
        );

        Timestamp validTo
                = parseTimestamp(
                        request.getParameter(
                                "validTo"
                        )
                );

        voucher.setValidTo(
                validTo
        );
        ;

        // MAX DISCOUNT
        Double maxDiscount
                = parseNullableDouble(
                        request.getParameter(
                                "maxDiscount"
                        )
                );

        if ("AMOUNT".equalsIgnoreCase(
                discountType
        )) {

            voucher.setMaxDiscount(
                    null
            );

        } else {

            voucher.setMaxDiscount(
                    maxDiscount
            );
        }

        // USAGE LIMIT
        Integer usageLimit
                = parseNullableInteger(
                        request.getParameter(
                                "usageLimit"
                        )
                );

        voucher.setUsageLimit(
                usageLimit
        );

        // PER USER
        Integer perUserLimit
                = parseNullableInteger(
                        request.getParameter(
                                "perUserLimit"
                        )
                );

        voucher.setPerUserLimit(
                perUserLimit
        );

        return voucher;
    }

    // =====================================================
    // VALIDATE
    // =====================================================
    private String validateVoucher(
            Voucher voucher,
            boolean isUpdate) {

        // CODE
        if (voucher.getCode() == null
                || voucher.getCode()
                        .trim()
                        .isEmpty()) {

            return "Mã Voucher không được để trống.";
        }

        // DUPLICATE
        boolean duplicate;

        if (isUpdate) {

            duplicate
                    = voucherDAO
                            .existsCodeExceptId(
                                    voucher.getCode(),
                                    voucher.getVoucherId()
                            );

        } else {

            duplicate
                    = voucherDAO
                            .existsCode(
                                    voucher.getCode()
                            );
        }

        if (duplicate) {

            return "Mã Voucher đã tồn tại.";
        }

        // TYPE
        if (!"AMOUNT".equalsIgnoreCase(
                voucher.getDiscountType()
        )
                && !"PERCENT".equalsIgnoreCase(
                        voucher.getDiscountType()
                )) {

            return "Loại giảm giá không hợp lệ.";
        }

        // VALUE
        if (voucher.getDiscountValue()
                <= 0) {

            return "Giá trị giảm phải lớn hơn 0.";
        }

        // PERCENT
        if ("PERCENT".equalsIgnoreCase(
                voucher.getDiscountType()
        )
                && voucher.getDiscountValue()
                > 100) {

            return "Phần trăm giảm không được vượt quá 100%.";
        }

        // MAX
        if ("PERCENT".equalsIgnoreCase(
                voucher.getDiscountType()
        )
                && voucher.getMaxDiscount()
                != null
                && voucher.getMaxDiscount()
                <= 0) {

            return "Giảm tối đa phải lớn hơn 0.";
        }

        // MIN ORDER
        if (voucher.getMinOrderValue()
                < 0) {

            return "Giá trị đơn tối thiểu không hợp lệ.";
        }

        // DATE
        if (voucher.getValidFrom()
                == null
                || voucher.getValidTo()
                == null) {

            return "Thời gian Voucher không hợp lệ.";
        }

        if (!voucher
                .getValidTo()
                .after(
                        voucher.getValidFrom()
                )) {

            return "Thời gian kết thúc phải sau thời gian bắt đầu.";
        }

        // USAGE
        if (voucher.getUsageLimit()
                != null
                && voucher.getUsageLimit()
                <= 0) {

            return "Tổng lượt sử dụng phải lớn hơn 0.";
        }

        // PER USER
        if (voucher.getPerUserLimit()
                != null
                && voucher.getPerUserLimit()
                <= 0) {

            return "Giới hạn mỗi User phải lớn hơn 0.";
        }

        if (voucher.getUsageLimit()
                != null
                && voucher.getPerUserLimit()
                != null
                && voucher.getPerUserLimit()
                > voucher.getUsageLimit()) {

            return "Giới hạn mỗi User không được lớn hơn tổng lượt sử dụng.";
        }

        return null;
    }

    // =====================================================
    // TIMESTAMP
    // =====================================================
    private Timestamp parseTimestamp(
            String value) {

        if (value == null
                || value.trim().isEmpty()) {

            return null;
        }

        LocalDateTime dateTime
                = LocalDateTime.parse(
                        value,
                        formatter
                );

        return Timestamp.valueOf(
                dateTime
        );
    }

    // =====================================================
    // NULLABLE DOUBLE
    // =====================================================
    private Double parseNullableDouble(
            String value) {

        if (value == null
                || value.trim().isEmpty()) {

            return null;
        }

        return Double.parseDouble(
                value.trim()
        );
    }

    // =====================================================
    // NULLABLE INT
    // =====================================================
    private Integer parseNullableInteger(
            String value) {

        if (value == null
                || value.trim().isEmpty()) {

            return null;
        }

        return Integer.parseInt(
                value.trim()
        );
    }

    // =====================================================
    // SUCCESS
    // =====================================================
    private void setSuccessMessage(
            HttpServletRequest request,
            String message) {

        request.getSession()
                .setAttribute(
                        "successMessage",
                        message
                );
    }

    // =====================================================
    // ERROR
    // =====================================================
    private void setErrorMessage(
            HttpServletRequest request,
            String message) {

        request.getSession()
                .setAttribute(
                        "errorMessage",
                        message
                );
    }

    // =====================================================
    // REDIRECT LIST
    // =====================================================
    private void redirectList(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        response.sendRedirect(
                request.getContextPath()
                + "/staff/voucher"
        );
    }

    // =====================================================
    // REDIRECT CREATE
    // =====================================================
    private void redirectCreate(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        response.sendRedirect(
                request.getContextPath()
                + "/staff/voucher?view=create"
        );
    }

    // =====================================================
    // REDIRECT EDIT
    // =====================================================
    private void redirectEdit(
            HttpServletRequest request,
            HttpServletResponse response,
            int voucherId)
            throws IOException {

        response.sendRedirect(
                request.getContextPath()
                + "/staff/voucher?view=edit&id="
                + voucherId
        );
    }
}
