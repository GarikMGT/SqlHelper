USE CDC_DB1;
GO

DECLARE @Now DATETIME2 = SYSDATETIME();

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.Customer
    WHERE CustomerId = 5
)
BEGIN
    INSERT INTO dbo.Customer
        (CustomerId, CustomerName, City, ModifiedDate)
    VALUES
        (5, N'Narek', N'Ashtarak', @Now);
END;

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.CustomerOrder
    WHERE OrderId = 105
)
BEGIN
    INSERT INTO dbo.CustomerOrder
        (OrderId, CustomerId, OrderAmount, OrderStatus, ModifiedDate)
    VALUES
        (105, 5, 450.00, N'Open', @Now);
END;
GO

SELECT *
FROM dbo.Customer
ORDER BY CustomerId;

SELECT *
FROM dbo.CustomerOrder
ORDER BY OrderId;

USE CDC_DB1;
GO

DECLARE @Now DATETIME2 = SYSDATETIME();

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.Customer
    WHERE CustomerId = 4
)
BEGIN
    INSERT INTO dbo.Customer
        (CustomerId, CustomerName, City, ModifiedDate)
    VALUES
        (4, N'Arman_DB1', N'Yerevan', @Now);
END;

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.CustomerOrder
    WHERE OrderId = 106
)
BEGIN
    INSERT INTO dbo.CustomerOrder
        (OrderId, CustomerId, OrderAmount, OrderStatus, ModifiedDate)
    VALUES
        (106, 4, 999.00, N'Open', @Now);
END;
GO

SELECT *
FROM dbo.Customer
ORDER BY CustomerId;

SELECT *
FROM dbo.CustomerOrder
ORDER BY OrderId;