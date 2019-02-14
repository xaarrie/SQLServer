--HERE WE SHOW THE N TOP MOST FRAGMENTED INDEXES 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @N as integer = 100, @MinimunFragmentation as integer = 5

SELECT TOP (@N)
DB_NAME() as DatabaseName,
SCHEMA_NAME(o.Schema_Id) as SchemaName,
OBJECT_NAME(s.[object_id]) as TableName,
i.name as IndexName,
ROUND(s.avg_fragmentation_in_percent,2) as [Fragmentation %],
s.page_count
FROM 
sys.dm_db_index_physical_stats(DB_ID(),null,null,null,null) s
INNER JOIN sys.indexes i on s.[object_id] = i.[object_id] AND s.index_id = i.index_id
INNER JOIN sys.objects o on i.[object_id] = o.[object_id]
WHERE s.database_id = DB_ID() AND i.name is not null AND OBJECTPROPERTY(s.[object_id],'IsMsShipped') = 0
and s.page_count >1000 and ROUND(s.avg_fragmentation_in_percent,2) > @MinimunFragmentation --no miramos los de menos de 1000 paginas (pequeños) ni un % fragmentacion menor del indicado
ORDER BY [Fragmentation %] DESC