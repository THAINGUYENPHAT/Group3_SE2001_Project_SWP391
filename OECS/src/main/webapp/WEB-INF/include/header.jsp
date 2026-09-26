<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>

<% User loggedInUser = (User) session.getAttribute("loggedInUser"); %>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OECS - Online E-Commerce System</title>

    <!-- Nhúng CSS Bootstrap local từ thư mục assets -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/bootstrap.css">
    
    <!-- (Tùy chọn) Nhúng CDN Icons để hiển thị nút Sửa/Xóa có biểu tượng đẹp -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
</head>
<body>
    <!-- Navbar Header -->
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
        <div class="container">
            <a class="navbar-brand fw-bold text-warning" href="${pageContext.request.contextPath}/">
                <i class="bi bi-cart3"></i> OECS STORE
            </a>
            
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNavDropdown" aria-controls="navbarNavDropdown" aria-expanded="false" aria-label="Toggle navigation">
                <span class="navbar-toggler-icon"></span>
            </button>
            
            <div class="collapse navbar-collapse" id="navbarNavDropdown">
                <ul class="navbar-nav me-auto">
                    <li class="nav-item dropdown">
                        <a class="nav-link dropdown-toggle" href="#" role="button" data-bs-toggle="dropdown" aria-expanded="false">
                            Thương Hiệu
                        </a>
                        <ul class="dropdown-menu">
                            <li><a class="dropdown-item" href="${pageContext.request.contextPath}/brand">Tất cả thương hiệu</a></li>
                            <li><a class="dropdown-item" href="${pageContext.request.contextPath}/brand?view=create">Thêm thương hiệu mới</a></li>
                        </ul>
                    </li>        

                    <li class="nav-item">
                        <a class="nav-link" href="${pageContext.request.contextPath}/product">Sản Phẩm</a>
                    </li>

                    <li class="nav-item">
                        <a class="nav-link" href="${pageContext.request.contextPath}/category">Danh Mục</a>
                    </li>
                </ul>

                <ul class="navbar-nav align-items-center">
                    <c:choose>
                        <c:when test="${empty loggedInUser}">
                            <li class="nav-item me-2">
                                <a class="btn btn-outline-light btn-sm" href="${pageContext.request.contextPath}/login">Đăng nhập</a>
                            </li>
                            <li class="nav-item">
                                <a class="btn btn-warning btn-sm" href="${pageContext.request.contextPath}/register">Đăng ký</a>
                            </li>
                        </c:when>
                        <c:otherwise>
                            <li class="nav-item me-3">
                                <span class="navbar-text text-light">
                                    Xin chào, <strong class="text-warning">${loggedInUser.username}</strong>
                                </span>
                            </li>
                            <li class="nav-item">
                                <a class="btn btn-outline-danger btn-sm" href="${pageContext.request.contextPath}/logout">
                                    <i class="bi bi-box-arrow-right"></i> Đăng xuất
                                </a>
                            </li>
                        </c:otherwise>
                    </c:choose>
                </ul>
            </div>
        </div>
    </nav>

    <main class="container mt-4">