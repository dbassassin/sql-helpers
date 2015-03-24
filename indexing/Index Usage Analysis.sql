SELECT 
o.name
, indexname=i.name
, i.index_id
, reads = user_seeks + user_scans + user_lookups  
, writes =  user_updates  
, rows = (SELECT SUM(p.rows) FROM sys.partitions p WHERE p.index_id = s.index_id AND s.object_id = p.object_id)
, (SUM(a.total_pages) * 8) /1024 AS TotalSpaceMB
, (SUM(a.used_pages) * 8) / 1024 AS UsedspaceMB
, ((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024 AS UnusedSpaceMB
, CASE
	WHEN s.user_updates < 1 THEN 100
	ELSE 1.00 * (s.user_seeks + s.user_scans + s.user_lookups) / s.user_updates
  END AS reads_per_write
, 'ALTER INDEX ' + QUOTENAME(i.name)
+ ' ON ' + QUOTENAME(c.name) + '.' + QUOTENAME(OBJECT_NAME(s.object_id)) + ' DISABLE' as 'Disable TSQL'
, 'DROP INDEX ' + QUOTENAME(i.name) 
+ ' ON ' + QUOTENAME(c.name) + '.' + QUOTENAME(OBJECT_NAME(s.object_id)) as 'Drop TSQL'
FROM sys.dm_db_index_usage_stats s  
INNER JOIN sys.indexes i ON i.index_id = s.index_id AND s.object_id = i.object_id   
INNER JOIN sys.objects o on s.object_id = o.object_id
INNER JOIN sys.schemas c on o.schema_id = c.schema_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE OBJECTPROPERTY(s.object_id,'IsUserTable') = 1
AND s.database_id = DB_ID()   
AND i.type_desc = 'nonclustered'
AND i.is_primary_key = 0
AND i.is_unique_constraint = 0
--Edit this next line to suit your preferences.  The below is a predicate on the amount of reads
--AND (user_seeks + user_scans + user_lookups) < 10000
--Edit this next line to suit your preferences.  The below is a predicate on the amnount of writes
--AND (user_updates) > 1
--Edit this next line to suit your preferences.  The below is a predicate on reads being less than writes.  This assumes that any index with less reads than writes is one that should be reviewed.
AND (user_seeks + user_scans + user_lookups) < user_updates
GROUP BY i.name, o.name, i.index_id, user_seeks, user_scans, user_lookups, user_updates, i.index_id, s.object_id, p.index_id, s.index_id, i.name, c.name
ORDER BY TotalSpaceMB DESC