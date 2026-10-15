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
                            Đặt lại mật khẩu
                        </h3>

                        <p class="text-muted small">
                            Nhập mật khẩu mới cho tài khoản của bạn.
                        </p>
                    </div>

                    <!-- THÔNG BÁO LỖI -->
                    <c:if test="${not empty errorMessage}">
                        <div class="alert alert-danger alert-dismissible fade show"
                             role="alert">

                            <i class="bi bi-exclamation-triangle-fill me-2"></i>

                            <c:out value="${errorMessage}"/>

                            <button type="button"
                                    class="btn-close"
                                    data-bs-dismiss="alert"
                                    aria-label="Close">
                            </button>
                        </div>
                    </c:if>

                    <!-- CHỈ HIỆN FORM KHI TOKEN HỢP LỆ -->
                    <c:if test="${not empty token}">

                        <form action="${pageContext.request.contextPath}/reset-password"
                              method="post">

                            <!-- TOKEN ẨN -->
                            <input type="hidden"
                                   name="token"
                                   value="<c:out value='${token}'/>">

                            <!-- MẬT KHẨU MỚI -->
                            <div class="mb-3">

                                <label for="newPassword"
                                       class="form-label fw-semibold">
                                    Mật khẩu mới
                                </label>

                                <div class="input-group">

                                    <span class="input-group-text bg-light">
                                        <i class="bi bi-lock"></i>
                                    </span>

                                    <input type="password"
                                           class="form-control"
                                           id="newPassword"
                                           name="newPassword"
                                           placeholder="Nhập mật khẩu mới"
                                           minlength="6"
                                           required>

                                    <button class="btn btn-outline-secondary"
                                            type="button"
                                            id="toggleNewPassword">

                                        <i class="bi bi-eye"
                                           id="newPasswordIcon"></i>

                                    </button>

                                </div>

                            </div>

                            <!-- XÁC NHẬN MẬT KHẨU -->
                            <div class="mb-3">

                                <label for="confirmPassword"
                                       class="form-label fw-semibold">
                                    Xác nhận mật khẩu
                                </label>

                                <div class="input-group">

                                    <span class="input-group-text bg-light">
                                        <i class="bi bi-lock-fill"></i>
                                    </span>

                                    <input type="password"
                                           class="form-control"
                                           id="confirmPassword"
                                           name="confirmPassword"
                                           placeholder="Nhập lại mật khẩu mới"
                                           minlength="6"
                                           required>

                                    <button class="btn btn-outline-secondary"
                                            type="button"
                                            id="toggleConfirmPassword">

                                        <i class="bi bi-eye"
                                           id="confirmPasswordIcon"></i>

                                    </button>

                                </div>

                            </div>

                            <!-- NÚT SUBMIT -->
                            <div class="d-grid mt-4">

                                <button type="submit"
                                        class="btn btn-primary fw-bold py-2">

                                    <i class="bi bi-check-circle me-1"></i>
                                    Đặt lại mật khẩu

                                </button>

                            </div>

                        </form>

                    </c:if>

                    <hr class="my-4">

                    <!-- QUAY LẠI LOGIN -->
                    <div class="text-center small">

                        <a href="${pageContext.request.contextPath}/login"
                           class="fw-semibold text-decoration-none text-primary">

                            <i class="bi bi-arrow-left me-1"></i>
                            Quay lại đăng nhập

                        </a>

                    </div>

                </div>
            </div>

        </div>
    </div>
</div>

<script>
    document.addEventListener('DOMContentLoaded', function () {

        const toggleNewPassword =
                document.getElementById('toggleNewPassword');

        const newPassword =
                document.getElementById('newPassword');

        const newPasswordIcon =
                document.getElementById('newPasswordIcon');

        const toggleConfirmPassword =
                document.getElementById('toggleConfirmPassword');

        const confirmPassword =
                document.getElementById('confirmPassword');

        const confirmPasswordIcon =
                document.getElementById('confirmPasswordIcon');

        // Hiện / ẩn mật khẩu mới
        if (toggleNewPassword && newPassword && newPasswordIcon) {

            toggleNewPassword.addEventListener('click', function () {

                const type =
                        newPassword.getAttribute('type') === 'password'
                        ? 'text'
                        : 'password';

                newPassword.setAttribute('type', type);

                newPasswordIcon.classList.toggle('bi-eye');
                newPasswordIcon.classList.toggle('bi-eye-slash');
            });
        }

        // Hiện / ẩn mật khẩu xác nhận
        if (toggleConfirmPassword
                && confirmPassword
                && confirmPasswordIcon) {

            toggleConfirmPassword.addEventListener('click', function () {

                const type =
                        confirmPassword.getAttribute('type') === 'password'
                        ? 'text'
                        : 'password';

                confirmPassword.setAttribute('type', type);

                confirmPasswordIcon.classList.toggle('bi-eye');
                confirmPasswordIcon.classList.toggle('bi-eye-slash');
            });
        }

    });
</script>

<%@include file="/WEB-INF/include/footer.jsp" %>