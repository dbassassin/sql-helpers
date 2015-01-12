SELECT 
		id.statement,
        cast(gs.avg_total_user_cost * gs.avg_user_impact * ( gs.user_seeks + gs.user_scans )as BIGINT) AS Impact,
        cast(gs.avg_total_user_cost as numeric(10,2)) as [Average Total Cost],
        cast(gs.avg_user_impact as int) as [% Reduction of Cost],
        gs.user_seeks + gs.user_scans as [Missed Opportunities],
        id.equality_columns as [Equality Columns],
        id.inequality_columns as [Inequality Columns],
        id.included_columns as [Included Columns],
		CASE
		--Generate script when there are equality columns, but no inequality and no included columns
		WHEN id.equality_columns IS NOT NULL AND id.inequality_columns IS NULL AND id.included_columns IS NULL THEN
		'CREATE INDEX MIX__' + REPLACE(REPLACE(REPLACE(REPLACE(id.equality_columns + '_', ',', '_'), ' ', ''), '[', ''), ']', '') 
			+ ' ON ' + id.statement + ' (' + id.equality_columns + ')'

		--Generate script when there are equality columns, no inequality columns, and included columns
		WHEN id.equality_columns IS NOT NULL AND id.inequality_columns IS NULL AND id.included_columns IS NOT NULL THEN
		'CREATE INDEX MIX__' + REPLACE(REPLACE(REPLACE(REPLACE(id.equality_columns, ',', '_'), ' ', ''), '[', ''), ']', '') 
			+ '__INCLUDES__' + REPLACE(REPLACE(REPLACE(REPLACE(id.included_columns, '[', ''), ']', ''), ' ', ''), ',', '_')
			+ ' ON ' + id.statement + ' (' + id.equality_columns + ') INCLUDE (' + id.included_columns + ')'

		--Generate script when there are no equality, there are inequality  and there are no included columns
		WHEN id.equality_columns IS NULL AND id.inequality_columns IS NOT NULL AND id.included_columns IS NULL THEN
		'CREATE INDEX MIX__' + REPLACE(REPLACE(REPLACE(REPLACE(id.inequality_columns, ',', '_'), ' ', ''), '[', ''), ']', '') 
			+ ' ON ' + id.statement + ' (' + id.inequality_columns + ')'

		--Generate script when there are equality, inequality and included columns
		WHEN id.equality_columns IS NOT NULL AND id.included_columns IS NOT NULL AND id.included_columns IS NOT NULL THEN
		'CREATE INDEX MIX__' + REPLACE(REPLACE(REPLACE(REPLACE(id.equality_columns + '_' + id.inequality_columns, ',', '_'), ' ', ''), '[', ''), ']', '') 
			+ '__INCLUDES__' + REPLACE(REPLACE(REPLACE(REPLACE(id.included_columns, '[', ''), ']', ''), ' ', ''), ',', '_')
			+ ' ON ' + id.statement + ' (' + id.equality_columns + ',' + id.inequality_columns + ') INCLUDE (' + id.included_columns + ')'

		--Generate script when there are equality, inequality and no included columns
		WHEN id.equality_columns IS NOT NULL AND id.inequality_columns IS NOT NULL AND id.included_columns IS NULL THEN
		'CREATE INDEX MIX__' + REPLACE(REPLACE(REPLACE(REPLACE(id.equality_columns + '_' + id.inequality_columns, ',', '_'), ' ', ''), '[', ''), ']', '') 
			+ ' ON ' + id.statement + ' (' + id.equality_columns + ',' + id.inequality_columns + ')'

		--Generate script when there are inequality and included columns, but no equality
		WHEN id.equality_columns IS NULL AND id.inequality_columns IS NOT NULL AND id.included_columns IS NOT NULL THEN
		'CREATE INDEX MIX__' + REPLACE(REPLACE(REPLACE(REPLACE(id.inequality_columns, ',', '_'), ' ', ''), '[', ''), ']', '') 
			+ '__INCLUDES__' + REPLACE(REPLACE(REPLACE(REPLACE(id.included_columns, '[', ''), ']', ''), ' ', ''), ',', '_')
			+ ' ON ' + id.statement + ' (' + id.inequality_columns + ') INCLUDE (' + id.included_columns + ')'

		END AS 'TSQL'
FROM sys.dm_db_missing_index_group_stats AS gs
JOIN sys.dm_db_missing_index_groups AS ig ON gs.group_handle = ig.index_group_handle
JOIN sys.dm_db_missing_index_details AS id ON ig.index_handle = id.index_handle
ORDER BY statement, Impact DESC
go