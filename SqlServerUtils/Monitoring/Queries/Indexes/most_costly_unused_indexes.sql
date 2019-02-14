--HERE WE SHOW THE TOP N MOST COSTLY UNUSED INDEXES ORDERED BY THE NUMBER OF UPDATES APPLIED TO THEM
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @N as integer = 20
SELECT TOP (@N)
DB_NAME() as DatabaseName,
SCHEMA_NAME(o.Schema_ID) AS SchemaName,
OBJECT_NAME(s.[object_id]) AS TableName,
i.name as IndexName,
s.user_updates,
s.system_seeks + s.system_scans + s.system_lookups as [System Usage]
FROM
sys.dm_db_index_usage_stats s
INNER JOIN  sys.indexes i ON s.[object_id] = i.[object_id] AND s.index_id = i.index_id
INNER JOIN sys.objects o ON i.[object_id] = o.[object_id]
WHERE s.database_id = DB_ID() AND OBJECTPROPERTY(s.[object_id],'IsMsShipped') = 0
AND 
s.user_seeks = 0 AND --HERE IS THE USAGE WE WANT TO FILTER
s.user_scans = 0 AND --HERE IS THE USAGE WE WANT TO FILTER
s.user_lookups = 0 AND --HERE IS THE USAGE WE WANT TO FILTER
i.name is not null ORDER BY s.user_updates DESC