package controller;

import dao.VoucherDAO;
import java.io.IOException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import model.Voucher;

@WebServlet(name = "VoucherServlet",
        urlPatterns = {"/admin/voucher"})
public class VoucherServlet extends HttpServlet {

    private VoucherDAO voucherDAO;

    @Override
    public void init() throws ServletException {
        voucherDAO = new VoucherDAO();
    }

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        String action
                = request.getParameter("action");

        if (action == null) {
            action = "list";
        }

        switch (action) {

            case "delete":
                deleteVoucher(
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

            default:
                showList(
                        request,
                        response
                );
                break;
        }
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String action
                = request.getParameter("action");

        if ("create".equals(action)) {

            createVoucher(
                    request,
                    response
            );

        } else if ("update".equals(action)) {

            updateVoucher(
                    request,
                    response
            );

        } else {

            response.sendRedirect(
                    request.getContextPath()
                    + "/admin/voucher"
            );
        }
    }

    // =========================================
    // LIST
    // =========================================
    private void showList(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        List<Voucher> list
                = voucherDAO.getAllVouchers();

        request.setAttribute(
                "vouchers",
                list
        );

        request.getRequestDispatcher(
                "/WEB-INF/admin/voucher.jsp"
        ).forward(
                request,
                response
        );
    }

    // =========================================
    // CREATE
    // =========================================
    private void createVoucher(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        try {

            String code
                    = request.getParameter("code")
                            .trim()
                            .toUpperCase();

            double discountAmount
                    = Double.parseDouble(
                            request.getParameter(
                                    "discountAmount"
                            )
                    );

            double minOrderValue
                    = Double.parseDouble(
                            request.getParameter(
                                    "minOrderValue"
                            )
                    );

            Timestamp validFrom
                    = convertToTimestamp(
                            request.getParameter(
                                    "validFrom"
                            )
                    );

            Timestamp validTo
                    = convertToTimestamp(
                            request.getParameter(
                                    "validTo"
                            )
                    );

            if (voucherDAO.existsCode(code)) {

                request.getSession()
                        .setAttribute(
                                "errorMessage",
                                "Mã Voucher đã tồn tại."
                        );

                response.sendRedirect(
                        request.getContextPath()
                        + "/admin/voucher"
                );

                return;
            }

            if (discountAmount <= 0) {

                request.getSession()
                        .setAttribute(
                                "errorMessage",
                                "Giá trị giảm phải lớn hơn 0."
                        );

                response.sendRedirect(
                        request.getContextPath()
                        + "/admin/voucher"
                );

                return;
            }

            if (validTo.before(validFrom)) {

                request.getSession()
                        .setAttribute(
                                "errorMessage",
                                "Ngày kết thúc phải sau ngày bắt đầu."
                        );

                response.sendRedirect(
                        request.getContextPath()
                        + "/admin/voucher"
                );

                return;
            }

            Voucher voucher = new Voucher();

            voucher.setCode(code);

            voucher.setDiscountAmount(
                    discountAmount
            );

            voucher.setMinOrderValue(
                    minOrderValue
            );

            voucher.setValidFrom(
                    validFrom
            );

            voucher.setValidTo(
                    validTo
            );

            boolean success
                    = voucherDAO.insertVoucher(
                            voucher
                    );

            if (success) {

                request.getSession()
                        .setAttribute(
                                "successMessage",
                                "Tạo Voucher thành công."
                        );

            } else {

                request.getSession()
                        .setAttribute(
                                "errorMessage",
                                "Không thể tạo Voucher."
                        );
            }

        } catch (Exception e) {

            e.printStackTrace();

            request.getSession()
                    .setAttribute(
                            "errorMessage",
                            "Dữ liệu Voucher không hợp lệ."
                    );
        }

        response.sendRedirect(
                request.getContextPath()
                + "/admin/voucher"
        );
    }

    // =========================================
    // SHOW EDIT
    // =========================================
    private void showEdit(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        try {

            int voucherId
                    = Integer.parseInt(
                            request.getParameter("id")
                    );

            Voucher voucher
                    = voucherDAO.getVoucherById(
                            voucherId
                    );

            request.setAttribute(
                    "editVoucher",
                    voucher
            );

            showList(
                    request,
                    response
            );

        } catch (NumberFormatException e) {

            response.sendRedirect(
                    request.getContextPath()
                    + "/admin/voucher"
            );
        }
    }

    // =========================================
    // UPDATE
    // =========================================
    private void updateVoucher(
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

            String code
                    = request.getParameter("code")
                            .trim()
                            .toUpperCase();

            double discountAmount
                    = Double.parseDouble(
                            request.getParameter(
                                    "discountAmount"
                            )
                    );

            double minOrderValue
                    = Double.parseDouble(
                            request.getParameter(
                                    "minOrderValue"
                            )
                    );

            Timestamp validFrom
                    = convertToTimestamp(
                            request.getParameter(
                                    "validFrom"
                            )
                    );

            Timestamp validTo
                    = convertToTimestamp(
                            request.getParameter(
                                    "validTo"
                            )
                    );

            Voucher voucher
                    = new Voucher();

            voucher.setVoucherId(
                    voucherId
            );

            voucher.setCode(code);

            voucher.setDiscountAmount(
                    discountAmount
            );

            voucher.setMinOrderValue(
                    minOrderValue
            );

            voucher.setValidFrom(
                    validFrom
            );

            voucher.setValidTo(
                    validTo
            );

            boolean success
                    = voucherDAO.updateVoucher(
                            voucher
                    );

            if (success) {

                request.getSession()
                        .setAttribute(
                                "successMessage",
                                "Cập nhật Voucher thành công."
                        );

            } else {

                request.getSession()
                        .setAttribute(
                                "errorMessage",
                                "Không thể cập nhật Voucher."
                        );
            }

        } catch (Exception e) {

            e.printStackTrace();

            request.getSession()
                    .setAttribute(
                            "errorMessage",
                            "Dữ liệu không hợp lệ."
                    );
        }

        response.sendRedirect(
                request.getContextPath()
                + "/admin/voucher"
        );
    }

    // =========================================
    // DELETE
    // =========================================
    private void deleteVoucher(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        try {

            int voucherId
                    = Integer.parseInt(
                            request.getParameter("id")
                    );

            boolean success
                    = voucherDAO.deleteVoucher(
                            voucherId
                    );

            if (success) {

                request.getSession()
                        .setAttribute(
                                "successMessage",
                                "Đã xóa Voucher."
                        );

            } else {

                request.getSession()
                        .setAttribute(
                                "errorMessage",
                                "Không thể xóa Voucher."
                        );
            }

        } catch (NumberFormatException e) {

            request.getSession()
                    .setAttribute(
                            "errorMessage",
                            "Voucher không hợp lệ."
                    );
        }

        response.sendRedirect(
                request.getContextPath()
                + "/admin/voucher"
        );
    }

    // =========================================
    // Convert datetime-local -> Timestamp
    // =========================================
    private Timestamp convertToTimestamp(
            String value) {

        LocalDateTime dateTime
                = LocalDateTime.parse(
                        value,
                        DateTimeFormatter.ofPattern(
                                "yyyy-MM-dd'T'HH:mm"
                        )
                );

        return Timestamp.valueOf(
                dateTime
        );
    }
}
