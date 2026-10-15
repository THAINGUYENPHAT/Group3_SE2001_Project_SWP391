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
                            Quên mật khẩu?
                        </h3>

                        <p class="text-muted small">
                            Nhập email đã đăng ký tài khoản.
                            Chúng tôi sẽ gửi cho bạn liên kết để đặt lại mật khẩu.
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

                    <!-- THÔNG BÁO THÀNH CÔNG -->
                    <c:if test="${not empty successMessage}">

                        <div class="alert alert-success alert-dismissible fade show"
                             role="alert">

                            <i class="bi bi-check-circle-fill me-2"></i>

                            <c:out value="${successMessage}"/>

                            <button type="button"
                                    class="btn-close"
                                    data-bs-dismiss="alert"
                                    aria-label="Close">
                            </button>

                        </div>

                    </c:if>

                    <!-- FORM QUÊN MẬT KHẨU -->
                    <form action="${pageContext.request.contextPath}/forgot-password"
                          method="post">

                        <div class="mb-3">

                            <label for="email"
                                   class="form-label fw-semibold">
                                Email
                            </label>

                            <div class="input-group">

                                <span class="input-group-text bg-light">
                                    <i class="bi bi-envelope"></i>
                                </span>

                                <input type="email"
                                       class="form-control"
                                       id="email"
                                       name="email"
                                       placeholder="Nhập email của bạn"
                                       value="<c:out value='${param.email}'/>"
                                       required
                                       autofocus>

                            </div>

                        </div>

                        <div class="d-grid mt-4">

                            <button type="submit"
                                    class="btn btn-primary fw-bold py-2">

                                <i class="bi bi-send me-1"></i>
                                Gửi liên kết đặt lại mật khẩu

                            </button>

                        </div>

                    </form>

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

<%@include file="/WEB-INF/include/footer.jsp" %>