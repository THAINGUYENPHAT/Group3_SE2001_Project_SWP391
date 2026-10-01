<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<div class="container">

    <div class="d-flex justify-content-between align-items-center mb-4">

        <h2>Create User</h2>

        <a href="${pageContext.request.contextPath}/user?view=list"
           class="btn btn-secondary">
            Back
        </a>

    </div>

    <c:if test="${not empty sessionScope.error}">

        <div class="alert alert-danger">
            ${sessionScope.error}
        </div>

        <c:remove var="error"
                  scope="session"/>

    </c:if>

    <form action="${pageContext.request.contextPath}/user"
          method="post">

        <input type="hidden"
               name="action"
               value="create">

        <!-- USERNAME -->
        <div class="mb-3">

            <label class="form-label">
                Username
            </label>

            <input type="text"
                   name="username"
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
                   class="form-control"
                   required>

        </div>

        <!-- PASSWORD -->
        <div class="mb-3">

            <label class="form-label">
                Password
            </label>

            <input type="password"
                   name="password"
                   class="form-control"
                   required>

        </div>

        <!-- PHONE -->
        <div class="mb-3">

            <label class="form-label">
                Phone
            </label>

            <input type="text"
                   name="phone"
                   class="form-control">

        </div>

        <!-- ROLE -->
        <div class="mb-3">

            <label class="form-label">
                Role
            </label>

            <select name="roleId"
                    class="form-select"
                    required>

                <option value="">
                    -- Select Role --
                </option>

                <c:forEach var="role"
                           items="${roleList}">

                    <option value="${role.roleId}">
                        ${role.roleName}
                    </option>

                </c:forEach>

            </select>

        </div>

        <button type="submit"
                class="btn btn-primary">
            Create User
        </button>

        <a href="${pageContext.request.contextPath}/user?view=list"
           class="btn btn-secondary">
            Cancel
        </a>

    </form>

</div>

<%@include file="/WEB-INF/include/footer.jsp"%>