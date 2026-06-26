# High-level architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ DB1 (Primary database)                                                      │
└─────────────────────────────────────────────────────────────────────────────┘
                    │
                    │ 1. Create a snapshot of DB1
                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ DB2 (Working database)                                                      │
│                                                                             │
│ Users perform INSERT, UPDATE and DELETE operations.                         │
└─────────────────────────────────────────────────────────────────────────────┘
                    │
                    │ 2. SQL Server Change Data Capture (CDC)
                    │    continuously monitors the transaction log
                    │    and stores every committed row change.
                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ CDC Change Tables                                                           │
│                                                                             │
│ cdc.dbo_<TableName>_CT                                                      │
│                                                                             │
│ These tables contain every INSERT, UPDATE and DELETE together with          │
│ metadata describing the order in which the changes occurred.                │
└─────────────────────────────────────────────────────────────────────────────┘
                    │
                    │ 3. ExportCdcEvents
                    │    Reads all CDC changes since the supplied LSN.
                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ Generic Event Stream                                                        │
│                                                                             │
│ EventId                                                                     │
│ SchemaName                                                                  │
│ TableName                                                                   │
│ Operation (INSERT / UPDATE / DELETE)                                        │
│ StartLsn                                                                    │
│ SeqVal                                                                      │
│ RecordDataJson                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                    │
                    │ 4. Generate replay SQL
                    │    Converts each event into SQL statements.
                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ Replay Script                                                               │
│                                                                             │
│ UPDATE ...                                                                  │
│ INSERT ...                                                                  │
│ DELETE ...                                                                  │
└─────────────────────────────────────────────────────────────────────────────┘
                    │
                    │ 5. Execute the generated script
                    │    inside a single transaction.
                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ DB1                                                                         │
│                                                                             │
│ All changes made in DB2 are applied to the primary database.                │
│                                                                             │
│ Any PK/FK violation causes the transaction to roll back.                    │
└─────────────────────────────────────────────────────────────────────────────┘
```