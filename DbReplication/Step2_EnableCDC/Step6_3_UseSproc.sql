USE CDC_DB2;
GO

CREATE TABLE #temp
(
    EventId        BIGINT,
    SchemaName     SYSNAME NOT NULL,
    TableName      SYSNAME NOT NULL,
    OperationCode  INT NOT NULL,
    OperationName  NVARCHAR(50) NOT NULL,
    StartLsn       VARCHAR(50) NOT NULL,
    SeqVal         VARCHAR(50) NOT NULL,
    RecordDataJson NVARCHAR(MAX) NOT NULL
);

Insert into #temp
EXEC dbo.ExportCdcEvents @SavedStartLsn = 0x0000002B00000CD00001

select * from #temp

drop table #temp
