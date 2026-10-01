-- ========================================================
-- 1. XÓA VÀ TẠO LẠI DATABASE SẠCH (TRÁNH LỖI KHÓA NGOẠI)
-- ========================================================
USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'OECS')
BEGIN
    -- Ngắt toàn bộ kết nối đang mở tới DB để DROP thành công
    ALTER DATABASE OECS SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE OECS;
END
GO

CREATE DATABASE OECS;
GO

USE OECS;
GO

-- ========================================================
-- II. TẠO BẢNG (SCHEMA DEFINITIONS)
-- ========================================================

-- 1. QUẢN LÝ NGƯỜI DÙNG & PHÂN QUYỀN
CREATE TABLE ROLES (
    role_id INT IDENTITY(1,1) PRIMARY KEY,
    role_name NVARCHAR(50) NOT NULL UNIQUE,
    description NVARCHAR(MAX)
);

CREATE TABLE [USER] (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    created_at DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE USER_ROLES (
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT FK_UserRoles_User FOREIGN KEY (user_id) REFERENCES [USER](user_id) ON DELETE CASCADE,
    CONSTRAINT FK_UserRoles_Role FOREIGN KEY (role_id) REFERENCES ROLES(role_id) ON DELETE CASCADE
);

CREATE TABLE STAFF (
    staff_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    department NVARCHAR(100),
    position NVARCHAR(100),
    CONSTRAINT FK_Staff_User FOREIGN KEY (user_id) REFERENCES [USER](user_id) ON DELETE CASCADE
);

CREATE TABLE ADDRESSBOOK (
    address_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    recipient_name NVARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    address_line NVARCHAR(MAX) NOT NULL,
    is_default BIT DEFAULT 0,
    CONSTRAINT FK_AddressBook_User FOREIGN KEY (user_id) REFERENCES [USER](user_id) ON DELETE CASCADE
);

-- 2. DANH MỤC, SẢN PHẨM & THUỘC TÍNH
CREATE TABLE CATEGORY (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    category_name NVARCHAR(100) NOT NULL,
    parent_id INT NULL,
    CONSTRAINT FK_Category_Parent FOREIGN KEY (parent_id) REFERENCES CATEGORY(category_id)
);

CREATE TABLE BRAND (
    brand_id INT IDENTITY(1,1) PRIMARY KEY,
    brand_name NVARCHAR(100) NOT NULL,
    logo_url VARCHAR(2048)
);

CREATE TABLE PRODUCT (
    product_id INT IDENTITY(1,1) PRIMARY KEY,
    category_id INT NOT NULL,
    brand_id INT NOT NULL,
    product_name NVARCHAR(255) NOT NULL,
    description NVARCHAR(MAX),
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Product_Category FOREIGN KEY (category_id) REFERENCES CATEGORY(category_id),
    CONSTRAINT FK_Product_Brand FOREIGN KEY (brand_id) REFERENCES BRAND(brand_id)
);

CREATE TABLE ATTRIBUTE (
    attribute_id INT IDENTITY(1,1) PRIMARY KEY,
    attribute_name NVARCHAR(100) NOT NULL
);

CREATE TABLE PRODUCT_SPECIFICATION (
    product_id INT NOT NULL,
    attribute_id INT NOT NULL,
    value NVARCHAR(255) NOT NULL,
    PRIMARY KEY (product_id, attribute_id),
    CONSTRAINT FK_Spec_Product FOREIGN KEY (product_id) REFERENCES PRODUCT(product_id) ON DELETE CASCADE,
    CONSTRAINT FK_Spec_Attribute FOREIGN KEY (attribute_id) REFERENCES ATTRIBUTE(attribute_id) ON DELETE CASCADE
);

CREATE TABLE PRODUCT_SKU (
    sku_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT NOT NULL,
    sku_code VARCHAR(100) NOT NULL UNIQUE,
    price DECIMAL(18, 2) NOT NULL,
    stock_quantity INT DEFAULT 0,
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_SKU_Product FOREIGN KEY (product_id) REFERENCES PRODUCT(product_id) ON DELETE CASCADE
);

-- 3. GIỎ HÀNG
CREATE TABLE CART (
    cart_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Cart_User FOREIGN KEY (user_id) REFERENCES [USER](user_id) ON DELETE CASCADE
);

CREATE TABLE CART_ITEMS (
    cart_item_id INT IDENTITY(1,1) PRIMARY KEY,
    cart_id INT NOT NULL,
    sku_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    CONSTRAINT FK_CartItems_Cart FOREIGN KEY (cart_id) REFERENCES CART(cart_id) ON DELETE CASCADE,
    CONSTRAINT FK_CartItems_SKU FOREIGN KEY (sku_id) REFERENCES PRODUCT_SKU(sku_id) ON DELETE CASCADE
);

-- 4. ĐƠN HÀNG, VẬN CHUYỂN & VOUCHER
CREATE TABLE SHIPPING_PARTNER (
    partner_id INT IDENTITY(1,1) PRIMARY KEY,
    partner_name NVARCHAR(100) NOT NULL,
    contact_phone VARCHAR(20)
);

CREATE TABLE VOUCHER (
    voucher_id INT IDENTITY(1,1) PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    discount_amount DECIMAL(18, 2) NOT NULL,
    min_order_value DECIMAL(18, 2) DEFAULT 0,
    valid_from DATETIME2,
    valid_to DATETIME2
);

CREATE TABLE [ORDER] (
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    address_id INT NOT NULL,
    shipping_partner_id INT,
    total_amount DECIMAL(18, 2) NOT NULL,
    shipping_fee DECIMAL(18, 2) DEFAULT 0,
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Order_User FOREIGN KEY (user_id) REFERENCES [USER](user_id),
    CONSTRAINT FK_Order_Address FOREIGN KEY (address_id) REFERENCES ADDRESSBOOK(address_id),
    CONSTRAINT FK_Order_ShippingPartner FOREIGN KEY (shipping_partner_id) REFERENCES SHIPPING_PARTNER(partner_id)
);

CREATE TABLE ORDER_ITEM (
    order_item_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL,
    sku_id INT NOT NULL,
    price DECIMAL(18, 2) NOT NULL,
    quantity INT NOT NULL,
    CONSTRAINT FK_OrderItem_Order FOREIGN KEY (order_id) REFERENCES [ORDER](order_id) ON DELETE CASCADE,
    CONSTRAINT FK_OrderItem_SKU FOREIGN KEY (sku_id) REFERENCES PRODUCT_SKU(sku_id)
);

CREATE TABLE ORDER_STATUS_HISTORY (
    status_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL,
    status NVARCHAR(50) NOT NULL,
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_StatusHistory_Order FOREIGN KEY (order_id) REFERENCES [ORDER](order_id) ON DELETE CASCADE
);

CREATE TABLE VOUCHER_USAGES (
    usage_id INT IDENTITY(1,1) PRIMARY KEY,
    voucher_id INT NOT NULL,
    order_id INT NOT NULL,
    user_id INT NOT NULL,
    used_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_VoucherUsage_Voucher FOREIGN KEY (voucher_id) REFERENCES VOUCHER(voucher_id),
    CONSTRAINT FK_VoucherUsage_Order FOREIGN KEY (order_id) REFERENCES [ORDER](order_id),
    CONSTRAINT FK_VoucherUsage_User FOREIGN KEY (user_id) REFERENCES [USER](user_id)
);

CREATE TABLE COD_SETTLEMENTS (
    settlement_id INT IDENTITY(1,1) PRIMARY KEY,
    partner_id INT NOT NULL,
    total_cod_amount DECIMAL(18, 2) NOT NULL,
    settlement_date DATETIME2 DEFAULT GETDATE(),
    status NVARCHAR(50) DEFAULT N'PENDING',
    CONSTRAINT FK_CODSettlement_Partner FOREIGN KEY (partner_id) REFERENCES SHIPPING_PARTNER(partner_id)
);

-- 5. ĐÁNH GIÁ SẢN PHẨM
CREATE TABLE PRODUCT_REVIEWS (
    review_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    order_item_id INT NOT NULL,
    sku_id INT NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment NVARCHAR(MAX),
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Review_User FOREIGN KEY (user_id) REFERENCES [USER](user_id),
    CONSTRAINT FK_Review_OrderItem FOREIGN KEY (order_item_id) REFERENCES ORDER_ITEM(order_item_id),
    CONSTRAINT FK_Review_SKU FOREIGN KEY (sku_id) REFERENCES PRODUCT_SKU(sku_id)
);

-- 6. QUẢN LÝ NHẬP HÀNG
CREATE TABLE SUPPLIERS (
    supplier_id INT IDENTITY(1,1) PRIMARY KEY,
    supplier_name NVARCHAR(150) NOT NULL,
    contact_email VARCHAR(100),
    phone VARCHAR(20),
    address NVARCHAR(MAX)
);

CREATE TABLE PURCHASE_ORDERS (
    po_id INT IDENTITY(1,1) PRIMARY KEY,
    supplier_id INT NOT NULL,
    total_cost DECIMAL(18, 2) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_PO_Supplier FOREIGN KEY (supplier_id) REFERENCES SUPPLIERS(supplier_id)
);

CREATE TABLE PURCHASE_ORDER_ITEMS (
    po_item_id INT IDENTITY(1,1) PRIMARY KEY,
    po_id INT NOT NULL,
    sku_id INT NOT NULL,
    unit_cost DECIMAL(18, 2) NOT NULL,
    quantity INT NOT NULL,
    CONSTRAINT FK_POItems_PO FOREIGN KEY (po_id) REFERENCES PURCHASE_ORDERS(po_id) ON DELETE CASCADE,
    CONSTRAINT FK_POItems_SKU FOREIGN KEY (sku_id) REFERENCES PRODUCT_SKU(sku_id)
);
GO

-- ========================================================
-- III. CHÈN DỮ LIỆU MẪU (SEED DATA)
-- ========================================================

-- ROLES
INSERT INTO ROLES (role_name, description) VALUES 
(N'Admin', N'Quản trị viên hệ thống - Toàn quyền'),
(N'Staff', N'Nhân viên vận hành và xử lý đơn hàng'),
(N'Customer', N'Khách hàng mua sắm');

-- USER
INSERT INTO [USER] (username, email, password_hash, phone) VALUES 
('admin_sys', 'admin@oecs.com', 'e10adc3949ba59abbe56e057f20f883e', '0901111111'),
('staff_khang', 'khang.staff@oecs.com', 'e10adc3949ba59abbe56e057f20f883e', '0902222222'),
('phat_user', 'phat.user@gmail.com', 'e10adc3949ba59abbe56e057f20f883e', '0903333333'),
('lan_customer', 'lan.nguyen@gmail.com', 'e10adc3949ba59abbe56e057f20f883e', '0904444444');

-- USER_ROLES
INSERT INTO USER_ROLES (user_id, role_id) VALUES 
(1, 1),
(2, 2),
(3, 3),
(4, 3);

-- STAFF
INSERT INTO STAFF (user_id, department, position) VALUES 
(2, N'Phòng Vận Hành', N'Chuyên viên kiểm duyệt đơn');

-- ADDRESSBOOK
INSERT INTO ADDRESSBOOK (user_id, recipient_name, phone_number, address_line, is_default) VALUES 
(3, N'Trần Phát', '0903333333', N'123 Đường 3/2, Phường Xuân Khánh, Quận Ninh Kiều, Cần Thơ', 1),
(3, N'Trần Phát (Văn phòng)', '0903333333', N'456 Nguyễn Văn Cừ, Phường An Khánh, Ninh Kiều, Cần Thơ', 0),
(4, N'Nguyễn Thị Lan', '0904444444', N'789 Lê Duẩn, Quận 1, TP. Hồ Chí Minh', 1);

-- CATEGORY
INSERT INTO CATEGORY (category_name, parent_id) VALUES 
(N'Điện thoại & Thiết bị di động', NULL),
(N'Máy tính & Laptop', NULL),         
(N'Smartphone', 1),                    
(N'Laptop Văn Phòng', 2);              

-- BRAND
INSERT INTO BRAND (brand_name, logo_url) VALUES 
(N'Apple', 'https://cdn.oecs.com/brands/apple.png'),
(N'Samsung', 'https://cdn.oecs.com/brands/samsung.png'),
(N'Lenovo', 'https://cdn.oecs.com/brands/lenovo.png');

-- PRODUCT
INSERT INTO PRODUCT (category_id, brand_id, product_name, description) VALUES 
(3, 1, N'iPhone 15 Pro', N'Điện thoại flagship cao cấp vỏ Titan từ Apple'),
(3, 2, N'Samsung Galaxy S24 Ultra', N'Điện thoại cao cấp tích hợp Galaxy AI'),
(4, 3, N'Lenovo LOQ 15', N'Laptop gaming/đồ họa hiệu năng cao trong tầm giá');

-- ATTRIBUTE
INSERT INTO ATTRIBUTE (attribute_name) VALUES 
(N'Màn hình'),
(N'RAM'),
(N'Dung lượng lưu trữ'),
(N'Chip xử lý (CPU)');

-- PRODUCT_SPECIFICATION
INSERT INTO PRODUCT_SPECIFICATION (product_id, attribute_id, value) VALUES 
(1, 1, N'6.1 inch Super Retina XDR OLED'),
(1, 4, N'Apple A17 Pro'),
(2, 1, N'6.8 inch Dynamic AMOLED 2X'),
(2, 4, N'Snapdragon 8 Gen 3 for Galaxy'),
(3, 2, N'16GB DDR5'),
(3, 4, N'Intel Core i5-13420H');

-- PRODUCT_SKU
INSERT INTO PRODUCT_SKU (product_id, sku_code, price, stock_quantity) VALUES 
(1, 'IP15P-128-BLK', 27990000.00, 15),
(1, 'IP15P-256-SLV', 30990000.00, 10),
(2, 'SS-S24U-256-GRY', 29990000.00, 20),
(3, 'LOQ-15-16GB-512GB', 21490000.00, 8);

-- CART
INSERT INTO CART (user_id) VALUES 
(3),
(4);

-- CART_ITEMS
INSERT INTO CART_ITEMS (cart_id, sku_id, quantity) VALUES 
(1, 2, 1),
(2, 4, 1);

-- SHIPPING_PARTNER
INSERT INTO SHIPPING_PARTNER (partner_name, contact_phone) VALUES 
(N'Giao Hàng Nhanh (GHN)', '19001201'),
(N'Viettel Post', '19008095'),
(N'Giao Hàng Tiết Kiệm (GHTK)', '18006092');

-- VOUCHER
INSERT INTO VOUCHER (code, discount_amount, min_order_value, valid_from, valid_to) VALUES 
('OECSHELLO', 500000.00, 10000000.00, '2026-01-01', '2026-12-31'),
('OECSVIP1M', 1000000.00, 25000000.00, '2026-01-01', '2026-12-31');

-- ORDER
INSERT INTO [ORDER] (user_id, address_id, shipping_partner_id, total_amount, shipping_fee) VALUES 
(3, 1, 1, 27530000.00, 40000.00),
(4, 3, 2, 29990000.00, 0.00);

-- ORDER_ITEM
INSERT INTO ORDER_ITEM (order_id, sku_id, price, quantity) VALUES 
(1, 1, 27990000.00, 1),
(2, 3, 29990000.00, 1);

-- ORDER_STATUS_HISTORY
INSERT INTO ORDER_STATUS_HISTORY (order_id, status) VALUES 
(1, N'Pending'),
(1, N'Shipping'),
(1, N'Completed'),
(2, N'Pending'),
(2, N'Shipping');

-- VOUCHER_USAGES
INSERT INTO VOUCHER_USAGES (voucher_id, order_id, user_id) VALUES 
(1, 1, 3);

-- COD_SETTLEMENTS
INSERT INTO COD_SETTLEMENTS (partner_id, total_cod_amount, status) VALUES 
(1, 27530000.00, N'COMPLETED'),
(2, 29990000.00, N'PENDING');

-- PRODUCT_REVIEWS
INSERT INTO PRODUCT_REVIEWS (user_id, order_item_id, sku_id, rating, comment) VALUES 
(3, 1, 1, 5, N'Hàng giao cực nhanh tại Cần Thơ, đóng gói cẩn thận, máy chuẩn mới 100%!'),
(4, 2, 3, 4, N'Điện thoại mượt, camera chụp đêm rất nét nhưng pin hơi nhanh tụt.');

-- SUPPLIERS
INSERT INTO SUPPLIERS (supplier_name, contact_email, phone, address) VALUES 
(N'Công ty TNHH Apple Việt Nam', 'supply@apple.com.vn', '02839999999', N'Quận 1, TP. Hồ Chí Minh'),
(N'Nhà phân phối Synnex FPT', 'contact@synnexfpt.com.vn', '02473006666', N'Quận Cầu Giấy, Hà Nội');

-- PURCHASE_ORDERS
INSERT INTO PURCHASE_ORDERS (supplier_id, total_cost) VALUES 
(1, 240000000.00),
(2, 180000000.00);

-- PURCHASE_ORDER_ITEMS
INSERT INTO PURCHASE_ORDER_ITEMS (po_id, sku_id, unit_cost, quantity) VALUES 
(1, 1, 24000000.00, 10),
(2, 4, 18000000.00, 10);
GO