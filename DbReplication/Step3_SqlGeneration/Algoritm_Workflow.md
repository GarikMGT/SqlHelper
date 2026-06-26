# Workflow

```text
#CdcEvents
      │
      ▼
Begin transaction
      │
      ▼
Open cursor over ordered events
      │
      ▼
For each event
      │
      ├─ Read event metadata
      │     • SchemaName
      │     • TableName
      │     • Operation
      │     • RecordDataJson
      │
      ├─ Read target table metadata
      │
      ├─ UPDATE event
      │     ├─ Apply current PK/FK ID mappings
      │     └─ Generate and execute dynamic UPDATE
      │
      ├─ DELETE event
      │     ├─ Apply current PK ID mappings
      │     └─ Generate and execute dynamic DELETE
      │
      └─ INSERT event
            ├─ Apply current PK/FK ID mappings
            ├─ Generate and execute dynamic INSERT
            ├─ Capture the newly generated identity value
            └─ Store ID mapping (OldId → NewId)
      │
      ▼
Process next event
      │
      ▼
Commit transaction
```
