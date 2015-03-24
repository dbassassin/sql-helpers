SELECT DISTINCT o.NAME
	,i.NAME
	,'DROP INDEX ' + QUOTENAME(i.NAME) + ' ON ' + QUOTENAME(c.NAME) + '.' + QUOTENAME(OBJECT_NAME(s.object_id)) AS 'Drop TSQL'
	,'ALTER INDEX ' + QUOTENAME(i.NAME) + ' ON ' + QUOTENAME(c.NAME) + '.' + QUOTENAME(OBJECT_NAME(s.object_id)) + ' Rebuild' AS 'Enable TSQL'
FROM sys.indexes i
INNER JOIN sys.dm_db_index_usage_stats s ON i.object_id = s.object_id
INNER JOIN sys.objects o ON s.object_id = o.object_id
INNER JOIN sys.schemas c ON o.schema_id = c.schema_id
WHERE i.is_disabled = 1
ORDER BY o.NAME
	,i.NAME