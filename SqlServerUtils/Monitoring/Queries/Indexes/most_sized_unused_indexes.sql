--HERE WE SHOW THE TOP N MOST COSTLY UNUSED INDEXES ORDERED BY THE NUMBER OF UPDATES APPLIED TO THEM
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 
DB_NAME() as DatabaseName,
SCHEMA_NAME(o.Schema_ID) AS SchemaName,
OBJECT_NAME(i.[object_id]) AS TableName,
i.name as IndexName,
ISNULL(s.user_updates,0) as user_updates,
ISNULL(s.system_seeks,0) + ISNULL(s.system_scans,0) + ISNULL(s.system_lookups,0) as [System Usage],
ISNULL(st.IndexSizeKB, 0) as IndexSizeKB
FROM

sys.indexes i 
INNER JOIN sys.objects o ON i.[object_id] = o.[object_id]
LEFT JOIN sys.dm_db_index_usage_stats s ON s.[object_id] = i.[object_id] AND s.index_id = i.index_id
INNER JOIN (

	SELECT
    iq.name                  AS IndexName,
	iq.index_id,
	iq.object_id,
    SUM(sq.used_page_count) * 8   AS IndexSizeKB
FROM sys.dm_db_partition_stats  AS sq 
JOIN sys.indexes                AS iq
ON sq.[object_id] = iq.[object_id] AND sq.index_id = iq.index_id

GROUP BY iq.name,iq.index_id,
	iq.object_id
HAVING SUM(sq.used_page_count) > 0
	) as st on st.index_id = i.index_id and st.object_id = i.object_id
WHERE 
 OBJECTPROPERTY(i.[object_id],'IsMsShipped') = 0

and i.name is not null and (ISNULL(s.system_seeks,0) + ISNULL(s.system_scans,0) + ISNULL(s.system_lookups,0)= 0)

ORDER BY st.IndexSizeKB DESC


