<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%@include file="/WEB-INF/include/header.jsp" %>

<div class="container my-5">
    <div class="row justify-content-center">
        <div class="col-md-6 col-lg-5 col-xl-4">
            <div class="card shadow-sm border-0 rounded-3">
                <div class="card-body p-4">
                    <!-- TIÊU ĐỀ -->
                    <div class="text-center mb-4">
                        <h3 class="fw-bold text-primary">
                            <i class="bi bi-box-arrow-in-right me-2"></i>Đăng Nhập
                        </h3>
                        <p class="text-muted small">Chào mừng bạn quay trở lại!</p>
                    </div>

                    <!-- THÔNG BÁO LỖI ĐĂNG NHẬP -->
                    <c:if test="${not empty errorMessage}">
                        <div class="alert alert-danger alert-dismissible fade show" role="alert">
                            <i class="bi bi-exclamation-triangle-fill me-2"></i><c:out value="${errorMessage}"/>
                            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                        </div>
                    </c:if>

                    <!-- THÔNG BÁO ĐĂNG XUẤT THÀNH CÔNG -->
                    <c:if test="${not empty sessionScope.logoutMessage}">
                        <div class="alert alert-success alert-dismissible fade show" role="alert">
                            <i class="bi bi-check-circle-fill me-2"></i><c:out value="${sessionScope.logoutMessage}"/>
                            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                        </div>
                        <%-- Xóa thông báo khỏi session sau khi đã hiển thị --%>
                        <c:remove var="logoutMessage" scope="session"/>
                    </c:if>

                    <!-- FORM ĐĂNG NHẬP -->
                    <form action="${pageContext.request.contextPath}/login" method="post">
                        <div class="mb-3">
                            <label for="username" class="form-label fw-semibold">Tên đăng nhập / Email</label>
                            <div class="input-group">
                                <span class="input-group-text bg-light"><i class="bi bi-person"></i></span>
                                <input type="text" class="form-control" id="username" name="username" placeholder="Nhập tên đăng nhập" required autofocus>
                            </div>
                        </div>

                        <div class="mb-3">
                            <label for="password" class="form-label fw-semibold">Mật khẩu</label>
                            <div class="input-group">
                                <span class="input-group-text bg-light"><i class="bi bi-lock"></i></span>
                                <input type="password" class="form-control" id="password" name="password" placeholder="Nhập mật khẩu" required>
                                <button class="btn btn-outline-secondary" type="button" id="togglePassword">
                                    <i class="bi bi-eye" id="toggleIcon"></i>
                                </button>
                            </div>
                        </div>

                        <div class="d-flex justify-content-between align-items-center mb-3">
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" id="rememberMe" name="rememberMe" value="true">
                                <label class="form-check-label small" for="rememberMe">Ghi nhớ đăng nhập</label>
                            </div>
                            <a href="${pageContext.request.contextPath}/forgot-password" class="text-decoration-none small text-primary">Quên mật khẩu?</a>
                        </div>

                        <div class="d-grid mt-4">
                            <button type="submit" class="btn btn-primary fw-bold py-2">
                                <i class="bi bi-box-arrow-in-right me-1"></i> Đăng nhập
                            </button>
                        </div>
                    </form>

                    <hr class="my-4">

                    <!-- CHUYỂN HƯỚNG ĐĂNG KÝ -->
                    <div class="text-center small">
                        Chưa có tài khoản? 
                        <a href="${pageContext.request.contextPath}/register" class="fw-bold text-decoration-none text-primary">
                            Đăng ký ngay
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
    document.addEventListener('DOMContentLoaded', function () {
        const togglePassword = document.getElementById('togglePassword');
        const password = document.getElementById('password');
        const toggleIcon = document.getElementById('toggleIcon');

        if (togglePassword && password && toggleIcon) {
            togglePassword.addEventListener('click', function () {
                const type = password.getAttribute('type') === 'password' ? 'text' : 'password';
                password.setAttribute('type', type);
                
                toggleIcon.classList.toggle('bi-eye');
                toggleIcon.classList.toggle('bi-eye-slash');
            });
        }
    });
</script>

<%-- Nhúng Footer chung của dự án --%>
<%@include file="/WEB-INF/include/footer.jsp" %>