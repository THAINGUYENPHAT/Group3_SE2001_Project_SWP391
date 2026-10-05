-- ================================================================
-- HUONG DAN NHOM TRUONG:
-- [BAT DAU PHAN TAM BO SUNG] / [KET THUC PHAN TAM BO SUNG]
-- PHAN DUOC DANH DAU: Order / Payment truoc day + is_deleted ADDRESSBOOK moi.
-- CHI BO SUNG is_deleted SO VOI FILE FULL DA GUI TRUOC.
-- CAC BANG CON LAI DUOC GIU NGUYEN TU FILE FULL TRUOC DO.
-- LUU Y: VoucherDAO moi dang dung cot khac voi schema VOUCHER trong file.
-- KHONG TU Y SUA VOUCHER CUA NHOM KHI CHUA CO SCHEMA MOI.
-- DAY LA FILE FULL: CO LENH DROP DATABASE OECS O PHAN DAU.
-- CHI CHAY DE TAO LAI DB TEST, KHONG CHAY LEN DB CAN GIU DU LIEU.
-- ================================================================

/* ================================================================
   OECS - FULL SCHEMA + SEED DATA + ORDER / PAYMENT EXTENSIONS
   Source: DB_OECS(2).sql + Order/Payment upgrade.
   CANH BAO: SCRIPT NAY XOA TOAN BO DATABASE OECS NEU DA TON TAI.
   CHI CHAY KHI MUON TAO LAI DATABASE TEST TU DAU.
   NEU CAN GIU DU LIEU HIEN TAI, DUNG FILE MIGRATION RIENG.
   ================================================================ */

-- ========================================================
-- 1. TAO LAI DATABASE TU DAU (CHI DUNG CHO MOI TRUONG DEMO)
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
    -- >>> [BAT DAU PHAN TAM BO SUNG 4/4] SOFT DELETE ADDRESSBOOK
    -- 0 = dang su dung; 1 = an khoi danh sach checkout
    is_deleted BIT NOT NULL CONSTRAINT DF_ADDRESSBOOK_is_deleted DEFAULT (0),
    -- <<< [KET THUC PHAN TAM BO SUNG 4/4]
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

    min_order_value DECIMAL(18,2)
        NOT NULL
        CONSTRAINT DF_Voucher_MinOrder DEFAULT 0,

    valid_from DATETIME2 NOT NULL,
    valid_to DATETIME2 NOT NULL,

    discount_type VARCHAR(20) NOT NULL,

    discount_value DECIMAL(18,2) NOT NULL,

    max_discount DECIMAL(18,2) NULL,

    usage_limit INT NULL,

    per_user_limit INT NULL,

    CONSTRAINT CK_Voucher_DiscountType
        CHECK (discount_type IN ('AMOUNT', 'PERCENT')),

    CONSTRAINT CK_Voucher_DiscountValue
        CHECK (discount_value > 0),

    CONSTRAINT CK_Voucher_MinOrder
        CHECK (min_order_value >= 0),

    CONSTRAINT CK_Voucher_ValidDate
        CHECK (valid_to > valid_from),

    CONSTRAINT CK_Voucher_MaxDiscount
        CHECK (
            max_discount IS NULL
            OR max_discount > 0
        ),

    CONSTRAINT CK_Voucher_UsageLimit
        CHECK (
            usage_limit IS NULL
            OR usage_limit > 0
        ),

    CONSTRAINT CK_Voucher_PerUserLimit
        CHECK (
            per_user_limit IS NULL
            OR per_user_limit > 0
        ),

    CONSTRAINT CK_Voucher_PerUserVsTotal
        CHECK (
            usage_limit IS NULL
            OR per_user_limit IS NULL
            OR per_user_limit <= usage_limit
        ),

    CONSTRAINT CK_Voucher_MaxDiscountType
        CHECK (
            discount_type = 'PERCENT'
            OR max_discount IS NULL
        )
);

