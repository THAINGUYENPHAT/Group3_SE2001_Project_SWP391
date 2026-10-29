
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
            Logger.getLogger(StaffReturnExchangeServlet.class.getName());

    private final ReturnExchangeService returnExchangeService =
            new ReturnExchangeService();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        String contextPath = request.getContextPath();
        String view = request.getParameter("view");

        try {
            if ("detail".equals(view)) {
                int requestId = parseRequestId(
                        request.getParameter("id"));

                List<Map<String, Object>> requests =
                        returnExchangeService.getAllRequests();

                Map<String, Object> selectedRequest = null;

                for (Map<String, Object> item : requests) {
                    if (((Number) item.get("requestId")).intValue()
                            == requestId) {
                        selectedRequest = item;
                        break;
                    }
                }

                if (selectedRequest == null) {
                    response.sendRedirect(contextPath
                            + "/staff/return-exchange?error=notFound");
                    return;
                }

                request.setAttribute("selectedRequest", selectedRequest);
                request.setAttribute(
                        "requestItems",
                        returnExchangeService.getRequestItems(requestId));

                request.getRequestDispatcher(
                        "/WEB-INF/staff/return-exchange/detail.jsp")
                        .forward(request, response);
                return;
            }

            request.setAttribute(
                    "requestList",
                    returnExchangeService.getAllRequests());

            request.getRequestDispatcher(
                    "/WEB-INF/staff/return-exchange/list.jsp")
                    .forward(request, response);

        } catch (NumberFormatException ex) {
            response.sendRedirect(contextPath
                    + "/staff/return-exchange?error=invalidId");
        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE,
                    "Cannot load return/exchange requests", ex);
            throw new ServletException(
                    "Không thể tải danh sách yêu cầu đổi/trả hàng.", ex);
        }
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String contextPath = request.getContextPath();
        String action = request.getParameter("action");

        HttpSession session = request.getSession(false);
        User staff = session == null
                ? null
                : (User) session.getAttribute("loggedInUser");

        // AuthFilter cũng kiểm tra quyền Staff.
        if (staff == null || !staff.isStaff()) {
            response.sendRedirect(contextPath + "/login");
            return;
        }

        int requestId;

        try {
            requestId = parseRequestId(request.getParameter("id"));
        } catch (NumberFormatException ex) {
            response.sendRedirect(contextPath
                    + "/staff/return-exchange?error=invalidId");
            return;
        }

        String newStatus;

        if ("approve".equals(action)) {
            newStatus = "APPROVED";
        } else if ("reject".equals(action)) {
            newStatus = "REJECTED";
        } else {
            response.sendRedirect(contextPath
                    + "/staff/return-exchange?error=invalidAction");
            return;
        }

        String staffNote = request.getParameter("staffNote");
        staffNote = staffNote == null ? "" : staffNote.trim();

        if ("REJECTED".equals(newStatus) && staffNote.isEmpty()) {
            response.sendRedirect(contextPath
                    + "/staff/return-exchange?view=detail&id="
                    + requestId + "&error=noteRequired");
            return;
        }

        try {
            boolean updated = returnExchangeService.reviewRequest(
                    requestId,
                    staff.getUserId(),
                    newStatus,
                    staffNote);

            if (!updated) {
                response.sendRedirect(contextPath
                        + "/staff/return-exchange?view=detail&id="
                        + requestId + "&error=alreadyReviewed");
                return;
            }

            String message = "APPROVED".equals(newStatus)
                    ? "Đã chấp nhận yêu cầu."
                    : "Đã từ chối yêu cầu.";

            response.sendRedirect(contextPath
                    + "/staff/return-exchange?view=detail&id="
                    + requestId + "&message="
                    + URLEncoder.encode(
                            message, StandardCharsets.UTF_8));

        } catch (IllegalArgumentException ex) {
            response.sendRedirect(contextPath
                    + "/staff/return-exchange?view=detail&id="
                    + requestId + "&error=invalid");
        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE,
                    "Cannot review return/exchange request", ex);
            throw new ServletException(
                    "Không thể xử lý yêu cầu đổi/trả hàng.", ex);
        }
    }

    private int parseRequestId(String value) {
        int requestId = Integer.parseInt(value);

        if (requestId <= 0) {
            throw new NumberFormatException();
        }

        return requestId;
    }
}
