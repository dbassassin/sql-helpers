SELECT 'DROP INDEX [' + i.NAME + '] ON [' + s.NAME + '].[' + t.NAME + ']' AS [Drop TSQL]
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE i.Is_Hypothetical = 1