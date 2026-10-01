<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<%-- Nhúng Header chung của dự án (đã bao gồm <head>, CSS Bootstrap và mở <body>) --%>
<%@include file="/WEB-INF/include/header.jsp" %>

<div class="container my-5">
    <div class="row justify-content-center">
        <div class="col-md-6 col-lg-5">
            <div class="card shadow-sm border-0 rounded-3">
                <div class="card-body p-4">
                    <h3 class="card-title text-center fw-bold text-primary mb-4">Đăng Ký Tài Khoản</h3>

                    <%-- Thẻ hiển thị thông báo lỗi từ Servlet --%>
                    <c:if test="${not empty errorMessage}">
                        <div class="alert alert-danger alert-dismissible fade show" role="alert">
                            <i class="bi bi-exclamation-triangle-fill me-2"></i>
                            <c:out value="${errorMessage}"/>
                            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                        </div>
                    </c:if>

                    <form action="${pageContext.request.contextPath}/register" method="post" id="registerForm">
                        <div class="mb-3">
                            <label for="username" class="form-label fw-bold">Tên đăng nhập <span class="text-danger">*</span></label>
                            <input type="text" 
                                   class="form-control" 
                                   id="username" 
                                   name="username" 
                                   value="<c:out value='${param.username}'/>" 
                                   required 
                                   pattern="^[a-zA-Z0-9_]{4,20}$"
                                   title="Tên đăng nhập từ 4-20 ký tự, không chứa ký tự đặc biệt"
                                   placeholder="Ví dụ: phat_user">
                        </div>

                        <div class="mb-3">
                            <label for="email" class="form-label fw-bold">Email <span class="text-danger">*</span></label>
                            <input type="email" 
                                   class="form-control" 
                                   id="email" 
                                   name="email" 
                                   value="<c:out value='${param.email}'/>" 
                                   required 
                                   placeholder="example@gmail.com">
                        </div>

                        <div class="mb-3">
                            <label for="phone" class="form-label fw-bold">Số điện thoại</label>
                            <input type="tel" 
                                   class="form-control" 
                                   id="phone" 
                                   name="phone" 
                                   value="<c:out value='${param.phone}'/>" 
                                   pattern="(0[3|5|7|8|9])+([0-9]{8})\b"
                                   title="Vui lòng nhập đúng định dạng số điện thoại Việt Nam (10 chữ số)"
                                   placeholder="090xxxxxxx">
                        </div>

                        <div class="mb-3">
                            <label for="password" class="form-label fw-bold">Mật khẩu <span class="text-danger">*</span></label>
                            <input type="password" class="form-control" id="password" name="password" minlength="6" required placeholder="Tối thiểu 6 ký tự">
                        </div>

                        <div class="mb-3">
                            <label for="confirmPassword" class="form-label fw-bold">Xác nhận mật khẩu <span class="text-danger">*</span></label>
                            <input type="password" class="form-control" id="confirmPassword" name="confirmPassword" required placeholder="Nhập lại mật khẩu">
                            <div id="passwordError" class="text-danger small mt-1 d-none">
                                Mật khẩu xác nhận không trùng khớp!
                            </div>
                        </div>

                        <div class="d-grid gap-2 mt-4">
                            <button type="submit" class="btn btn-success btn-lg fs-6 fw-bold">
                                <i class="bi bi-person-plus-fill me-1"></i> Đăng Ký
                            </button>
                        </div>
                    </form>

                    <div class="text-center mt-4 pt-2 border-top">
                        <span class="text-muted">Đã có tài khoản?</span> 
                        <a href="${pageContext.request.contextPath}/login" class="text-decoration-none fw-bold">Đăng nhập ngay</a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
    document.addEventListener('DOMContentLoaded', function () {
        const form = document.getElementById('registerForm');
        const password = document.getElementById('password');
        const confirmPassword = document.getElementById('confirmPassword');
        const passwordError = document.getElementById('passwordError');

        function validatePasswordMatch() {
            if (confirmPassword.value && password.value !== confirmPassword.value) {
                passwordError.classList.remove('d-none');
                confirmPassword.setCustomValidity("Mật khẩu không khớp");
            } else {
                passwordError.classList.add('d-none');
                confirmPassword.setCustomValidity("");
            }
        }

        password.addEventListener('change', validatePasswordMatch);
        confirmPassword.addEventListener('keyup', validatePasswordMatch);

        form.addEventListener('submit', function (e) {
            validatePasswordMatch();
            if (!form.checkValidity()) {
                e.preventDefault();
                e.stopPropagation();
            }
        });
    });
</script>

<%-- Nhúng Footer chung của dự án (đã bao gồm JS Bootstrap và đóng </body></html>) --%>
<%@include file="/WEB-INF/include/footer.jsp" %>