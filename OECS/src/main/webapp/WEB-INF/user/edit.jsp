<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<div class="container">

    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2>Edit User</h2>
        <a href="${pageContext.request.contextPath}/user?view=list" class="btn btn-secondary">
            Back
        </a>
    </div>

    <c:if test="${not empty sessionScope.error}">
        <div class="alert alert-danger">
            ${sessionScope.error}
        </div>
        <c:remove var="error" scope="session"/>
    </c:if>

    <form action="${pageContext.request.contextPath}/user" method="post">

        <!-- ACTION & ID -->
        <input type="hidden" name="action" value="edit">
        <input type="hidden" name="id" value="${user.userId}">

        <!-- USERNAME -->
        <div class="mb-3">
            <label class="form-label">
                Username
            </label>
            <input type="text"
                   name="username"
                   value="${user.username}"
                   class="form-control"
                   required>
        </div>

        <!-- EMAIL -->
        <div class="mb-3">
            <label class="form-label">
                Email
            </label>
            <input type="email"
                   name="email"
                   value="${user.email}"
                   class="form-control"
                   required>
        </div>

        <!-- PASSWORD -->
        <div class="mb-3">
            <label class="form-label">
                New Password
            </label>
            <input type="password"
                   name="password"
                   class="form-control">
            <small class="text-muted">
                Leave blank if you do not want to change password.
            </small>
        </div>

        <!-- PHONE -->
        <div class="mb-3">
            <label class="form-label">
                Phone
            </label>
            <input type="text"
                   name="phone"
                   value="${user.phone}"
                   class="form-control">
        </div>

        <!-- ROLE -->
        <div class="mb-3">
            <label class="form-label">
                Role
            </label>
            <select name="roleId" class="form-select" required>
                <c:forEach var="role" items="${roleList}">
                    <option value="${role.roleId}" ${role.roleId == user.roleId ? 'selected' : ''}>
                        ${role.roleName}
                    </option>
                </c:forEach>
            </select>
        </div>

        <button type="submit" class="btn btn-warning">
            Update User
        </button>

        <a href="${pageContext.request.contextPath}/user?view=list" class="btn btn-secondary">
            Cancel
        </a>

    </form>

</div>

<%@include file="/WEB-INF/include/footer.jsp"%>