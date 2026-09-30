<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Hồ Sơ Cá Nhân & Đổi Mật Khẩu</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                margin: 0;
                padding: 0;
                background-color: #f4f6f9;
            }
            .profile-container {
                max-width: 800px;
                margin: 40px auto;
                background: #fff;
                padding: 30px;
                border-radius: 8px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            }
            .profile-title {
                text-align: center;
                margin-bottom: 25px;
                color: #333;
            }
            .section-box {
                border: 1px solid #e0e0e0;
                border-radius: 6px;
                padding: 20px;
                margin-bottom: 30px;
                background-color: #fff;
            }
            .section-title {
                font-size: 18px;
                font-weight: bold;
                margin-bottom: 15px;
                color: #007bff;
                border-bottom: 2px solid #007bff;
                padding-bottom: 5px;
                display: inline-block;
            }
            .form-group {
                margin-bottom: 15px;
            }
            .form-group label {
                display: block;
                margin-bottom: 5px;
                font-weight: bold;
                color: #555;
            }
            .form-group input {
                width: 100%;
                padding: 10px;
                box-sizing: border-box;
                border: 1px solid #ccc;
                border-radius: 4px;
                font-size: 14px;
            }
            .form-group input[disabled] {
                background-color: #e9ecef;
                cursor: not-allowed;
            }
            .btn-submit {
                padding: 10px 20px;
                background-color: #007bff;
                color: white;
                border: none;
                border-radius: 4px;
                cursor: pointer;
                font-weight: bold;
                font-size: 14px;
            }
            .btn-submit:hover {
                background-color: #0056b3;
            }
            .btn-danger {
                background-color: #dc3545;
            }
            .btn-danger:hover {
                background-color: #bd2130;
            }
            .alert-success {
                color: #155724;
                background-color: #d4edda;
                border: 1px solid #c3e6cb;
                padding: 10px 15px;
                border-radius: 4px;
                margin-bottom: 15px;
            }
            .alert-danger {
                color: #721c24;
                background-color: #f8d7da;
                border: 1px solid #f5c6cb;
                padding: 10px 15px;
                border-radius: 4px;
                margin-bottom: 15px;
            }
        </style>
    </head>
    <body>

        <!-- NHÚNG HEADER TẠI ĐÂY -->
        <%@include file="/WEB-INF/include/header.jsp" %>

        <div class="profile-container">
            <h2 class="profile-title">Quản Lý Tài Khoản</h2>

            <!-- KHU VỰC 1: CẬP NHẬT THÔNG TIN CÁ NHÂN -->
            <div class="section-box">
                <div class="section-title">Thông Tin Cá Nhân</div>

                <c:if test="${not empty profileSuccess}">
                    <div class="alert-success">${profileSuccess}</div>
                </c:if>
                <c:if test="${not empty profileError}">
                    <div class="alert-danger">${profileError}</div>
                </c:if>

                <form action="${pageContext.request.contextPath}/profile" method="post">
                    <input type="hidden" name="action" value="updateProfile">

                    <div class="form-group">
                        <label for="username">Tên đăng nhập:</label>
                        <input type="text" id="username" value="${sessionScope.loggedInUser.username}" disabled readonly>
                    </div>

                    <div class="form-group">
                        <label for="email">Email:</label>
                        <input type="email" id="email" name="email" value="${sessionScope.loggedInUser.email}" required>
                    </div>

                    <div class="form-group">
                        <label for="phone">Số điện thoại:</label>
                        <input type="text" id="phone" name="phone" value="${sessionScope.loggedInUser.phone}">
                    </div>

                    <button type="submit" class="btn-submit">Cập nhật thông tin</button>
                </form>
            </div>

            <!-- KHU VỰC 2: ĐỔI MẬT KHẨU -->
            <div class="section-box">
                <div class="section-title" style="color: #dc3545; border-bottom-color: #dc3545;">Đổi Mật Khẩu</div>

                <c:if test="${not empty pwdSuccess}">
                    <div class="alert-success">${pwdSuccess}</div>
                </c:if>
                <c:if test="${not empty pwdError}">
                    <div class="alert-danger">${pwdError}</div>
                </c:if>

                <form action="${pageContext.request.contextPath}/profile" method="post">
                    <input type="hidden" name="action" value="changePassword">

                    <div class="form-group">
                        <label for="oldPassword">Mật khẩu hiện tại:</label>
                        <input type="password" id="oldPassword" name="oldPassword" required>
                    </div>

                    <div class="form-group">
                        <label for="newPassword">Mật khẩu mới:</label>
                        <input type="password" id="newPassword" name="newPassword" required>
                    </div>

                    <div class="form-group">
                        <label for="confirmPassword">Xác nhận mật khẩu mới:</label>
                        <input type="password" id="confirmPassword" name="confirmPassword" required>
                    </div>

                    <button type="submit" class="btn-submit btn-danger">Đổi mật khẩu</button>
                </form>
            </div>
        </div>

        <!-- NHÚNG FOOTER TẠI ĐÂY -->
        <%@include file="/WEB-INF/include/footer.jsp" %>

    </body>
</html>