--HERE WE SHOW THE N TOP MOST USED INDEXES ORDER BY USAGE
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @N as integer = 20

SELECT TOP (@N)
DB_NAME() as DatabaseName,
SCHEMA_NAME(o.Schema_Id) as SchemaName,
OBJECT_NAME(s.[object_id]) as TableName,
i.name as IndexName,
(s.user_seeks + s.user_scans + s.user_lookups) as [Usage],
s.user_updates,
i.fill_factor
FROM 
sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i on s.[object_id] = i.[object_id] AND s.index_id = i.index_id
INNER JOIN sys.objects o on i.[object_id] = o.[object_id]
WHERE s.database_id = DB_ID() AND i.name is not null AND OBJECTPROPERTY(s.[object_id],'IsMsShipped') = 0
ORDER BY [Usage] DESC