CREATE TABLE [ORDER] (
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    address_id INT NOT NULL,
    shipping_partner_id INT,
    total_amount DECIMAL(18,2) NOT NULL,
    shipping_fee DECIMAL(18,2) DEFAULT 0,
    created_at DATETIME2 DEFAULT GETDATE(),
    -- >>> [BAT DAU PHAN TAM BO SUNG 1/4] COT MOI TRONG BANG [ORDER]
    -- Phuc vu Checkout, thanh toan online, tracking va hoan kho
    order_status VARCHAR(30) NULL,
    payment_method VARCHAR(20) NULL,
    payment_status VARCHAR(30) NULL,
    payment_expires_at DATETIME2 NULL,
    recipient_name NVARCHAR(100) NULL,
    recipient_phone VARCHAR(20) NULL,
    shipping_address NVARCHAR(MAX) NULL,
    discount_amount DECIMAL(18,2) NULL,
    stock_restored_at DATETIME2 NULL,
    -- <<< [KET THUC PHAN TAM BO SUNG 1/4]

    -- >>> [BAT DAU PHAN TAM BO SUNG: CHONG TRUNG ORDER]
    -- Moi lan Checkout se co 1 token duy nhat. Database dung token nay de chan tao nhieu don cung mot lan Checkout.
    -- De NULL de khong anh huong cac don hang cu / seed data hien tai.
    checkout_token VARCHAR(64) NULL,
    -- <<< [KET THUC PHAN TAM BO SUNG: CHONG TRUNG ORDER]
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
-- >>> [BAT DAU PHAN TAM BO SUNG 2/4] BANG / INDEX PAYMENT
-- PAYMENT_TRANSACTION: luu tung lan thu thanh toan VNPAY / MOMO
-- PAYMENT_REFUND: luu yeu cau va trang thai hoan tien
-- Hai INDEX phuc vu tra cuu giao dich va don het han thanh toan
-- 7. PAYMENT GATEWAY (VNPAY / MOMO)
CREATE TABLE PAYMENT_TRANSACTION (
    transaction_id BIGINT IDENTITY(1,1) CONSTRAINT PK_PAYMENT_TRANSACTION PRIMARY KEY,
    order_id INT NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    amount DECIMAL(18,2) NOT NULL,
    transaction_code VARCHAR(100) NOT NULL,
    provider_transaction_id VARCHAR(150) NULL,
    status VARCHAR(30) NOT NULL CONSTRAINT DF_PaymentTransaction_Status DEFAULT 'PENDING',
    provider_response_code VARCHAR(100) NULL,
    created_at DATETIME2 NOT NULL CONSTRAINT DF_PaymentTransaction_Created DEFAULT SYSUTCDATETIME(),
    completed_at DATETIME2 NULL,
    CONSTRAINT FK_PaymentTransaction_Order FOREIGN KEY (order_id) REFERENCES [ORDER](order_id),
    CONSTRAINT UQ_PaymentTransaction_Code UNIQUE (transaction_code),
    CONSTRAINT CK_PaymentTransaction_Method CHECK (payment_method IN ('VNPAY','MOMO')),
    CONSTRAINT CK_PaymentTransaction_Amount CHECK (amount >= 0),
    CONSTRAINT CK_PaymentTransaction_Status CHECK (status IN ('PENDING','SUCCESS','FAILED','CANCELLED','EXPIRED'))
);

CREATE TABLE PAYMENT_REFUND (
    refund_id BIGINT IDENTITY(1,1) CONSTRAINT PK_PAYMENT_REFUND PRIMARY KEY,
    transaction_id BIGINT NOT NULL,
    refund_amount DECIMAL(18,2) NOT NULL,
    refund_status VARCHAR(30) NOT NULL CONSTRAINT DF_PaymentRefund_Status DEFAULT 'PENDING',
    provider_refund_id VARCHAR(150) NULL,
    reason NVARCHAR(500) NULL,
    requested_at DATETIME2 NOT NULL CONSTRAINT DF_PaymentRefund_Requested DEFAULT SYSUTCDATETIME(),
    completed_at DATETIME2 NULL,
    CONSTRAINT FK_PaymentRefund_Transaction FOREIGN KEY (transaction_id) REFERENCES PAYMENT_TRANSACTION(transaction_id),
    CONSTRAINT CK_PaymentRefund_Amount CHECK (refund_amount > 0),
    CONSTRAINT CK_PaymentRefund_Status CHECK (refund_status IN ('PENDING','PROCESSING','SUCCESS','FAILED'))
);

CREATE INDEX IX_PaymentTransaction_Order ON PAYMENT_TRANSACTION(order_id, created_at DESC);
CREATE INDEX IX_Order_Expiry ON [ORDER](order_status, payment_expires_at);

-- >>> [BAT DAU PHAN TAM BO SUNG: UNIQUE CHECKOUT TOKEN]
-- Bao dam 1 checkout_token chi tao duoc toi da 1 ORDER.
-- Filter WHERE checkout_token IS NOT NULL giup cac Order cu co token NULL van hop le.
CREATE UNIQUE INDEX UX_Order_CheckoutToken
ON dbo.[ORDER](checkout_token)
WHERE checkout_token IS NOT NULL;
-- <<< [KET THUC PHAN TAM BO SUNG: UNIQUE CHECKOUT TOKEN]
-- <<< [KET THUC PHAN TAM BO SUNG 2/4]
GO

-- ========================================================
-- III. CHÈN DỮ LIỆU MẪU (SEED DATA)
-- ========================================================

-- ROLES
INSERT INTO ROLES (role_name, description) VALUES 
(N'ADMIN', N'Quản trị viên hệ thống - Toàn quyền'),
(N'STAFF', N'Nhân viên vận hành và xử lý đơn hàng'),
(N'CUSTOMER', N'Khách hàng mua sắm'),
(N'GUEST', N'Khách truy cập chưa đăng nhập');

-- USER
INSERT INTO [USER] (username, email, password_hash, phone) VALUES 
('admin', 'admin@oecs.com', 'e10adc3949ba59abbe56e057f20f883e', '0901111111'),
('staff', 'khang.staff@oecs.com', 'e10adc3949ba59abbe56e057f20f883e', '0902222222'),
('user', 'phat.user@gmail.com', 'e10adc3949ba59abbe56e057f20f883e', '0903333333'),
('customer', 'lan.nguyen@gmail.com', 'e10adc3949ba59abbe56e057f20f883e', '0904444444');

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
-- Danh mục cha
(N'Điện thoại & Thiết bị di động', NULL),
(N'Máy tính & Laptop', NULL),
(N'Phụ kiện', NULL),

-- Danh mục con của Điện thoại & Thiết bị di động
(N'Smartphone', 1),
(N'Tai nghe', 1),
(N'Sạc điện thoại', 1),
(N'Cáp sạc', 1),

-- Danh mục con của Máy tính & Laptop
(N'Laptop Văn Phòng', 2),
(N'Laptop Gaming', 2),

-- Danh mục con của Phụ kiện
(N'Chuột', 3),
(N'Bàn phím', 3),
(N'Webcam', 3),
(N'Balo Laptop', 3);          

-- BRAND
INSERT INTO BRAND (brand_name, logo_url) VALUES 
(N'Apple', 'https://cdn.oecs.com/brands/apple.png'),
(N'Samsung', 'https://cdn.oecs.com/brands/samsung.png'),
(N'Lenovo', 'https://cdn.oecs.com/brands/lenovo.png'),
(N'Logitech', 'https://cdn.oecs.com/brands/logitech.png'),
(N'Sony', 'https://cdn.oecs.com/brands/sony.png'),
(N'JBL', 'https://cdn.oecs.com/brands/jbl.png'),
(N'ASUS', 'https://cdn.oecs.com/brands/asus.png'),
(N'HP', 'https://cdn.oecs.com/brands/hp.png'),
(N'Dell', 'https://cdn.oecs.com/brands/dell.png'),
(N'Razer', 'https://cdn.oecs.com/brands/razer.png'),
(N'Anker', 'https://cdn.oecs.com/brands/anker.png');

-- PRODUCT
INSERT INTO PRODUCT (category_id, brand_id, product_name, description) VALUES 

-- ========================================================
-- SMARTPHONE
-- category_id = 4
-- ========================================================
(4, 1, N'iPhone 15 Pro', 
 N'Điện thoại flagship cao cấp vỏ Titan từ Apple'),

(4, 1, N'iPhone 15 Pro Max', 
 N'Điện thoại flagship màn hình lớn, camera chuyên nghiệp'),

(4, 1, N'iPhone 16 Pro', 
 N'Điện thoại cao cấp với chip Apple A18 Pro'),

(4, 1, N'iPhone 16 Pro Max', 
 N'Flagship cao cấp nhất của Apple với màn hình lớn'),

(4, 2, N'Samsung Galaxy S24 Ultra', 
 N'Điện thoại cao cấp tích hợp Galaxy AI'),

(4, 2, N'Samsung Galaxy S24 Plus', 
 N'Smartphone cao cấp với màn hình Dynamic AMOLED'),

(4, 2, N'Samsung Galaxy A55 5G', 
 N'Smartphone tầm trung hỗ trợ kết nối 5G'),

(4, 2, N'Samsung Galaxy A35 5G', 
 N'Smartphone tầm trung thiết kế hiện đại'),

-- ========================================================
-- TAI NGHE
-- category_id = 5
-- ========================================================
(5, 1, N'AirPods Pro 2', 
 N'Tai nghe không dây cao cấp với chống ồn chủ động'),

(5, 1, N'AirPods 4', 
 N'Tai nghe không dây nhỏ gọn dành cho hệ sinh thái Apple'),

(5, 2, N'Samsung Galaxy Buds3 Pro', 
 N'Tai nghe true wireless cao cấp với chống ồn chủ động'),

(5, 2, N'Samsung Galaxy Buds FE', 
 N'Tai nghe không dây giá tốt cho người dùng Samsung'),

-- ========================================================
-- SẠC ĐIỆN THOẠI
-- category_id = 6
-- ========================================================
(6, 1, N'Apple USB-C 20W Power Adapter', 
 N'Củ sạc nhanh USB-C công suất 20W'),

(6, 2, N'Samsung 25W USB-C Fast Charger', 
 N'Củ sạc nhanh USB-C 25W của Samsung'),

-- ========================================================
-- CÁP SẠC
-- category_id = 7
-- ========================================================
(7, 1, N'Apple USB-C Charge Cable 1m', 
 N'Cáp USB-C chính hãng Apple dài 1 mét'),

(7, 1, N'Apple USB-C to Lightning Cable', 
 N'Cáp chuyển USB-C sang Lightning'),

(7, 2, N'Samsung USB-C Cable 1m', 
 N'Cáp sạc và truyền dữ liệu USB-C'),

-- ========================================================
-- LAPTOP VĂN PHÒNG
-- category_id = 8
-- ========================================================
(8, 3, N'Lenovo IdeaPad Slim 3', 
 N'Laptop văn phòng mỏng nhẹ dành cho học tập và làm việc'),

(8, 3, N'Lenovo ThinkBook 14', 
 N'Laptop doanh nghiệp với thiết kế hiện đại'),

(8, 3, N'Lenovo IdeaPad 5', 
 N'Laptop đa dụng cho học tập và văn phòng'),

-- ========================================================
-- LAPTOP GAMING
-- category_id = 9
-- ========================================================
(9, 3, N'Lenovo LOQ 15', 
 N'Laptop gaming hiệu năng cao trong tầm giá'),

(9, 3, N'Lenovo Legion 5', 
 N'Laptop gaming cao cấp dành cho chơi game và đồ họa'),

(9, 3, N'Lenovo Legion Pro 5', 
 N'Laptop gaming hiệu năng cao dành cho game thủ'),

-- ========================================================
-- CHUỘT
-- category_id = 10
-- ========================================================
(10, 3, N'Lenovo Legion M300 RGB', 
 N'Chuột gaming có đèn RGB và thiết kế công thái học'),

(10, 3, N'Lenovo Legion M600 Wireless', 
 N'Chuột gaming không dây với độ chính xác cao'),

-- ========================================================
-- BÀN PHÍM
-- category_id = 11
-- ========================================================
(11, 3, N'Lenovo Legion K300 RGB', 
 N'Bàn phím gaming có đèn RGB'),

(11, 3, N'Lenovo Go Wireless Split Keyboard', 
 N'Bàn phím không dây dành cho công việc văn phòng'),

-- ========================================================
-- WEBCAM
-- category_id = 12
-- ========================================================
(12, 3, N'Lenovo 300 FHD Webcam', 
 N'Webcam Full HD dành cho học tập và họp trực tuyến'),

(12, 3, N'Lenovo Performance FHD Webcam', 
 N'Webcam Full HD với chất lượng hình ảnh cao'),

-- ========================================================
-- BALO LAPTOP
-- category_id = 13
-- ========================================================
(13, 3, N'Lenovo Laptop Backpack 15.6"', 
 N'Balo laptop chống nước dành cho laptop 15.6 inch'),

(13, 3, N'Lenovo Legion Gaming Backpack', 
 N'Balo gaming dành cho laptop và phụ kiện');

INSERT INTO ATTRIBUTE (attribute_name) VALUES 
(N'Màn hình'),
(N'RAM'),
(N'Dung lượng lưu trữ'),
(N'Chip xử lý (CPU)'),
(N'Card đồ họa (GPU)'),
(N'Hệ điều hành'),
(N'Pin'),
(N'Kết nối'),
(N'Tính năng'),
(N'Màu sắc'),
(N'Kích thước'),
(N'Trọng lượng'),
(N'Độ phân giải'),
(N'DPI'),
(N'Loại kết nối');

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
-- VOUCHER
INSERT INTO VOUCHER (
    code,
    min_order_value,
    valid_from,
    valid_to,
    discount_type,
    discount_value,
    max_discount,
    usage_limit,
    per_user_limit
)
VALUES
(
    'OECSHELLO',
    10000000.00,
    '2026-01-01 00:00:00',
    '2026-12-31 23:59:59',
    'AMOUNT',
    500000.00,
    NULL,
    100,
    1
),
(
    'OECSVIP20',
    25000000.00,
    '2026-01-01 00:00:00',
    '2026-12-31 23:59:59',
    'PERCENT',
    20.00,
    1000000.00,
    50,
    1
),
(
    'TECH10',
    5000000.00,
    '2026-01-01 00:00:00',
    '2026-12-31 23:59:59',
    'PERCENT',
    10.00,
    500000.00,
    200,
    2
),
(
    'SAVE200K',
    3000000.00,
    '2026-01-01 00:00:00',
    '2026-12-31 23:59:59',
    'AMOUNT',
    200000.00,
    NULL,
    NULL,
    1
);

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

-- >>> [BAT DAU PHAN TAM BO SUNG 3/4] BO SUNG DU LIEU CHO DON HANG MAU
-- Dien snapshot thong tin giao hang va status tu cac dong ORDER_STATUS_HISTORY cu
-- payment_status = UNKNOWN do du lieu mau cu khong co bang chung thanh toan
-- CAP NHAT DON HANG MAU TU LICH SU VA SO DIA CHI
UPDATE o SET recipient_name=a.recipient_name,
             recipient_phone=a.phone_number,
             shipping_address=a.address_line,
             payment_status='UNKNOWN'
FROM dbo.[ORDER] o
JOIN dbo.ADDRESSBOOK a ON a.address_id=o.address_id;

;WITH latest AS (
    SELECT order_id, status,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY updated_at DESC,status_id DESC) rn
    FROM dbo.ORDER_STATUS_HISTORY
)
UPDATE o SET order_status=CASE UPPER(l.status)
   WHEN 'PENDING' THEN 'PENDING_CONFIRMATION'
   WHEN 'SHIPPING' THEN 'SHIPPING'
   WHEN 'COMPLETED' THEN 'COMPLETED'
   WHEN 'CONFIRMED' THEN 'CONFIRMED'
   WHEN 'CANCELLED' THEN 'CANCELLED'
   ELSE 'PENDING_CONFIRMATION' END
FROM dbo.[ORDER] o
JOIN latest l ON l.order_id=o.order_id AND l.rn=1;
-- <<< [KET THUC PHAN TAM BO SUNG 3/4]
GO
