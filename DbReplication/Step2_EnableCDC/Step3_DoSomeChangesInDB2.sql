USE CDC_DB2;
GO

DECLARE @Now DATETIME2 = SYSDATETIME();

BEGIN TRANSACTION;

    -- 1. UPDATE existing customer
    UPDATE dbo.Customer
    SET
        City = N'Abovyan',
        ModifiedDate = @Now
    WHERE CustomerId = 1;

    -- 2. INSERT new customer
    INSERT INTO dbo.Customer
        (CustomerId, CustomerName, City, ModifiedDate)
    VALUES
        (4, N'Gor', N'Dilijan', @Now);

    -- 3. UPDATE existing order
    UPDATE dbo.CustomerOrder
    SET
        OrderAmount = 125.50,
        OrderStatus = N'Paid',
        ModifiedDate = @Now
    WHERE OrderId = 101;

    -- 4. DELETE existing order
    DELETE FROM dbo.CustomerOrder
    WHERE OrderId = 103;

    -- 5. INSERT new order for the new customer
    INSERT INTO dbo.CustomerOrder
        (OrderId, CustomerId, OrderAmount, OrderStatus, ModifiedDate)
    VALUES
        (104, 4, 80.00, N'Open', @Now);

COMMIT TRANSACTION;
GO