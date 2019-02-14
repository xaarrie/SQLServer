CREATE PROCEDURE  IBER_INDEX_MAINTENANCE_BY_FRAGMENTATION as
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE  @Reorganize as integer = 5, @Rebuild as integer = 30

IF EXISTS (SELECT 1 
           FROM INFORMATION_SCHEMA.TABLES 
           WHERE TABLE_TYPE='BASE TABLE' 
           AND TABLE_NAME='IBER_INDEX_MAINTENANCE')
		   BEGIN
			DROP TABLE IBER_INDEX_MAINTENANCE
		   END

SELECT 
DB_NAME() as DatabaseName,
SCHEMA_NAME(o.Schema_Id) as SchemaName,
OBJECT_NAME(s.[object_id]) as TableName,
i.name as IndexName,
ROUND(s.avg_fragmentation_in_percent,2) as [Fragmentation %],
s.page_count,
CASE WHEN ROUND(s.avg_fragmentation_in_percent,2) > @Rebuild THEN 
     'ALTER INDEX ['+i.Name+'] ON ['+DB_NAME()+'].['+SCHEMA_NAME (o.schema_id)+'].['+OBJECT_NAME(s.[object_id])+'] REBUILD WITH (ONLINE = OFF);'
     WHEN ROUND(s.avg_fragmentation_in_percent,2) > @Reorganize AND ROUND(s.avg_fragmentation_in_percent,2)<= @Rebuild THEN 
     'ALTER INDEX ['+i.Name+'] ON ['+DB_NAME()+'].['+SCHEMA_NAME (o.schema_id)+'].['+OBJECT_NAME(s.[object_id])+'] REORGANIZE;'     
     ELSE
     NULL
     END as Sentence
 into IBER_INDEX_MAINTENANCE
FROM 
sys.dm_db_index_physical_stats(DB_ID(),null,null,null,null) s
INNER JOIN sys.indexes i on s.[object_id] = i.[object_id] AND s.index_id = i.index_id
INNER JOIN sys.objects o on i.[object_id] = o.[object_id]
WHERE s.database_id = DB_ID() AND i.name is not null AND OBJECTPROPERTY(s.[object_id],'IsMsShipped') = 0
and s.page_count >1000 and ROUND(s.avg_fragmentation_in_percent,2) > @Reorganize --no miramos los de menos de 1000 paginas (pequeños) ni un % fragmentacion menor del indicado
ORDER BY [Fragmentation %] DESC

DECLARE @sentence varchar(max), @indexname varchar(max)
DECLARE dbNames_cursor CURSOR
 FOR select IBER_INDEX_MAINTENANCE.IndexName, IBER_INDEX_MAINTENANCE.Sentence from IBER_INDEX_MAINTENANCE
OPEN dbNames_cursor;
FETCH NEXT FROM dbNames_cursor INTO @indexname,@sentence
WHILE @@fetch_status = 0
BEGIN   
	EXEC (@sentence);  
	FETCH NEXT FROM dbNames_cursor INTO @indexname,@sentence	
	PRINT 'Index ' + @indexname + ' done'
	
END
PRINT ''
PRINT 'ALL INDEXES HAVE BEEN REORGANIZED/REBUILD'
PRINT ''

END
