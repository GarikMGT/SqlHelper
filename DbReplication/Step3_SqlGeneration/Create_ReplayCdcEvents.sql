USE CDC_DB1;
GO

CREATE OR ALTER PROCEDURE dbo.ReplayCdcEvents
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID(N'tempdb..#CdcEvents') IS NULL
    BEGIN
        THROW 50000, '#CdcEvents temp table is required.', 1;
    END;

    DROP TABLE IF EXISTS #IdMapping;

    CREATE TABLE #IdMapping
    (
        SchemaName SYSNAME NOT NULL,
        TableName  SYSNAME NOT NULL,
        ColumnName SYSNAME NOT NULL,
        OldValue   BIGINT NOT NULL,
        NewValue   BIGINT NOT NULL
    );

    DECLARE
        @EventId BIGINT,
        @SchemaName SYSNAME,
        @TableName SYSNAME,
        @OperationCode INT,
        @RecordDataJson NVARCHAR(MAX);

    DECLARE event_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT
        EventId,
        SchemaName,
        TableName,
        OperationCode,
        RecordDataJson
    FROM #CdcEvents
    ORDER BY
        StartLsn,
        SeqVal,
        EventId;

    BEGIN TRY
        BEGIN TRANSACTION;

        OPEN event_cursor;

        FETCH NEXT FROM event_cursor
        INTO
            @EventId,
            @SchemaName,
            @TableName,
            @OperationCode,
            @RecordDataJson;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @OperationCode = 1
            BEGIN
                --EXEC dbo.ReplayCdcDeleteEvent
                --    @EventId = @EventId,
                --    @SchemaName = @SchemaName,
                --    @TableName = @TableName,
                --    @RecordDataJson = @RecordDataJson;
                print('Delete');
            END;
            ELSE IF @OperationCode = 2
            BEGIN
                --EXEC dbo.ReplayCdcInsertEvent
                --    @EventId = @EventId,
                --    @SchemaName = @SchemaName,
                --    @TableName = @TableName,
                --    @RecordDataJson = @RecordDataJson;
                print('Insert');
            END;
            ELSE IF @OperationCode = 4
            BEGIN
                --EXEC dbo.ReplayCdcUpdateEvent
                --    @EventId = @EventId,
                --    @SchemaName = @SchemaName,
                --    @TableName = @TableName,
                --    @RecordDataJson = @RecordDataJson;
                print('Update');
            END;
            ELSE
            BEGIN
                THROW 50001, 'Unsupported CDC operation code.', 1;
            END;

            FETCH NEXT FROM event_cursor
            INTO
                @EventId,
                @SchemaName,
                @TableName,
                @OperationCode,
                @RecordDataJson;
        END;

        CLOSE event_cursor;
        DEALLOCATE event_cursor;

        COMMIT TRANSACTION;

        SELECT *
        FROM #IdMapping;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'event_cursor') >= -1
        BEGIN
            CLOSE event_cursor;
            DEALLOCATE event_cursor;
        END;

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
GO