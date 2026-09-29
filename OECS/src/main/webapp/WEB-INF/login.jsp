<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Trang Đăng Nhập</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                margin: 0;
                padding: 0;
            }
            .login-container {
                width: 300px;
                margin: 50px auto;
                padding: 20px;
                border: 1px solid #ccc;
                border-radius: 8px;
            }
            .form-group {
                margin-bottom: 15px;
            }
            .form-group label {
                display: block;
                margin-bottom: 5px;
            }
            .form-group input {
                width: 100%;
                padding: 8px;
                box-sizing: border-box;
            }
            .btn-login {
                width: 100%;
                padding: 10px;
                background-color: #007bff;
                color: white;
                border: none;
                border-radius: 4px;
                cursor: pointer;
            }
        </style>
    </head>
    <body>

        <!-- NHÚNG HEADER TẠI ĐÂY -->
        <%@include file="/WEB-INF/include/header.jsp" %>

        <div class="login-container">
            <h2>Đăng Nhập</h2>

            <c:if test="${not empty errorMessage}">
                <div class="alert-danger" style="color: #721c24; background-color: #f8d7da;">
                    ${errorMessage}
                </div>
            </c:if>

            <%-- Thẻ kiểm tra thông báo đăng xuất thành công --%>
            <c:if test="${not empty sessionScope.logoutMessage}">
                <div style="color: #155724; background-color: #d4edda;">
                    ${sessionScope.logoutMessage}
                </div>
                <%-- Xóa thông báo khỏi session để không bị lặp lại khi người dùng bấm F5 --%>
                <c:remove var="logoutMessage" scope="session"/>
            </c:if>

            <form action="${pageContext.request.contextPath}/login" method="post">
                <div class="form-group">
                    <label for="username">Tên đăng nhập:</label>
                    <input type="text" id="username" name="username" required>
                </div>
                <div class="form-group">
                    <label for="password">Mật khẩu:</label>
                    <input type="password" id="password" name="password" required>
                </div>
                <button type="submit" class="btn-login">Đăng nhập</button>
            </form>
            <div class="auth-links">
                Chưa có tài khoản? <a href="${pageContext.request.contextPath}/register">Đăng ký ngay</a>
            </div>
        </div>

        <!-- NHÚNG FOOTER TẠI ĐÂY -->
        <%@include file="/WEB-INF/include/footer.jsp" %>

    </body>
</html>