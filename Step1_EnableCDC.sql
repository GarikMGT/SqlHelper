--1. Ensure SQL Server Agent (...)    Running

USE master;
GO

SELECT 
    servicename,
    status_desc
FROM sys.dm_server_services
WHERE servicename LIKE N'SQL Server Agent%';
GO

--Result should be -> Running NOT STOPPED.
--If it is not running, start SQL Server Agent from SQL Server Configuration Manager or SSMS.

--2. Enable CDC on the database

USE CDC_DB2;
GO

EXEC sys.sp_cdc_enable_db;
GO

--check
SELECT 
    name,
    is_cdc_enabled
FROM sys.databases
WHERE name = N'CDC_DB2';
GO

--Expected result:
--name       is_cdc_enabled
--CDC_DB2    1

--3. Enable CDC on the two tables
USE CDC_DB2;
GO

EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Customer',
    @role_name = NULL,
    @supports_net_changes = 1;
GO

EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'CustomerOrder',
    @role_name = NULL,
    @supports_net_changes = 1;
GO

--4. Verify table tracking

USE CDC_DB2;
GO

SELECT 
    name,
    is_tracked_by_cdc
FROM sys.tables
WHERE name IN (N'Customer', N'CustomerOrder');
GO

--Expected:
--Customer         1
--CustomerOrder    1

EXEC sys.sp_cdc_help_change_data_capture;
GO

--You should see rows for:
--dbo_Customer
--dbo_CustomerOrder