///*
// * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
// * Click nbfs://nbhost/SystemFileSystem/Templates/JSP_Servlet/Servlet.java to edit this template
// */
//package controller;
//
//import java.io.IOException;
//import java.io.PrintWriter;
//import jakarta.servlet.ServletException;
//import jakarta.servlet.annotation.WebServlet;
//import jakarta.servlet.http.HttpServlet;
//import jakarta.servlet.http.HttpServletRequest;
//import jakarta.servlet.http.HttpServletResponse;
//import jakarta.servlet.http.HttpSession;
//
///**
// *
// * @author PC
// */
//@WebServlet(name = "LogoutServlet", urlPatterns = {"/logout"})
//public class LogoutServlet extends HttpServlet {
//
//    @Override
//    protected void doGet(HttpServletRequest request, HttpServletResponse response)
//            throws ServletException, IOException {
//        //HttpSession session = request.getSession(); // mặc định sẽ là getSession(true);(true thì chưa có nó sẽ tự tạo còn false thì chưa có sẽ bỏ qua)
//        HttpSession session = request.getSession(false);
//        if (session != null) {
//            // Xóa sạch session của người dùng: Invalidate
//            session.invalidate();
//        }
//        // Redirect ve lai "/login"
//        response.sendRedirect(request.getContextPath() + "/login");
//    }
//
//    @Override
//    protected void doPost(HttpServletRequest request, HttpServletResponse response)
//            throws ServletException, IOException {
//    }
//}
