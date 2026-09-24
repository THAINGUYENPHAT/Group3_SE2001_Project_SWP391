-- ========================================================
-- TẠO DATABASE (NẾU CHƯA CÓ)
-- ========================================================
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'OECS')
BEGIN
    CREATE DATABASE OECS;
END
GO

USE OECS;
GO

-- ========================================================
-- DROP CÁC BẢNG NẾU ĐÃ TỒN TẠI (XÓA THEO THỨ TỰ TỪ CON LÊN CHA)
-- ========================================================
DROP TABLE IF EXISTS PURCHASE_ORDER_ITEMS;
DROP TABLE IF EXISTS PURCHASE_ORDERS;
DROP TABLE IF EXISTS SUPPLIERS;
DROP TABLE IF EXISTS PRODUCT_REVIEWS;
DROP TABLE IF EXISTS COD_SETTLEMENTS;
DROP TABLE IF EXISTS VOUCHER_USAGES;
DROP TABLE IF EXISTS ORDER_STATUS_HISTORY;
DROP TABLE IF EXISTS ORDER_ITEM;
DROP TABLE IF EXISTS [ORDER];
DROP TABLE IF EXISTS VOUCHER;
DROP TABLE IF EXISTS SHIPPING_PARTNER;
DROP TABLE IF EXISTS CART_ITEMS;
DROP TABLE IF EXISTS CART;
DROP TABLE IF EXISTS PRODUCT_SKU;
DROP TABLE IF EXISTS PRODUCT_SPECIFICATION;
DROP TABLE IF EXISTS ATTRIBUTE;
DROP TABLE IF EXISTS PRODUCT;
DROP TABLE IF EXISTS BRAND;
-- Vì CATEGORY có khóa ngoại tự trỏ đến chính nó, xóa bình thường vẫn được do DROP TABLE sẽ gỡ luôn constraint
DROP TABLE IF EXISTS CATEGORY; 
DROP TABLE IF EXISTS ADDRESSBOOK;
DROP TABLE IF EXISTS STAFF;
DROP TABLE IF EXISTS USER_ROLES;
DROP TABLE IF EXISTS [USER];
DROP TABLE IF EXISTS ROLES;
GO

-- ========================================================
-- 1. QUẢN LÝ NGƯỜI DÙNG & PHÂN QUYỀN (USER & AUTH)
-- ========================================================

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

-- Bảng trung gian USER_ROLES (Mối quan hệ N-N giữa USER và ROLES)
CREATE TABLE USER_ROLES (
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT FK_UserRoles_User FOREIGN KEY (user_id) REFERENCES [USER](user_id) ON DELETE CASCADE,
    CONSTRAINT FK_UserRoles_Role FOREIGN KEY (role_id) REFERENCES ROLES(role_id) ON DELETE CASCADE
);

-- Thông tin nhân viên (STAFF)
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

-- ========================================================
-- 2. DANH MỤC, SẢN PHẨM & THUỘC TÍNH (PRODUCT CATALOG)
-- ========================================================

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
    attribute_name NVARCHAR(100) NOT NULL -- Ví dụ: Màn hình, RAM, Dung lượng
);

-- Thuộc tính/Thông số kỹ thuật chi tiết của sản phẩm (PRODUCT_SPECIFICATION)
CREATE TABLE PRODUCT_SPECIFICATION (
    product_id INT NOT NULL,
    attribute_id INT NOT NULL,
    value NVARCHAR(255) NOT NULL,
    PRIMARY KEY (product_id, attribute_id),
    CONSTRAINT FK_Spec_Product FOREIGN KEY (product_id) REFERENCES PRODUCT(product_id) ON DELETE CASCADE,
    CONSTRAINT FK_Spec_Attribute FOREIGN KEY (attribute_id) REFERENCES ATTRIBUTE(attribute_id) ON DELETE CASCADE
);

-- Mẫu sản phẩm cụ thể / biến thể sản phẩm (PRODUCT_SKU)
CREATE TABLE PRODUCT_SKU (
    sku_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT NOT NULL,
    sku_code VARCHAR(100) NOT NULL UNIQUE,
    price DECIMAL(18, 2) NOT NULL,
    stock_quantity INT DEFAULT 0,
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_SKU_Product FOREIGN KEY (product_id) REFERENCES PRODUCT(product_id) ON DELETE CASCADE
);

-- ========================================================
-- 3. GIỎ HÀNG (SHOPPING CART)
-- ========================================================

CREATE TABLE CART (
    cart_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL UNIQUE, -- Mỗi khách hàng có 1 giỏ hàng
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

-- ========================================================
-- 4. ĐƠN HÀNG, VẬN CHUYỂN & VOUCHER (ORDERS & SHIPPING)
-- ========================================================

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
    status NVARCHAR(50) NOT NULL, -- Pending, Shipping, Completed, Cancelled...
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_StatusHistory_Order FOREIGN KEY (order_id) REFERENCES [ORDER](order_id) ON DELETE CASCADE
);

-- Theo dõi lượt sử dụng Voucher (VOUCHER_USAGES)
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

-- Chốt trả tiền mặt (COD_SETTLEMENTS)
CREATE TABLE COD_SETTLEMENTS (
    settlement_id INT IDENTITY(1,1) PRIMARY KEY,
    partner_id INT NOT NULL,
    total_cod_amount DECIMAL(18, 2) NOT NULL,
    settlement_date DATETIME2 DEFAULT GETDATE(),
    status NVARCHAR(50) DEFAULT N'PENDING',
    CONSTRAINT FK_CODSettlement_Partner FOREIGN KEY (partner_id) REFERENCES SHIPPING_PARTNER(partner_id)
);

-- ========================================================
-- 5. ĐÁNH GIÁ SẢN PHẨM (REVIEWS)
-- ========================================================

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

-- ========================================================
-- 6. QUẢN LÝ NHẬP HÀNG (PURCHASE ORDERS)
-- ========================================================

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