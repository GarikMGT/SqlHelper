--Read table 1

USE CDC_DB2;
GO

DECLARE @SavedStartLsn BINARY(10) = 0x0000002B00000CD00001;
DECLARE @FromLsn       BINARY(10);
DECLARE @ToLsn         BINARY(10);

SET @FromLsn = sys.fn_cdc_increment_lsn(@SavedStartLsn);
SET @ToLsn   = sys.fn_cdc_get_max_lsn();

SELECT
    CONVERT(VARCHAR(50), @SavedStartLsn, 1) AS SavedStartLsn,
    CONVERT(VARCHAR(50), @FromLsn, 1)       AS FromLsn,
    CONVERT(VARCHAR(50), @ToLsn, 1)         AS ToLsn;

SELECT
    CONVERT(VARCHAR(50), __$start_lsn, 1) AS StartLsn,
    CONVERT(VARCHAR(50), __$seqval, 1)    AS SeqVal,
    __$operation,
    CASE __$operation
        WHEN 1 THEN 'DELETE'
        WHEN 2 THEN 'INSERT'
        WHEN 3 THEN 'UPDATE - OLD VALUES'
        WHEN 4 THEN 'UPDATE - NEW VALUES'
    END AS OperationName,
    CustomerId,
    CustomerName,
    City,
    ModifiedDate
FROM cdc.fn_cdc_get_all_changes_dbo_Customer
(
    @FromLsn,
    @ToLsn,
    'all' --For updates, using 'all' returns only the new row values after the update. The option 'all update old' would return both old and new values for updates
)
ORDER BY
    __$start_lsn,
    __$seqval,
    __$operation;
GO

--read table 2

USE CDC_DB2;
GO

DECLARE @SavedStartLsn BINARY(10) = 0x0000002B00000CD00001;
DECLARE @FromLsn       BINARY(10) = sys.fn_cdc_increment_lsn(@SavedStartLsn);
DECLARE @ToLsn         BINARY(10) = sys.fn_cdc_get_max_lsn();

SELECT
    CONVERT(VARCHAR(50), __$start_lsn, 1) AS StartLsn,
    CONVERT(VARCHAR(50), __$seqval, 1)    AS SeqVal,
    __$operation,
    CASE __$operation
        WHEN 1 THEN 'DELETE'
        WHEN 2 THEN 'INSERT'
        WHEN 3 THEN 'UPDATE - OLD VALUES'
        WHEN 4 THEN 'UPDATE - NEW VALUES'
    END AS OperationName,
    OrderId,
    CustomerId,
    OrderAmount,
    OrderStatus,
    ModifiedDate
FROM cdc.fn_cdc_get_all_changes_dbo_CustomerOrder
(
    @FromLsn,
    @ToLsn,
    'all update old' --For updates, using 'all' returns only the new row values after the update. The option 'all update old' would return both old and new values for updates
)
ORDER BY
    __$start_lsn,
    __$seqval,
    __$operation;
GO