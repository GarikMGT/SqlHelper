USE CDC_DB2;
GO

DECLARE @StartLsn BINARY(10);

SET @StartLsn = sys.fn_cdc_get_max_lsn();

IF @StartLsn IS NULL
BEGIN
    THROW 50000, 'StartLSN is NULL. Check that CDC is enabled on CDC_DB2 and SQL Server Agent is running.', 1;
END;

SELECT 
    CONVERT(VARCHAR(50), @StartLsn, 1) AS StartLsn;
GO

--You should get something like:
--StartLsn
--0x0000002A000001B80003


--0x0000002B00000CD00001  --my real example
--Copy that value somewhere. This is the point before your DB2 changes start.