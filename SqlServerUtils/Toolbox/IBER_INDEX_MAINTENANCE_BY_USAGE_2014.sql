CREATE PROCEDURE  IBER_INDEX_MAINTENANCE_BY_USAGE 
@MostReadIndexes as integer = 100, 
@MostUpdatedIndexes as integer = 100,
@StoredProcedures as varchar(max) = ''
as
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

if not exists(SELECT 1 
           FROM INFORMATION_SCHEMA.TABLES 
           WHERE TABLE_TYPE='BASE TABLE' 
           AND TABLE_NAME='IBER_INDEX_USAGE')
BEGIN
	CREATE TABLE IBER_INDEX_USAGE (db_id smallint, databasename varchar(128),schemaname sysname,index_name sysname,tablename sysname,usage int, updates int)
	INSERT INTO IBER_INDEX_USAGE(db_id,databasename,schemaname,index_name,tablename,usage,updates)
	SELECT 
		DB_ID(),
		DB_NAME() as DatabaseName,
		SCHEMA_NAME(o.Schema_Id) as SchemaName,

		i.name as IndexName,
		OBJECT_NAME(o.[object_id]) as TableName,
		0, 
		0
		FROM 		
		sys.indexes i 
		INNER JOIN sys.objects o on i.[object_id] = o.[object_id]
		WHERE   i.name is not null AND OBJECTPROPERTY(o.[object_id],'IsMsShipped') = 0
		
END



SELECT TOP (@MostReadIndexes)
s.database_id,
DB_NAME() as DatabaseName,
SCHEMA_NAME(o.Schema_Id) as SchemaName,
OBJECT_NAME(s.[object_id]) as TableName,
i.name as IndexName,
(s.user_seeks + s.user_scans + s.user_lookups) as [Usage],
s.user_updates,
i.fill_factor
into #MostReadWithUpdates
FROM 
sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i on s.[object_id] = i.[object_id] AND s.index_id = i.index_id
INNER JOIN sys.objects o on i.[object_id] = o.[object_id]
join IBER_INDEX_USAGE as IU on
s.database_id = IU.db_id and i.name = IU.index_name and OBJECT_NAME(s.[object_id]) = IU.tablename
WHERE 
s.database_id = DB_ID() AND i.name is not null AND OBJECTPROPERTY(s.[object_id],'IsMsShipped') = 0
and (s.user_seeks + s.user_scans + s.user_lookups) > IU.usage and s.user_updates>IU.updates
ORDER BY [Usage] DESC

SELECT TOP (@MostUpdatedIndexes)
s.database_id,
DB_NAME() as DatabaseName,
SCHEMA_NAME(o.Schema_Id) as SchemaName,
OBJECT_NAME(s.[object_id]) as TableName,
i.name as IndexName,
(s.user_seeks + s.user_scans + s.user_lookups) as [Usage],
s.user_updates,
i.fill_factor
into #MostUpdated
FROM 
sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i on s.[object_id] = i.[object_id] AND s.index_id = i.index_id
INNER JOIN sys.objects o on i.[object_id] = o.[object_id]
join IBER_INDEX_USAGE as IU on
s.database_id = IU.db_id and i.name = IU.index_name and OBJECT_NAME(s.[object_id]) = IU.tablename
WHERE 
s.database_id = DB_ID() AND i.name is not null AND OBJECTPROPERTY(s.[object_id],'IsMsShipped') = 0
and s.user_updates>IU.updates
ORDER BY s.user_updates DESC


;WITH stored_procedures AS (
 
SELECT 
 distinct o.name AS parent, oo.name AS child, oo.id as childid,o.id as parentid,
 ROW_NUMBER() OVER(partition by o.name,oo.name ORDER BY o.name,oo.name) as rn, oo.name as TableName, oo.id as TableID
FROM sysdepends d 
INNER JOIN sysobjects o ON o.id=d.id
INNER JOIN sysobjects oo ON oo.id=d.depid
--INNER JOIN SplitFunction(@StoredProcedures,',') as SP on o.name like '%'+ SP.items +'%'
WHERE o.xtype in ('P','IF','FN','V') and oo.xtype = 'U' 
union all
select
  o.name AS parent, sp.parent AS child, sp.parentid as childid,o.id as parentid,
ROW_NUMBER() OVER(partition by o.name,sp.parent ORDER BY o.name,sp.parent) AS rn, SP.TableName, SP.TableID
FROM sysdepends d 
INNER JOIN sysobjects o ON o.id=d.id
--INNER JOIN sysobjects oo ON oo.id=d.depid
--INNER JOIN SplitFunction(@StoredProcedures,',') as SP on oo.name like '%'+ SP.items +'%'
join stored_procedures as SP on sp.parentid = d.depid and sp.rn = 1 and sp.parentid <> o.id
WHERE o.xtype in ('P','IF','FN','V')
)

