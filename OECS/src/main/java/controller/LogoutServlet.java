package controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(name = "LogoutServlet", urlPatterns = {"/logout"})
public class LogoutServlet extends HttpServlet {

    private static final Logger LOGGER = Logger.getLogger(LogoutServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processLogout(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processLogout(request, response);
    }

  
    private void processLogout(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        try {
            
            HttpSession session = request.getSession(false);
            if (session != null) {
                session.invalidate();
            }

           
            HttpSession newSession = request.getSession(true);
            newSession.setAttribute("logoutMessage", "Bạn đã đăng xuất thành công!");

        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi khi xử lý đăng xuất người dùng!", e);
        } finally {
          
            response.sendRedirect(request.getContextPath() + "/login");
        }
    }
}