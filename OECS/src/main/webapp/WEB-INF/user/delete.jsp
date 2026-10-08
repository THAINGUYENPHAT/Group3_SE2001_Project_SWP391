<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>

<%@include file="/WEB-INF/include/header.jsp"%>

<div class="container">

    <div class="card">

        <div class="card-header bg-danger text-white">
            <h4 class="mb-0">
                Delete User
            </h4>
        </div>

        <div class="card-body">

            <p>
                Are you sure you want to delete this user?
            </p>

            <table class="table table-bordered">
                <tr>
                    <th>ID</th>
                    <td>${user.userId}</td>
                </tr>
                <tr>
                    <th>Username</th>
                    <td>${user.username}</td>
                </tr>
                <tr>
                    <th>Email</th>
                    <td>${user.email}</td>
                </tr>
                <tr>
                    <th>Role</th>
                    <td>${user.roleName}</td>
                </tr>
            </table>

            <form action="${pageContext.request.contextPath}/user" method="post">

                <input type="hidden" name="action" value="delete">
                <input type="hidden" name="id" value="${user.userId}">

                <button type="submit" class="btn btn-danger">
                    Yes, Delete
                </button>

                <a href="${pageContext.request.contextPath}/user?view=list" class="btn btn-secondary">
                    Cancel
                </a>

            </form>

        </div>

    </div>

</div>

<%@include file="/WEB-INF/include/footer.jsp"%>