<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%-- Nhúng Header chung của dự án --%>
<%@include file="/WEB-INF/include/header.jsp" %>

<div class="container my-5">
    <h2 class="text-center fw-bold text-primary mb-4">
        <i class="bi bi-person-badge me-2"></i>Quản Lý Tài Khoản
    </h2>

    <div class="row g-4">
        <!-- KHU VỰC 1: CẬP NHẬT THÔNG TIN CÁ NHÂN -->
        <div class="col-lg-6">
            <div class="card shadow-sm border-0 h-100">
                <div class="card-header bg-primary text-white fw-bold py-3">
                    <i class="bi bi-person-lines-fill me-2"></i>Thông Tin Cá Nhân
                </div>
                <div class="card-body p-4">
                    <c:if test="${not empty profileSuccess}">
                        <div class="alert alert-success alert-dismissible fade show" role="alert">
                            <i class="bi bi-check-circle-fill me-2"></i><c:out value="${profileSuccess}"/>
                            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                        </div>
                    </c:if>
                    <c:if test="${not empty profileError}">
                        <div class="alert alert-danger alert-dismissible fade show" role="alert">
                            <i class="bi bi-exclamation-triangle-fill me-2"></i><c:out value="${profileError}"/>
                            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                        </div>
                    </c:if>

                    <form action="${pageContext.request.contextPath}/profile" method="post">
                        <input type="hidden" name="action" value="updateProfile">

                        <div class="mb-3">
                            <label for="username" class="form-label fw-bold">Tên đăng nhập</label>
                            <input type="text" class="form-control bg-light" id="username" value="<c:out value='${sessionScope.loggedInUser.username}'/>" disabled readonly>
                        </div>

                        <div class="mb-3">
                            <label for="email" class="form-label fw-bold">Email <span class="text-danger">*</span></label>
                            <input type="email" class="form-control" id="email" name="email" value="<c:out value='${sessionScope.loggedInUser.email}'/>" required>
                        </div>

                        <div class="mb-3">
                            <label for="phone" class="form-label fw-bold">Số điện thoại</label>
                            <input type="tel" class="form-control" id="phone" name="phone" value="<c:out value='${sessionScope.loggedInUser.phone}'/>" pattern="(0[3|5|7|8|9])+([0-9]{8})\b" title="Số điện thoại Việt Nam gồm 10 chữ số">
                        </div>

                        <div class="form-group mb-3">
                            <label for="address">Địa chỉ giao hàng mặc định:</label>
                            <textarea id="address" name="address" class="form-control" rows="3" placeholder="Nhập địa chỉ nhận hàng của bạn...">${sessionScope.loggedInUser.address}</textarea>
                        </div>

                        <div class="d-grid mt-4">
                            <button type="submit" class="btn btn-primary fw-bold">
                                <i class="bi bi-save me-1"></i> Cập nhật thông tin
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <!-- KHU VỰC 2: ĐỔI MẬT KHẨU -->
        <div class="col-lg-6">
            <div class="card shadow-sm border-0 h-100">
                <div class="card-header bg-danger text-white fw-bold py-3">
                    <i class="bi bi-shield-lock-fill me-2"></i>Đổi Mật Khẩu
                </div>
                <div class="card-body p-4">
                    <c:if test="${not empty pwdSuccess}">
                        <div class="alert alert-success alert-dismissible fade show" role="alert">
                            <i class="bi bi-check-circle-fill me-2"></i><c:out value="${pwdSuccess}"/>
                            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                        </div>
                    </c:if>
                    <c:if test="${not empty pwdError}">
                        <div class="alert alert-danger alert-dismissible fade show" role="alert">
                            <i class="bi bi-exclamation-triangle-fill me-2"></i><c:out value="${pwdError}"/>
                            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                        </div>
                    </c:if>

                    <form action="${pageContext.request.contextPath}/profile" method="post" id="changePasswordForm">
                        <input type="hidden" name="action" value="changePassword">

                        <div class="mb-3">
                            <label for="oldPassword" class="form-label fw-bold">Mật khẩu hiện tại <span class="text-danger">*</span></label>
                            <input type="password" class="form-control" id="oldPassword" name="oldPassword" required>
                        </div>

                        <div class="mb-3">
                            <label for="newPassword" class="form-label fw-bold">Mật khẩu mới <span class="text-danger">*</span></label>
                            <input type="password" class="form-control" id="newPassword" name="newPassword" minlength="6" required placeholder="Tối thiểu 6 ký tự">
                        </div>

                        <div class="mb-3">
                            <label for="confirmPassword" class="form-label fw-bold">Xác nhận mật khẩu mới <span class="text-danger">*</span></label>
                            <input type="password" class="form-control" id="confirmPassword" name="confirmPassword" required>
                            <div id="pwdMismatchError" class="text-danger small mt-1 d-none">
                                Mật khẩu mới không trùng khớp!
                            </div>
                        </div>

                        <div class="d-grid mt-4">
                            <button type="submit" class="btn btn-danger fw-bold">
                                <i class="bi bi-key-fill me-1"></i> Đổi mật khẩu
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
    document.addEventListener('DOMContentLoaded', function () {
        const pwdForm = document.getElementById('changePasswordForm');
        const newPassword = document.getElementById('newPassword');
        const confirmPassword = document.getElementById('confirmPassword');
        const pwdMismatchError = document.getElementById('pwdMismatchError');

        function validatePasswordMatch() {
            if (confirmPassword.value && newPassword.value !== confirmPassword.value) {
                pwdMismatchError.classList.remove('d-none');
                confirmPassword.setCustomValidity("Mật khẩu không trùng khớp");
            } else {
                pwdMismatchError.classList.add('d-none');
                confirmPassword.setCustomValidity("");
            }
        }

        newPassword.addEventListener('change', validatePasswordMatch);
        confirmPassword.addEventListener('keyup', validatePasswordMatch);

        pwdForm.addEventListener('submit', function (e) {
            validatePasswordMatch();
            if (!pwdForm.checkValidity()) {
                e.preventDefault();
                e.stopPropagation();
            }
        });
    });
</script>

<%-- Nhúng Footer chung của dự án --%>
<%@include file="/WEB-INF/include/footer.jsp" %>