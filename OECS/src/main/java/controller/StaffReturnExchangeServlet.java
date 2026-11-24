
package controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import model.User;
import service.ReturnExchangeService;

@WebServlet(
        name = "StaffReturnExchangeServlet",
        urlPatterns = {"/staff/return-exchange"}
)
public class StaffReturnExchangeServlet extends HttpServlet {

    private static final Logger LOGGER =
            Logger.getLogger(
                    StaffReturnExchangeServlet.class.getName());

    private final ReturnExchangeService returnExchangeService =
            new ReturnExchangeService();

    // =====================================================
    // 1. KIEM TRA QUYEN STAFF
    // =====================================================

    private User getLoggedInStaff(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        HttpSession session = request.getSession(false);

        if (session == null) {
            response.sendRedirect(
                    request.getContextPath() + "/login");
            return null;
        }

        Object loggedInUser =
                session.getAttribute("loggedInUser");

        if (!(loggedInUser instanceof User)) {
            response.sendRedirect(
                    request.getContextPath() + "/login");
            return null;
        }

        User staff = (User) loggedInUser;

        if (!staff.isStaff()) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "Bạn không có quyền quản lý trả hàng.");
            return null;
        }

        return staff;
    }

    // =====================================================
    // 2. HIEN THI DANH SACH / CHI TIET RETURN
    // =====================================================

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setHeader("Cache-Control", "no-store");

        User staff = getLoggedInStaff(request, response);

        if (staff == null) {
            return;
        }

        String contextPath = request.getContextPath();
        String view = request.getParameter("view");

        try {

            // Xem chi tiet mot yeu cau tra hang.
            if ("detail".equals(view)) {

                int requestId = parseRequestId(
                        request.getParameter("id"));

                List<Map<String, Object>> requests =
                        returnExchangeService.getAllRequests();

                Map<String, Object> selectedRequest = null;

                for (Map<String, Object> item : requests) {

                    Object id = item.get("requestId");

                    if (id instanceof Number
                            && ((Number) id).intValue() == requestId) {

                        selectedRequest = item;
                        break;
                    }
                }

                if (selectedRequest == null) {

                    response.sendRedirect(
                            contextPath
                            + "/staff/return-exchange?error=notFound");

                    return;
                }

                request.setAttribute(
                        "selectedRequest",
                        selectedRequest
                );

                request.setAttribute(
                        "requestItems",
                        returnExchangeService.getRequestItems(requestId)
                );

                request.getRequestDispatcher(
                        "/WEB-INF/staff/return-exchange/detail.jsp"
                ).forward(request, response);

                return;
            }

            // Xem danh sach tat ca yeu cau tra hang.
            request.setAttribute(
                    "requestList",
                    returnExchangeService.getAllRequests()
            );

            request.getRequestDispatcher(
                    "/WEB-INF/staff/return-exchange/list.jsp"
            ).forward(request, response);

        } catch (NumberFormatException ex) {

            response.sendRedirect(
                    contextPath
                    + "/staff/return-exchange?error=invalidId"
            );

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Cannot load return requests",
                    ex
            );

            throw new ServletException(
                    "Không thể tải danh sách yêu cầu trả hàng.",
                    ex
            );
        }
    }

    // =====================================================
    // 3. STAFF DUYET / TU CHOI RETURN
    // =====================================================

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-store");

        User staff = getLoggedInStaff(request, response);

        if (staff == null) {
            return;
        }

        String contextPath = request.getContextPath();
        String action = request.getParameter("action");

        int requestId;

        try {

            requestId = parseRequestId(
                    request.getParameter("id"));

        } catch (NumberFormatException ex) {

            response.sendRedirect(
                    contextPath
                    + "/staff/return-exchange?error=invalidId"
            );

            return;
        }

        // Chi cho phep duyet hoac tu choi Return.
        String newStatus;

        if ("approve".equals(action)) {

            newStatus = "APPROVED";

        } else if ("reject".equals(action)) {

            newStatus = "REJECTED";

        } else {

            response.sendRedirect(
                    contextPath
                    + "/staff/return-exchange?error=invalidAction"
            );

            return;
        }

        String staffNote =
                request.getParameter("staffNote");

        staffNote = staffNote == null
                ? ""
                : staffNote.trim();

        // Gioi han do dai phu hop voi DB.
        if (staffNote.length() > 1000) {

            response.sendRedirect(
                    detailUrl(contextPath, requestId)
                    + "&error=invalid"
            );

            return;
        }

        // Tu choi bat buoc co ly do.
        if ("REJECTED".equals(newStatus)
                && staffNote.isEmpty()) {

            response.sendRedirect(
                    detailUrl(contextPath, requestId)
                    + "&error=noteRequired"
            );

            return;
        }

        try {

            boolean updated =
                    returnExchangeService.reviewRequest(
                            requestId,
                            staff.getUserId(),
                            newStatus,
                            staffNote
                    );

            if (!updated) {

                response.sendRedirect(
                        detailUrl(contextPath, requestId)
                        + "&error=alreadyReviewed"
                );

                return;
            }

            // Giu ma thong bao cu de tuong thich JSP.
            String message =
                    "APPROVED".equals(newStatus)
                    ? "approved"
                    : "rejected";

            response.sendRedirect(
                    detailUrl(contextPath, requestId)
                    + "&message="
                    + URLEncoder.encode(
                            message,
                            StandardCharsets.UTF_8
                    )
            );

        } catch (IllegalArgumentException ex) {

            LOGGER.log(
                    Level.WARNING,
                    "Invalid return review request",
                    ex
            );

            response.sendRedirect(
                    detailUrl(contextPath, requestId)
                    + "&error=invalid"
            );

        } catch (SQLException ex) {

            LOGGER.log(
                    Level.SEVERE,
                    "Cannot review return request",
                    ex
            );

            response.sendRedirect(
                    detailUrl(contextPath, requestId)
                    + "&error=system"
            );
        }
    }

    // =====================================================
    // 4. KIEM TRA MA YEU CAU
    // =====================================================

    private int parseRequestId(String value) {

        if (value == null || value.trim().isEmpty()) {
            throw new NumberFormatException(
                    "Thiếu mã yêu cầu trả hàng.");
        }

        int requestId = Integer.parseInt(value.trim());

        if (requestId <= 0) {
            throw new NumberFormatException(
                    "Mã yêu cầu phải lớn hơn 0.");
        }

        return requestId;
    }

    // =====================================================
    // 5. TAO DUONG DAN CHI TIET RETURN
    // =====================================================

    private String detailUrl(
            String contextPath,
            int requestId) {

        return contextPath
                + "/staff/return-exchange?view=detail&id="
                + requestId;
    }
}
