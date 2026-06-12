USE CDC_DB2;
GO

IF OBJECT_ID(N'dbo.ExportCdcEvents', N'P') IS NULL
BEGIN
    EXEC('
        CREATE PROCEDURE dbo.ExportCdcEvents
        AS
        BEGIN
            SET NOCOUNT ON;
        END
    ');
END
GO

ALTER PROCEDURE dbo.ExportCdcEvents
(
    @SavedStartLsn BINARY(10)
)
AS
BEGIN
    SET NOCOUNT ON;

DECLARE @FromLsn       BINARY(10) = sys.fn_cdc_increment_lsn(@SavedStartLsn);
DECLARE @ToLsn         BINARY(10) = sys.fn_cdc_get_max_lsn();

DECLARE @FromLsnText VARCHAR(50) = CONVERT(VARCHAR(50), @FromLsn, 1);
DECLARE @ToLsnText   VARCHAR(50) = CONVERT(VARCHAR(50), @ToLsn, 1);

DROP TABLE IF EXISTS #TrackedTables;
DROP TABLE IF EXISTS #CdcEvents;

CREATE TABLE #CdcEvents
(
    EventId        INT IDENTITY(1,1) PRIMARY KEY,
    SchemaName     SYSNAME NOT NULL,
    TableName      SYSNAME NOT NULL,
    RecordDataJson NVARCHAR(MAX) NOT NULL,
    RowDataJson    NVARCHAR(MAX) NULL,
    OperationCode  INT NOT NULL,
    StartLsn       BINARY(10) NOT NULL,
    SeqVal         BINARY(10) NOT NULL
);

SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    ct.capture_instance AS CaptureInstance
INTO #TrackedTables
FROM cdc.change_tables ct
JOIN sys.tables t
    ON ct.source_object_id = t.object_id
JOIN sys.schemas s
    ON t.schema_id = s.schema_id;

DECLARE
    @SchemaName SYSNAME,
    @TableName SYSNAME,
    @CaptureInstance SYSNAME,
    @Sql NVARCHAR(MAX);

DECLARE table_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT SchemaName, TableName, CaptureInstance
FROM #TrackedTables;

OPEN table_cursor;

FETCH NEXT FROM table_cursor
INTO @SchemaName, @TableName, @CaptureInstance;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @Sql = N'
        INSERT INTO #CdcEvents
        (
            SchemaName,
            TableName,
            RecordDataJson,
            OperationCode,
            StartLsn,
            SeqVal
        )
        SELECT
            N''' + REPLACE(@SchemaName, '''', '''''') + N''',
            N''' + REPLACE(@TableName, '''', '''''') + N''',
            (
                SELECT src.*
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            ),
            src.__$operation,
            src.__$start_lsn,
            src.__$seqval
        FROM cdc.fn_cdc_get_all_changes_' + @CaptureInstance + N'
        (
            ' + @FromLsnText + N',
            ' + @ToLsnText + N',
            ''all''
        ) AS src
        WHERE src.__$operation IN (1, 2, 4);
    ';

    EXEC sys.sp_executesql @Sql;

    FETCH NEXT FROM table_cursor
    INTO @SchemaName, @TableName, @CaptureInstance;
END;

CLOSE table_cursor;
DEALLOCATE table_cursor;

SELECT
    EventId,
    SchemaName,
    TableName,
    OperationCode,
    CASE OperationCode
        WHEN 1 THEN 'DELETE'
        WHEN 2 THEN 'INSERT'
        WHEN 4 THEN 'UPDATE'
    END AS OperationName,
    CONVERT(VARCHAR(50), StartLsn, 1) AS StartLsn,
    CONVERT(VARCHAR(50), SeqVal, 1) AS SeqVal,
    RecordDataJson
    into #CdcEvents_Ordered
FROM #CdcEvents
ORDER BY StartLsn, SeqVal, EventId;

select * from #CdcEvents_Ordered
drop table #CdcEvents_Ordered
END
GO