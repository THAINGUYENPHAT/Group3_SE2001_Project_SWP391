<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>

<%-- Nhúng Header chung --%>
<%@include file="/WEB-INF/include/header.jsp" %>

<style>
    .profile-sidebar {
        background: #ffffff;
        border-radius: 12px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.05);
    }
    .profile-avatar-circle {
        width: 90px;
        height: 90px;
        border-radius: 50%;
        background: linear-gradient(135deg, #0d6efd, #0dcaf0);
        color: white;
        font-size: 36px;
        font-weight: bold;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto;
        box-shadow: 0 4px 10px rgba(13, 110, 253, 0.25);
    }
    .profile-nav .nav-link {
        color: #495057;
        font-weight: 500;
        padding: 12px 16px;
        border-radius: 8px;
        margin-bottom: 6px;
        transition: all 0.2s ease;
    }
    .profile-nav .nav-link:hover {
        background-color: #f8f9fa;
        color: #0d6efd;
    }
    .profile-nav .nav-link.active {
        background-color: #e7f1ff;
        color: #0d6efd;
        font-weight: 600;
    }
    .profile-content-card {
        background: #ffffff;
        border-radius: 12px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.05);
    }
    .input-group-text {
        background-color: #f8f9fa;
        border-right: none;
    }
    .form-control-with-icon {
        border-left: none;
    }
    .form-control-with-icon:focus {
        border-color: #dee2e6;
        box-shadow: none;
    }
    .input-group:focus-within {
        border-radius: 0.375rem;
        box-shadow: 0 0 0 0.25rem rgba(13, 110, 253, 0.25);
    }
    .input-group:focus-within .input-group-text,
    .input-group:focus-within .form-control {
        border-color: #86b7fe;
    }
</style>

