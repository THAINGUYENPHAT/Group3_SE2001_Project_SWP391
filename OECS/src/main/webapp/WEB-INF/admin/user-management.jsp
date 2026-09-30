<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core"%>
<%@taglib prefix="fmt" uri="jakarta.tags.fmt"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Quản Lý Tài Khoản Người Dùng - Admin</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f4f6f9; }
            .admin-container { max-width: 1100px; margin: 30px auto; background: #fff; padding: 25px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
            .page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; border-bottom: 2px solid #007bff; padding-bottom: 10px; }
            .search-box { display: flex; gap: 10px; margin-bottom: 20px; }
            .search-box input[type="text"] { flex: 1; padding: 8px 12px; border: 1px solid #ccc; border-radius: 4px; }
            .btn { padding: 8px 16px; border: none; border-radius: 4px; cursor: pointer; font-weight: bold; text-decoration: none; display: inline-block; }
            .btn-primary { background-color: #007bff; color: white; }
            .btn-danger { background-color: #dc3545; color: white; }
            .btn-success { background-color: #28a745; color: white; }
            .btn-sm { padding: 5px 10px; font-size: 12px; }
            table { width: 100%; border-collapse: collapse; margin-top: 10px; }
            table, th, td { border: 1px solid #e0e0e0; }
            th, td { padding: 12px; text-align: left; }
            th { background-color: #f8f9fa; color: #333; }
            .badge { padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }
            .badge-active { background-color: #d4edda; color: #155724; }
            .badge-locked { background-color: #f8d7da; color: #721c24; }
            .alert-success { padding: 10px; background-color: #d4edda; color: #155724; border-radius: 4px; margin-bottom: 15px; }
            .alert-danger { padding: 10px; background-color: #f8d7da; color: #721c24; border-radius: 4px; margin-bottom: 15px; }
        </style>
    </head>
    <body>

        <%@include file="/WEB-INF/include/header.jsp" %>

        <div class="admin-container">
            <div class="page-header">
                <h2>Quản Lý Tài Khoản Khách Hàng</h2>
            </div>

            <c:if test="${not empty message}">
                <div class="alert-success">${message}</div>
            </c:if>
            <c:if test="${not empty error}">
                <div class="alert-danger">${error}</div>
            </c:if>

            <form action="${pageContext.request.contextPath}/admin/users" method="get" class="search-box">
                <input type="text" name="keyword" value="${keyword}" placeholder="Tìm theo tên đăng nhập, email, SĐT...">
                <button type="submit" class="btn btn-primary">Tra cứu</button>
            </form>

            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Tên đăng nhập</th>
                        <th>Email</th>
                        <th>Số điện thoại</th>
                        <th>Vai trò</th>
                        <th>Ngày tạo</th>
                        <th>Trạng thái</th>
                        <th>Thao tác</th>
                    </tr>
                </thead>
                <tbody>
                    <c:forEach var="u" items="${userList}">
                        <tr>
                            <td>${u.userId}</td>
                            <td><strong>${u.username}</strong></td>
                            <td>${u.email}</td>
                            <td>${u.phone != null ? u.phone : 'N/A'}</td>
                            <td>${u.roleId == 0 ? 'Bị khóa' : u.roleName}</td>
                            <td><fmt:formatDate value="${u.createdAt}" pattern="dd/MM/yyyy HH:mm"/></td>
                            <td>
                                <c:choose>
                                    <c:when test="${u.roleId == 0}">
                                        <span class="badge badge-locked">Đã khóa</span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="badge badge-active">Hoạt động</span>
                                    </c:otherwise>
                                </c:choose>
                            </td>
                            <td>
                                <!-- Không cho phép khóa tài khoản Admin chính mình -->
                                <c:if test="${u.roleId != 1}">
                                    <c:choose>
                                        <c:when test="${u.roleId != 0}">
                                            <a href="${pageContext.request.contextPath}/admin/users?action=toggleStatus&id=${u.userId}&roleId=${u.roleId}&keyword=${keyword}" 
                                               class="btn btn-danger btn-sm" 
                                               onclick="return confirm('Bạn có chắc chắn muốn KHÓA tài khoản này?');">Khóa</a>
                                        </c:when>
                                        <c:otherwise>
                                            <a href="${pageContext.request.contextPath}/admin/users?action=toggleStatus&id=${u.userId}&roleId=${u.roleId}&keyword=${keyword}" 
                                               class="btn btn-success btn-sm" 
                                               onclick="return confirm('Bạn có chắc chắn muốn MỞ KHÓA tài khoản này?');">Mở khóa</a>
                                        </c:otherwise>
                                    </c:choose>
                                </c:if>
                            </td>
                        </tr>
                    </c:forEach>
                    <c:if test="${empty userList}">
                        <tr>
                            <td colspan="8" style="text-align: center; color: #777;">Không tìm thấy người dùng nào.</td>
                        </tr>
                    </c:if>
                </tbody>
            </table>
        </div>

        <%@include file="/WEB-INF/include/footer.jsp" %>

    </body>
</html>