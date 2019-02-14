--HERE WE SHOW THE INDEXES THAT NEVER HAVE BEEN USED
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
DB_NAME() as DatabaseName,
SCHEMA_NAME(o.Schema_id) as SchemaName,
OBJECT_NAME(s.[object_id]) as TableName,
i.Name as IndexName

FROM
	sys.indexes i INNER JOIN sys.objects o ON i.[object_id] = o.[object_id]
	LEFT OUTER JOIN sys.dm_db_index_usage_stats s ON s.[object_id] = i.[object_id]
	AND i.index_id = s.index_id AND database_id = DB_ID()
	WHERE OBJECTPROPERTY(o.object_id,'IsMsShipped') = 0
	AND i.name is not null
	AND s.object_id is null
	ORDER BY DatabaseName,SchemaName,TableName,IndexName