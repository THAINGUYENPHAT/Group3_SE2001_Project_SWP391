-- Run on the existing OECS database before deploying the application.
USE OECS;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF OBJECT_ID('dbo.ORDER_CUSTOMER_POLICY','U') IS NULL
BEGIN
CREATE TABLE ORDER_CUSTOMER_POLICY (
    user_id INT NOT NULL PRIMARY KEY REFERENCES [USER](user_id),
    violation_count INT NOT NULL DEFAULT (0),
    blocked_until DATETIME2 NULL,
    CONSTRAINT CK_OrderCustomerPolicy_Count CHECK (violation_count BETWEEN 0 AND 3)
);
END;
IF OBJECT_ID('dbo.ORDER_CUSTOMER_CANCELLATION','U') IS NULL
BEGIN
CREATE TABLE ORDER_CUSTOMER_CANCELLATION (
    order_id INT NOT NULL PRIMARY KEY REFERENCES [ORDER](order_id),
    user_id INT NOT NULL REFERENCES [USER](user_id),
    quantity BIGINT NOT NULL CHECK (quantity > 0),
    cancelled_at DATETIME2 NOT NULL DEFAULT (SYSUTCDATETIME())
);
CREATE INDEX IX_OrderCustomerCancellation_UserTime
    ON ORDER_CUSTOMER_CANCELLATION(user_id, cancelled_at) INCLUDE (quantity);

END;
IF COL_LENGTH('dbo.PAYMENT_REFUND','processed_by') IS NULL
    ALTER TABLE dbo.PAYMENT_REFUND ADD processed_by INT NULL REFERENCES dbo.[USER](user_id);
IF COL_LENGTH('dbo.PAYMENT_REFUND','updated_at') IS NULL
    ALTER TABLE dbo.PAYMENT_REFUND ADD updated_at DATETIME2 NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.PAYMENT_REFUND') AND name = 'UX_Payment_Refund_Transaction')
    CREATE UNIQUE INDEX UX_Payment_Refund_Transaction ON dbo.PAYMENT_REFUND(transaction_id);
COMMIT;
GO
