-- Run once against an EXISTING database made by the checkout-deduction version.
-- Stop the old application, run this batch, then deploy the staff-confirmation version.
-- Fresh DB_OECS.sql installations do not need this migration.
-- checkout_token identifies orders created by checkout; sample/manual orders have no
-- reliable stock movement history and are intentionally excluded.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM dbo.AUDIT_LOG WITH (TABLOCKX, HOLDLOCK)
               WHERE action = 'STOCK_CONFIRMATION_MIGRATION' AND entity_type = 'DATABASE')
    BEGIN
        COMMIT;
        RETURN;
    END;

    DECLARE @Orders TABLE (order_id INT PRIMARY KEY);
    INSERT INTO @Orders (order_id)
    SELECT order_id FROM dbo.[ORDER] WITH (TABLOCKX, HOLDLOCK)
    WHERE UPPER(LTRIM(RTRIM(order_status))) IN ('PENDING', 'PENDING_CONFIRMATION', 'PENDING_PAYMENT')
      AND checkout_token IS NOT NULL AND stock_restored_at IS NULL;

    IF EXISTS (SELECT 1 FROM @Orders o
               WHERE NOT EXISTS (SELECT 1 FROM dbo.ORDER_ITEM i WHERE i.order_id = o.order_id))
        THROW 51000, 'A legacy checkout order has no items. Reconcile it before migration.', 1;
    IF EXISTS (SELECT 1 FROM dbo.ORDER_ITEM i JOIN @Orders o ON o.order_id = i.order_id
               WHERE i.quantity <= 0)
        THROW 51000, 'A legacy checkout order has invalid quantities.', 1;

    UPDATE s SET stock_quantity = s.stock_quantity + q.quantity
    FROM dbo.PRODUCT_SKU s
    JOIN (SELECT i.sku_id, SUM(CAST(i.quantity AS bigint)) AS quantity
          FROM dbo.ORDER_ITEM i JOIN @Orders o ON o.order_id = i.order_id
          GROUP BY i.sku_id) q ON q.sku_id = s.sku_id;

    -- The order is still pending. Staff confirmation will deduct it under the new rule.
    INSERT INTO dbo.AUDIT_LOG (actor_identifier, action, entity_type, description)
    SELECT 'inventory-migration', 'STOCK_CONFIRMATION_MIGRATION', 'DATABASE',
           CONCAT(N'Released legacy checkout stock for ', COUNT(*), N' pending orders before staff-confirmation deployment.')
    FROM @Orders;
    SELECT order_id AS migrated_pending_order FROM @Orders ORDER BY order_id;
    COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
END CATCH;
