<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<div class="container py-4">

    <div class="card shadow-sm">

        <div class="card-body">

            <h4 class="fw-bold mb-4">
                Thay đổi quyền tài khoản
            </h4>

            <!-- Thông tin user -->
            <div class="mb-3">

                <label class="form-label fw-semibold">
                    Tài khoản
                </label>

                <input type="text"
                       class="form-control"
                       value="${user.username}"
                       disabled>

            </div>

            <div class="mb-3">

                <label class="form-label fw-semibold">
                    Email
                </label>

                <input type="text"
                       class="form-control"
                       value="${user.email}"
                       disabled>

            </div>

            <div class="mb-3">

                <label class="form-label fw-semibold">
                    Quyền hiện tại
                </label>

                <input type="text"
                       class="form-control"
                       value="${user.roleName}"
                       disabled>

            </div>

            <!-- Form Update Role -->
            <form action="${pageContext.request.contextPath}/user"
                  method="post">

                <input type="hidden"
                       name="action"
                       value="updateRole">

                <input type="hidden"
                       name="id"
                       value="${user.userId}">

                <div class="mb-4">

                    <label class="form-label fw-semibold">
                        Quyền mới
                    </label>

                    <select name="roleId"
                            class="form-select"
                            required>

                        <c:forEach items="${roleList}" var="role">

                            <option value="${role.roleId}"
                                    ${role.roleId == user.roleId
                                      ? 'selected'
                                      : ''}>

                                ${role.roleName}

                            </option>

                        </c:forEach>

                    </select>

                </div>

                <div class="d-flex gap-2">

                    <button type="submit"
                            class="btn btn-primary">

                        <i class="bi bi-check-circle me-1"></i>
                        Cập nhật quyền

                    </button>

                    <a href="${pageContext.request.contextPath}/user?view=list"
                       class="btn btn-secondary">

                        Quay lại

                    </a>

                </div>

            </form>

        </div>

    </div>

</div>

<%@include file="/WEB-INF/include/footer.jsp"%>