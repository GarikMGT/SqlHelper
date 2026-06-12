USE master;
GO

IF DB_ID(N'CDC_DB1') IS NOT NULL OR DB_ID(N'CDC_DB2') IS NOT NULL
BEGIN
    THROW 50000, 'CDC_DB1 or CDC_DB2 already exists. Rename or drop them manually before running this script.', 1;
END;
GO

CREATE DATABASE CDC_DB1;
CREATE DATABASE CDC_DB2;
GO

USE CDC_DB1;
GO

CREATE TABLE dbo.Customer
(
    CustomerId   INT NOT NULL PRIMARY KEY,
    CustomerName NVARCHAR(100) NOT NULL,
    City         NVARCHAR(100) NOT NULL,
    ModifiedDate DATETIME2 NOT NULL
);

CREATE TABLE dbo.CustomerOrder
(
    OrderId      INT NOT NULL PRIMARY KEY,
    CustomerId   INT NOT NULL,
    OrderAmount  DECIMAL(10,2) NOT NULL,
    OrderStatus  NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME2 NOT NULL,

    CONSTRAINT FK_CustomerOrder_Customer
        FOREIGN KEY (CustomerId)
        REFERENCES dbo.Customer(CustomerId)
);
GO

INSERT INTO dbo.Customer
    (CustomerId, CustomerName, City, ModifiedDate)
VALUES
    (1, N'Anna',  N'Yerevan', '2026-06-01T10:00:00'),
    (2, N'David', N'Gyumri',  '2026-06-01T10:00:00'),
    (3, N'Mariam', N'Vanadzor', '2026-06-01T10:00:00');

INSERT INTO dbo.CustomerOrder
    (OrderId, CustomerId, OrderAmount, OrderStatus, ModifiedDate)
VALUES
    (101, 1, 100.00, N'Open',   '2026-06-01T10:00:00'),
    (102, 2, 250.00, N'Open',   '2026-06-01T10:00:00'),
    (103, 3, 300.00, N'Closed', '2026-06-01T10:00:00');
GO

USE CDC_DB2;
GO

CREATE TABLE dbo.Customer
(
    CustomerId   INT NOT NULL PRIMARY KEY,
    CustomerName NVARCHAR(100) NOT NULL,
    City         NVARCHAR(100) NOT NULL,
    ModifiedDate DATETIME2 NOT NULL
);

CREATE TABLE dbo.CustomerOrder
(
    OrderId      INT NOT NULL PRIMARY KEY,
    CustomerId   INT NOT NULL,
    OrderAmount  DECIMAL(10,2) NOT NULL,
    OrderStatus  NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME2 NOT NULL,

    CONSTRAINT FK_CustomerOrder_Customer
        FOREIGN KEY (CustomerId)
        REFERENCES dbo.Customer(CustomerId)
);
GO

INSERT INTO dbo.Customer
    (CustomerId, CustomerName, City, ModifiedDate)
VALUES
    (1, N'Anna',  N'Yerevan', '2026-06-01T10:00:00'),
    (2, N'David', N'Gyumri',  '2026-06-01T10:00:00'),
    (3, N'Mariam', N'Vanadzor', '2026-06-01T10:00:00');

INSERT INTO dbo.CustomerOrder
    (OrderId, CustomerId, OrderAmount, OrderStatus, ModifiedDate)
VALUES
    (101, 1, 100.00, N'Open',   '2026-06-01T10:00:00'),
    (102, 2, 250.00, N'Open',   '2026-06-01T10:00:00'),
    (103, 3, 300.00, N'Closed', '2026-06-01T10:00:00');
GO