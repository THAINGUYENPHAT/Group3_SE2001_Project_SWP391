<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Đăng Ký Tài Khoản - OECS</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 0; }
            .register-container {
                width: 350px;
                margin: 40px auto;
                padding: 20px;
                border: 1px solid #ccc;
                border-radius: 8px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            }
            .form-group { margin-bottom: 15px; }
            .form-group label { display: block; margin-bottom: 5px; font-weight: bold; }
            .form-group input { width: 100%; padding: 8px; box-sizing: border-box; border: 1px solid #ccc; border-radius: 4px; }
            .btn-register {
                width: 100%; padding: 10px; background-color: #28a745;
                color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 16px;
            }
            .btn-register:hover { background-color: #218838; }
            .login-link { margin-top: 15px; text-align: center; font-size: 14px; }
        </style>
    </head>
    <body>

        <%-- Nhúng Header chung của dự án --%>
        <%@include file="/WEB-INF/include/header.jsp" %>

        <div class="register-container">
            <h2 style="text-align: center; margin-top: 0;">Đăng Ký Tài Khoản</h2>

            <%-- Thẻ hiển thị thông báo lỗi --%>
            <c:if test="${not empty errorMessage}">
                <div style="color: #721c24; background-color: #f8d7da; border: 1px solid #f5c6cb; border-radius: 6px; padding: 10px 14px; font-size: 14px; margin-bottom: 15px; text-align: left;">
                    ${errorMessage}
                </div>
            </c:if>

            <form action="${pageContext.request.contextPath}/register" method="post">
                <div class="form-group">
                    <label for="username">Tên đăng nhập (*):</label>
                    <input type="text" id="username" name="username" value="${username}" required placeholder="Ví dụ: phat_user">
                </div>

                <div class="form-group">
                    <label for="email">Email (*):</label>
                    <input type="email" id="email" name="email" value="${email}" required placeholder="example@gmail.com">
                </div>

                <div class="form-group">
                    <label for="phone">Số điện thoại:</label>
                    <input type="text" id="phone" name="phone" value="${phone}" placeholder="090xxxxxxx">
                </div>

                <div class="form-group">
                    <label for="password">Mật khẩu (*):</label>
                    <input type="password" id="password" name="password" required>
                </div>

                <div class="form-group">
                    <label for="confirmPassword">Xác nhận mật khẩu (*):</label>
                    <input type="password" id="confirmPassword" name="confirmPassword" required>
                </div>

                <button type="submit" class="btn-register">Đăng Ký</button>
            </form>

            <div class="login-link">
                Đã có tài khoản? <a href="${pageContext.request.contextPath}/login">Đăng nhập ngay</a>
            </div>
        </div>

        <%-- Nhúng Footer chung của dự án --%>
        <%@include file="/WEB-INF/include/footer.jsp" %>

    </body>
</html>