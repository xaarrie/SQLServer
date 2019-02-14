--HERE  WE SHOW THE N TOP HIGH MAINTENANCE INDEXES ORDERED BY MAINTENANCE COST
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @N integer = 20
SELECT TOP(@N)
DB_NAME() as DatabaseName,
SCHEMA_NAME(o.Schema_id) as SchemaName,
OBJECT_NAME(s.[object_id]) as TableName,
i.Name as IndexName,
(s.user_updates) as [update_usage],
(s.user_seeks + s.user_scans + s.user_lookups) as [Retrieval Usage],
(s.user_updates) - (s.user_seeks + s.user_scans + s.user_lookups) as [Maintenance Cost],
s.system_seeks + s.system_scans + s.system_lookups as [System Usage],
s.last_user_seek,
s.last_user_scan,
s.last_user_lookup
FROM
	sys.dm_db_index_usage_stats s
	INNER JOIN sys.indexes i on s.[object_id] = i.[object_id] AND s.index_id = i.index_id
	INNER JOIN sys.objects o ON i.[object_id] = o.[object_id]
	WHERE s.database_id = DB_ID()
	AND i.name is not null
	AND OBJECTPROPERTY(s.[object_id],'IsMsShipped') = 0
	AND (s.user_seeks + s.user_scans + s.user_lookups) > = 0
	ORDER BY [Maintenance Cost] DESC