SELECT 
db_id() as database_id,
DB_NAME() as DatabaseName,
SCHEMA_NAME(o.Schema_Id) as SchemaName,
OBJECT_NAME(o.[object_id]) as TableName,
i.name as IndexName,
stored_procedures.parent as proc_name
into #UsedInProcs
FROM stored_procedures
INNER JOIN SplitFunction(@StoredProcedures,',') as SP on stored_procedures.parent like '%'+ SP.items+'%'
and rn = 1
INNER JOIN sys.indexes i on stored_procedures.tableid = i.[object_id] 
INNER JOIN sys.objects o on i.[object_id] = o.[object_id]
WHERE  i.name is not null



IF EXISTS (SELECT 1 
           FROM INFORMATION_SCHEMA.TABLES 
           WHERE TABLE_TYPE='BASE TABLE' 
           AND TABLE_NAME='IBER_INDEX_MAINTENANCE')
		   BEGIN
			DROP TABLE IBER_INDEX_MAINTENANCE
		   END

SELECT distinct 
DB_NAME() as DatabaseName,
SCHEMA_NAME(o.Schema_Id) as SchemaName,
OBJECT_NAME(ss.[object_id]) as TableName,
i.name as IndexName,
/*ROUND(s.avg_fragmentation_in_percent,2)*/0 as [Fragmentation %],
/*s.page_count*/0 as page_count,

     'ALTER INDEX ['+i.Name+'] ON ['+DB_NAME()+'].['+SCHEMA_NAME (o.schema_id)+'].['+OBJECT_NAME(ss.[object_id])+'] REBUILD WITH (ONLINE = OFF);'
 
   as Sentence
 into IBER_INDEX_MAINTENANCE
FROM 
/*sys.dm_db_index_physical_stats(DB_ID(),null,null,null,null) s*/
sys.indexes i /*on s.[object_id] = i.[object_id] AND s.index_id = i.index_id*/
INNER JOIN(
select M.IndexName from #MostReadWithUpdates as M
union
select U.IndexName from #MostUpdated as U
union
select P.IndexName from #UsedInProcs as P
) as T ON i.name = t.IndexName
INNER JOIN sys.objects o on i.[object_id] = o.[object_id]
INNER JOIN sys.dm_db_index_usage_stats ss on ss.[object_id] = i.[object_id] AND ss.index_id = i.index_id
join IBER_INDEX_USAGE as IU on
ss.database_id = IU.db_id and i.name = IU.index_name and OBJECT_NAME(ss.[object_id]) = IU.tablename
WHERE ss.database_id = DB_ID() AND i.name is not null AND OBJECTPROPERTY(ss.[object_id],'IsMsShipped') = 0 and
ss.user_updates > IU.updates
--and s.page_count >1000 
--and ROUND(s.avg_fragmentation_in_percent,2) > @Reorganize --no miramos los de menos de 1000 paginas (pequeños) ni un % fragmentacion menor del indicado
ORDER BY [Fragmentation %] DESC



DECLARE @sentence varchar(max), @indexname varchar(max)
DECLARE dbNames_cursor CURSOR
 FOR 
 select IBER_INDEX_MAINTENANCE.IndexName, IBER_INDEX_MAINTENANCE.Sentence 
 from IBER_INDEX_MAINTENANCE
OPEN dbNames_cursor;
FETCH NEXT FROM dbNames_cursor INTO @indexname,@sentence
WHILE @@fetch_status = 0
BEGIN   
	EXEC (@sentence);  
	--PRINT @sentence
	FETCH NEXT FROM dbNames_cursor INTO @indexname,@sentence	
	PRINT 'Index ' + @indexname + ' done'	
END
PRINT ''
PRINT 'ALL INDEXES HAVE BEEN REORGANIZED/REBUILD'
PRINT ''
/*
select IBER_INDEX_MAINTENANCE.IndexName, IBER_INDEX_MAINTENANCE.Sentence 
 from IBER_INDEX_MAINTENANCE*/
truncate table IBER_INDEX_USAGE
INSERT INTO IBER_INDEX_USAGE(db_id,databasename,schemaname,index_name,tablename,usage,updates)
	SELECT 
		DB_ID(),
		DB_NAME() as DatabaseName,
		SCHEMA_NAME(o.Schema_Id) as SchemaName,

		i.name as IndexName,
		OBJECT_NAME(o.[object_id]) as TableName,
		(ISNULL(s.user_seeks,0) + ISNULL(s.user_scans,0) + ISNULL(s.user_lookups,0)) as [Usage],
ISNULL(s.user_updates,0)
		FROM 
		
		sys.indexes i 
		LEFT JOIN sys.dm_db_index_usage_stats s on s.[object_id] = i.[object_id] AND s.index_id = i.index_id
		INNER JOIN sys.objects o on i.[object_id] = o.[object_id]
		WHERE   i.name is not null AND OBJECTPROPERTY(o.[object_id],'IsMsShipped') = 0
		and DB_ID() = ISNULL(s.database_id,DB_ID())
END