<div class="container my-5">
    <div class="row g-4">
        <!-- SIDEBAR TRÁI: THÔNG TIN TỔNG QUAN & MENU -->
        <div class="col-lg-3 col-md-4">
            <div class="profile-sidebar p-4 text-center">
                <!-- Avatar tự động từ ký tự đầu tên -->
                <div class="profile-avatar-circle mb-3">
                    <c:out value="${sessionScope.loggedInUser.username.substring(0, 1).toUpperCase()}"/>
                </div>
                
                <h5 class="fw-bold mb-1 text-dark">
                    <c:out value="${sessionScope.loggedInUser.username}"/>
                </h5>
                <p class="text-muted small mb-2">
                    <i class="bi bi-envelope me-1"></i><c:out value="${sessionScope.loggedInUser.email}"/>
                </p>

                <!-- Badge Vai trò -->
                <span class="badge ${sessionScope.loggedInUser.adminOrStaff ? 'bg-primary-subtle text-primary border border-primary-subtle' : 'bg-success-subtle text-success border border-success-subtle'} rounded-pill px-3 py-2 mb-4">
                    <i class="bi ${sessionScope.loggedInUser.adminOrStaff ? 'bi-shield-check' : 'bi-person'} me-1"></i>
                    <c:out value="${sessionScope.loggedInUser.roleName}"/>
                </span>

                <hr class="my-3 text-muted">

                <!-- Navigation Tabs -->
                <div class="nav flex-column nav-pills profile-nav" id="v-pills-tab" role="tablist" aria-orientation="vertical">
                    <button class="nav-link text-start active" id="v-pills-profile-tab" data-bs-toggle="pill" data-bs-target="#v-pills-profile" type="button" role="tab">
                        <i class="bi bi-person-gear me-2"></i>Thông tin cá nhân
                    </button>
                    <button class="nav-link text-start" id="v-pills-password-tab" data-bs-toggle="pill" data-bs-target="#v-pills-password" type="button" role="tab">
                        <i class="bi bi-shield-lock me-2"></i>Đổi mật khẩu
                    </button>
                </div>
            </div>
        </div>

        <!-- NỘI DUNG PHẢI: FORM CHI TIẾT -->
        <div class="col-lg-9 col-md-8">
            <div class="profile-content-card p-4 p-md-5">
                <div class="tab-content" id="v-pills-tabContent">
                    
                    <!-- TAB 1: THÔNG TIN CÁ NHÂN -->
                    <div class="tab-pane fade show active" id="v-pills-profile" role="tabpanel">
                        <div class="border-bottom pb-3 mb-4 d-flex align-items-center justify-content-between">
                            <div>
                                <h4 class="fw-bold text-dark mb-1">Hồ Sơ Cá Nhân</h4>
                                <p class="text-muted small mb-0">Quản lý và cập nhật thông tin tài khoản của bạn</p>
                            </div>
                        </div>

                        <!-- THÔNG BÁO -->
                        <c:if test="${not empty profileSuccess}">
                            <div class="alert alert-success alert-dismissible fade show" role="alert">
                                <i class="bi bi-check-circle-fill me-2"></i><c:out value="${profileSuccess}"/>
                                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                            </div>
                        </c:if>
                        <c:if test="${not empty profileError}">
                            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                                <i class="bi bi-exclamation-triangle-fill me-2"></i><c:out value="${profileError}"/>
                                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                            </div>
                        </c:if>

                        <form action="${pageContext.request.contextPath}/profile" method="post">
                            <input type="hidden" name="action" value="updateProfile">

                            <div class="row g-3">
                                <div class="col-md-6 mb-3">
                                    <label class="form-label fw-bold text-secondary">Tên đăng nhập</label>
                                    <div class="input-group">
                                        <span class="input-group-text"><i class="bi bi-person text-muted"></i></span>
                                        <input type="text" class="form-control form-control-with-icon bg-light" value="<c:out value='${sessionScope.loggedInUser.username}'/>" disabled readonly>
                                    </div>
                                </div>

                                <div class="col-md-6 mb-3">
                                    <label for="email" class="form-label fw-bold text-secondary">Email <span class="text-danger">*</span></label>
                                    <div class="input-group">
                                        <span class="input-group-text"><i class="bi bi-envelope text-muted"></i></span>
                                        <input type="email" class="form-control form-control-with-icon" id="email" name="email" value="<c:out value='${sessionScope.loggedInUser.email}'/>" required>
                                    </div>
                                </div>

                                <div class="col-md-12 mb-3">
                                    <label for="phone" class="form-label fw-bold text-secondary">Số điện thoại</label>
                                    <div class="input-group">
                                        <span class="input-group-text"><i class="bi bi-telephone text-muted"></i></span>
                                        <input type="tel" class="form-control form-control-with-icon" id="phone" name="phone" value="<c:out value='${sessionScope.loggedInUser.phone}'/>" pattern="(0[3|5|7|8|9])+([0-9]{8})\b" title="Số điện thoại Việt Nam gồm 10 chữ số">
                                    </div>
                                </div>

                                <div class="col-md-12 mb-3">
                                    <label for="address" class="form-label fw-bold text-secondary">Địa chỉ giao hàng mặc định</label>
                                    <div class="input-group">
                                        <span class="input-group-text"><i class="bi bi-geo-alt text-muted"></i></span>
                                        <textarea id="address" name="address" class="form-control form-control-with-icon" rows="3" placeholder="Nhập địa chỉ cụ thể (Số nhà, đường, xã/phường, quận/huyện, tỉnh/TP)...">${sessionScope.loggedInUser.address}</textarea>
                                    </div>
                                </div>
                            </div>

                            <div class="text-end mt-4">
                                <button type="submit" class="btn btn-primary px-4 py-2 fw-bold rounded-3">
                                    <i class="bi bi-check2-circle me-1"></i> Lưu thay đổi
                                </button>
                            </div>
                        </form>
                    </div>

                    <!-- TAB 2: ĐỔI MẬT KHẨU -->
                    <div class="tab-pane fade" id="v-pills-password" role="tabpanel">
                        <div class="border-bottom pb-3 mb-4">
                            <h4 class="fw-bold text-dark mb-1">Đổi Mật Khẩu</h4>
                            <p class="text-muted small mb-0">Nên sử dụng mật khẩu mạnh gồm chữ cái, chữ số và ký tự đặc biệt</p>
                        </div>

                        <!-- THÔNG BÁO -->
                        <c:if test="${not empty pwdSuccess}">
                            <div class="alert alert-success alert-dismissible fade show" role="alert">
                                <i class="bi bi-check-circle-fill me-2"></i><c:out value="${pwdSuccess}"/>
                                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                            </div>
                        </c:if>
                        <c:if test="${not empty pwdError}">
                            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                                <i class="bi bi-exclamation-triangle-fill me-2"></i><c:out value="${pwdError}"/>
                                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                            </div>
                        </c:if>

                        <form action="${pageContext.request.contextPath}/profile" method="post" id="changePasswordForm" style="max-width: 550px;">
                            <input type="hidden" name="action" value="changePassword">

                            <div class="mb-3">
                                <label for="oldPassword" class="form-label fw-bold text-secondary">Mật khẩu hiện tại <span class="text-danger">*</span></label>
                                <div class="input-group">
                                    <span class="input-group-text"><i class="bi bi-key text-muted"></i></span>
                                    <input type="password" class="form-control form-control-with-icon" id="oldPassword" name="oldPassword" required>
                                </div>
                            </div>

                            <div class="mb-3">
                                <label for="newPassword" class="form-label fw-bold text-secondary">Mật khẩu mới <span class="text-danger">*</span></label>
                                <div class="input-group">
                                    <span class="input-group-text"><i class="bi bi-lock text-muted"></i></span>
                                    <input type="password" class="form-control form-control-with-icon" id="newPassword" name="newPassword" minlength="6" required placeholder="Tối thiểu 6 ký tự">
                                </div>
                            </div>

                            <div class="mb-3">
                                <label for="confirmPassword" class="form-label fw-bold text-secondary">Xác nhận mật khẩu mới <span class="text-danger">*</span></label>
                                <div class="input-group">
                                    <span class="input-group-text"><i class="bi bi-shield-check text-muted"></i></span>
                                    <input type="password" class="form-control form-control-with-icon" id="confirmPassword" name="confirmPassword" required>
                                </div>
                                <div id="pwdMismatchError" class="text-danger small mt-2 d-none">
                                    <i class="bi bi-x-circle me-1"></i>Mật khẩu mới và Xác nhận mật khẩu không khớp!
                                </div>
                            </div>

                            <div class="mt-4">
                                <button type="submit" class="btn btn-danger px-4 py-2 fw-bold rounded-3">
                                    <i class="bi bi-arrow-repeat me-1"></i> Cập nhật mật khẩu
                                </button>
                            </div>
                        </form>
                    </div>

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

        // Tự động giữ active tab "Đổi mật khẩu" nếu vừa gửi form Đổi mật khẩu có lỗi/thành công
        <c:if test="${not empty pwdSuccess || not empty pwdError}">
            const pwdTabTrigger = new bootstrap.Tab(document.querySelector('#v-pills-password-tab'));
            pwdTabTrigger.show();
        </c:if>
    });
</script>

<%-- Nhúng Footer chung --%>
<%@include file="/WEB-INF/include/footer.jsp" %>