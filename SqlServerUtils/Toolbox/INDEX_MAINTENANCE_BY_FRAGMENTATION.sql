CREATE PROCEDURE  IBER_INDEX_MAINTENANCE_BY_FRAGMENTATION 
@withpks  int = 0, @updatethreshold int = 0
as BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE  @Reorganize as integer = 5, @Rebuild as integer = 30
/*SI EXISTE LA TABLA CON LOS ULTIMOS DATOS DEL PLAN DE MANTENIMIENTO LA BORRAMOS*/
IF EXISTS (SELECT 1 
           FROM INFORMATION_SCHEMA.TABLES 
           WHERE TABLE_TYPE='BASE TABLE' 
           AND TABLE_NAME='IBER_INDEX_MAINTENANCE')
		   BEGIN
			DROP TABLE IBER_INDEX_MAINTENANCE
		   END
/*SI NO EXISTE LA TABLA CON LOS DATOS DEL ESTADO DE LOS INDICES*/
IF NOT EXISTS (SELECT 1 
           FROM INFORMATION_SCHEMA.TABLES 
           WHERE TABLE_TYPE='BASE TABLE' 
           AND TABLE_NAME='IBER_INDEX_MAINTENANCE_USAGE')
		   BEGIN
				/*LA CREAMOS*/
				SELECT 
				s.database_id,
				DB_NAME() as DatabaseName,
				SCHEMA_NAME(o.Schema_Id) as SchemaName,
				OBJECT_NAME(s.[object_id]) as TableName,
                                s.[object_id] as TableId,
				i.name as IndexName,
                                i.index_id as IndexId,
				(s.user_seeks + s.user_scans + s.user_lookups) as [CurrentReadUsage],
				s.user_updates as CurrentUpdateUsage,
				cast(0 as bigint) LasReadUsage,
				cast(0 as bigint) LastUpdateUsage,
				(s.user_seeks + s.user_scans + s.user_lookups) as [DiffReadUsage],
				s.user_updates as DiffUpdateUsage,
				i.fill_factor,
				CONVERT (date, GETDATE()) LastModification,
			CONVERT (date, GETDATE()) CurrentModification,
			cast('' as varchar(max)) LastSentence,
			CONVERT(datetime,'19800101') LasSentenceDate,
			CAST(0 as bigint) SentenceCounter,
			CAST((s.user_seeks + s.user_scans + s.user_lookups) as bigint) DiffReadAccumulated,
			CAST(s.user_updates as bigint) DiffUpdateAccumulated
				into IBER_INDEX_MAINTENANCE_USAGE
				FROM 
				sys.dm_db_index_usage_stats s
				INNER JOIN sys.indexes i on s.[object_id] = i.[object_id] AND s.index_id = i.index_id
				INNER JOIN sys.objects o on i.[object_id] = o.[object_id]


				WHERE 
				s.database_id = DB_ID() AND i.name is not null
		end else
		begin
		/*SI EXISTE UPDATEAMOS LOS DATOS DE LOS INDICES EXISTENTES*/
		update IBER_INDEX_MAINTENANCE_USAGE set 
		IBER_INDEX_MAINTENANCE_USAGE.LastModification = IBER_INDEX_MAINTENANCE_USAGE.CurrentModification, 
		IBER_INDEX_MAINTENANCE_USAGE.CurrentModification = T.CurrentModification,
		IBER_INDEX_MAINTENANCE_USAGE.LasReadUsage = IBER_INDEX_MAINTENANCE_USAGE.CurrentReadUsage,
		IBER_INDEX_MAINTENANCE_USAGE.CurrentReadUsage = T.CurrentReadUsage,
		IBER_INDEX_MAINTENANCE_USAGE.LastUpdateUsage = IBER_INDEX_MAINTENANCE_USAGE.CurrentUpdateUsage,
		IBER_INDEX_MAINTENANCE_USAGE.CurrentUpdateUsage = T.CurrentUpdateUsage,
		IBER_INDEX_MAINTENANCE_USAGE.fill_factor = T.fill_factor,
		IBER_INDEX_MAINTENANCE_USAGE.DiffReadUsage = 
		case 
			when T.CurrentReadUsage >= IBER_INDEX_MAINTENANCE_USAGE.CurrentReadUsage 
			then	T.CurrentReadUsage - IBER_INDEX_MAINTENANCE_USAGE.CurrentReadUsage 
			else IBER_INDEX_MAINTENANCE_USAGE.CurrentReadUsage end ,
		IBER_INDEX_MAINTENANCE_USAGE.DiffReadAccumulated =
		IBER_INDEX_MAINTENANCE_USAGE.DiffReadAccumulated + 
		case 
			when T.CurrentReadUsage >= IBER_INDEX_MAINTENANCE_USAGE.CurrentReadUsage 
			then	T.CurrentReadUsage - IBER_INDEX_MAINTENANCE_USAGE.CurrentReadUsage 
			else IBER_INDEX_MAINTENANCE_USAGE.CurrentReadUsage end ,

		IBER_INDEX_MAINTENANCE_USAGE.DiffUpdateUsage = 
		case
			when T.CurrentUpdateUsage >= IBER_INDEX_MAINTENANCE_USAGE.CurrentUpdateUsage
			then T.CurrentUpdateUsage - IBER_INDEX_MAINTENANCE_USAGE.CurrentUpdateUsage
			else IBER_INDEX_MAINTENANCE_USAGE.CurrentUpdateUsage end,
		IBER_INDEX_MAINTENANCE_USAGE.DiffUpdateAccumulated = 
		IBER_INDEX_MAINTENANCE_USAGE.DiffUpdateAccumulated +
		case
			when T.CurrentUpdateUsage >= IBER_INDEX_MAINTENANCE_USAGE.CurrentUpdateUsage
			then T.CurrentUpdateUsage - IBER_INDEX_MAINTENANCE_USAGE.CurrentUpdateUsage
			else IBER_INDEX_MAINTENANCE_USAGE.CurrentUpdateUsage end
		from (
		SELECT 
				s.database_id,
				DB_NAME() as DatabaseName,
				SCHEMA_NAME(o.Schema_Id) as SchemaName,
				OBJECT_NAME(s.[object_id]) as TableName,
				i.name as IndexName,
				(s.user_seeks + s.user_scans + s.user_lookups) as [CurrentReadUsage],
				s.user_updates as CurrentUpdateUsage,
			
				
				i.fill_factor,
				
			CONVERT (date, GETDATE()) CurrentModification
				
				FROM 
				sys.dm_db_index_usage_stats s
				INNER JOIN sys.indexes i on s.[object_id] = i.[object_id] AND s.index_id = i.index_id
				INNER JOIN sys.objects o on i.[object_id] = o.[object_id]


				WHERE 
				s.database_id = DB_ID() AND i.name is not null AND OBJECTPROPERTY(s.[object_id],'IsMsShipped') = 0) as T
				where t.database_id = IBER_INDEX_MAINTENANCE_USAGE.database_id and t.DatabaseName = IBER_INDEX_MAINTENANCE_USAGE.DatabaseName
				and t.SchemaName = IBER_INDEX_MAINTENANCE_USAGE.SchemaName and t.TableName = IBER_INDEX_MAINTENANCE_USAGE.TableName and t.IndexName
				= IBER_INDEX_MAINTENANCE_USAGE.IndexName and T.CurrentModification > IBER_INDEX_MAINTENANCE_USAGE.CurrentModification

				/*E INSERTAMOS AQUELLOS INDICES QUE PUEDAN SER NUEVOS*/
				INSERT INTO  IBER_INDEX_MAINTENANCE_USAGE
				SELECT 
				s.database_id,
				DB_NAME() as DatabaseName,
				SCHEMA_NAME(o.Schema_Id) as SchemaName,
				OBJECT_NAME(s.[object_id]) as TableName,
                                s.[object_id] as TableId,
				i.name as IndexName,
                                i.index_id as IndexId,
				(s.user_seeks + s.user_scans + s.user_lookups) as [CurrentReadUsage],
				s.user_updates as CurrentUpdateUsage,
				cast(0 as bigint) LasReadUsage,
				cast(0 as bigint) LastUpdateUsage,
				(s.user_seeks + s.user_scans + s.user_lookups) as [DiffReadUsage],
				s.user_updates as DiffUpdateUsage,
				i.fill_factor,
				CONVERT (date, GETDATE()) LastModification,
			CONVERT (date, GETDATE()) CurrentModification,
			cast('' as varchar(max)) LastSentence,
			CONVERT(datetime,'19800101') LasSentenceDate,
			CAST(0 as bigint) SentenceCounter,
			CAST((s.user_seeks + s.user_scans + s.user_lookups) as bigint) DiffReadAccumulated,
			CAST(s.user_updates as bigint) DiffUpdateAccumulated
				
				FROM 
				sys.dm_db_index_usage_stats s
				INNER JOIN sys.indexes i on s.[object_id] = i.[object_id] AND s.index_id = i.index_id
				INNER JOIN sys.objects o on i.[object_id] = o.[object_id]


				WHERE 
				s.database_id = DB_ID() AND i.name is not null AND OBJECTPROPERTY(s.[object_id],'IsMsShipped') = 0
				and not exists(select 1 from IBER_INDEX_MAINTENANCE_USAGE where 
				 s.database_id = IBER_INDEX_MAINTENANCE_USAGE.database_id and DB_NAME()  = IBER_INDEX_MAINTENANCE_USAGE.DatabaseName
				and SCHEMA_NAME(o.Schema_Id) = IBER_INDEX_MAINTENANCE_USAGE.SchemaName and OBJECT_NAME(s.[object_id]) = IBER_INDEX_MAINTENANCE_USAGE.TableName and i.name
				= IBER_INDEX_MAINTENANCE_USAGE.IndexName)

		end
/*EN FUNCION DE LOS DATOS DE FRAMENTACION DE LOS INDICES, DE SU NUMERO DE PAGINAS, DE SU GRADO DE UPDATES*/
/*REALIZAMOS EL REORGANIZE O REBUILD DEL INDICE ORDENADO POR NUMERO DE PAGINAS, TAMAÑO DEL INDICE*/
SELECT 
T.DatabaseName as DatabaseName,
T.SchemaName as SchemaName,
T.TableName,
T.IndexName,
ROUND(s.avg_fragmentation_in_percent,2) as [Fragmentation %],
ROUND(s.avg_page_space_used_in_percent,2) as [PageDensity %],
s.page_count,
-1 as Modification_Counter,
CASE WHEN ROUND(s.avg_fragmentation_in_percent,2) > @Rebuild THEN 
     'ALTER INDEX ['+i.Name+'] ON ['+T.DatabaseName+'].['+T.SchemaName+'].['+T.TableName+'] REBUILD WITH (ONLINE = OFF);'
     WHEN ROUND(s.avg_fragmentation_in_percent,2) > @Reorganize AND ROUND(s.avg_fragmentation_in_percent,2)<= @Rebuild THEN 
     'ALTER INDEX ['+i.Name+'] ON ['+T.DatabaseName+'].['+T.SchemaName+'].['+T.TableName+'] REORGANIZE;'     
     ELSE
     NULL
     END as Sentence,
	 CONVERT (datetime, GETDATE()) as StartDate,
	 CONVERT (datetime, GETDATE()) as EndDate,
	 0 as Duration,
	 s.page_count as Rank
into IBER_INDEX_MAINTENANCE
FROM 
IBER_INDEX_MAINTENANCE_USAGE as T
INNER JOIN sys.indexes i on T.TableId = i.[object_id] AND T.IndexId = i.index_id
AND (i.is_primary_key = 0 or @withpks = 1) and T.DiffUpdateAccumulated > @updatethreshold
cross apply (select *  from 
sys.dm_db_index_physical_stats(T.database_id,T.TableId,T.IndexId,null,'LIMITED') s) as s

WHERE T.DiffUpdateUsage>0 and i.name is not null AND OBJECTPROPERTY(s.[object_id],'IsMsShipped') = 0
and s.page_count >1000 and ROUND(s.avg_fragmentation_in_percent,2) > @Reorganize --no miramos los de menos de 1000 paginas (pequeños) ni un % fragmentacion menor del indicado
ORDER BY [Fragmentation %] DESC



DECLARE @sentence varchar(max), @indexname varchar(max),
@tablename varchar(max), @databasename  varchar(max),@schemaname  varchar(max),
@sdate datetime,@edate datetime,@duration int
/*EJECUTAMOS TODAS LAS SENTENCIAS PARA LOS INDICES Y REGISTRAMOS SU RENDIMIENTO*/
DECLARE dbNames_cursor CURSOR FAST_FORWARD 
 FOR select IBER_INDEX_MAINTENANCE.DatabaseName,IBER_INDEX_MAINTENANCE.SchemaName, IBER_INDEX_MAINTENANCE.TableName, IBER_INDEX_MAINTENANCE.IndexName, IBER_INDEX_MAINTENANCE.Sentence from IBER_INDEX_MAINTENANCE
 where IBER_INDEX_MAINTENANCE.IndexName is not null
 order by Rank desc
OPEN dbNames_cursor;
FETCH NEXT FROM dbNames_cursor INTO @databasename,@schemaname,@tablename,@indexname,@sentence
WHILE @@fetch_status = 0
BEGIN   
	set @sdate = CONVERT (datetime, GETDATE())
   exec (@sentence)
	set @edate  = CONVERT (datetime, GETDATE())
    set @duration  = Datediff(s, @sdate, @edate) 
	if @indexname is not null
	begin
	update IBER_INDEX_MAINTENANCE_USAGE set DiffReadAccumulated = 0,
        DiffUpdateAccumulated = 0, SentenceCounter = SentenceCounter + 1, LastSentence = @sentence,
		LasSentenceDate = CONVERT (datetime, GETDATE()) where 
        IBER_INDEX_MAINTENANCE_USAGE.DatabaseName = @databasename and
        IBER_INDEX_MAINTENANCE_USAGE.SchemaName = @schemaname and
        IBER_INDEX_MAINTENANCE_USAGE.TableName = @tablename and
        IBER_INDEX_MAINTENANCE_USAGE.IndexName = @indexname
	end 
	update IBER_INDEX_MAINTENANCE set StartDate = @sdate, EndDate = @edate,
	Duration = @duration where DatabaseName = @databasename
	and SchemaName = @schemaname and TableName = @tablename
	and ((IndexName is null and @indexname is null) or (IndexName = @indexname))
        FETCH NEXT FROM dbNames_cursor INTO @databasename,@schemaname,@tablename,@indexname,@sentence	
    

	
	
END
CLOSE dbNames_cursor
DEALLOCATE dbNames_cursor     
/*PARA TODAS LAS TABLAS DE BASE DE DATOS GENERAMOS UNA SENTENCIA DE ACTUALIZACION DE ESTADISTICAS*/
insert IBER_INDEX_MAINTENANCE (DatabaseName,SchemaName,TableName,IndexName,[Fragmentation %],[PageDensity %],[page_count],Modification_Counter,Sentence,StartDate,EndDate,Duration,Rank)
SELECT 
distinct
DB_NAME() as DatabaseName,
sch.name as SchemaName,
obj.name as TableName,
null,
-1 as [Fragmentation %],
-1 as [PageDensity %],
-1,
max(MODIFICATION_COUNTER),
'Update Statistics [' +DB_NAME() +'].[' +sch.name +'].[' +obj.name+ '] With FULLSCAN' as Sentence,
CONVERT (datetime, GETDATE()) as StartDate,
	 CONVERT (datetime, GETDATE()) as EndDate,
	 0 as Duration,
	 max(MODIFICATION_COUNTER) as Rank
 
FROM   SYS.OBJECTS AS OBJ
INNER JOIN SYS.SCHEMAS SCH
        ON OBJ.[SCHEMA_ID] = SCH.[SCHEMA_ID]
INNER JOIN INFORMATION_SCHEMA.TABLES as T on T.TABLE_NAME = OBJ.name and OBJ.type = 'U'

INNER JOIN SYS.STATS AS STAT
        ON STAT.[OBJECT_ID] = OBJ.[OBJECT_ID]
CROSS APPLY SYS.DM_DB_STATS_PROPERTIES(STAT.[OBJECT_ID], STAT.STATS_ID)
            AS SP

WHERE 
OBJ.[OBJECT_ID] > 100
GROUP  BY SCH.NAME,
    OBJ.NAME
/*EJECUTAMOS LAS SENTENCIAS Y REGISTRAMOS SUS TIEMPOS*/
DECLARE dbStatistics_cursor CURSOR FAST_FORWARD 
 FOR select IBER_INDEX_MAINTENANCE.DatabaseName,IBER_INDEX_MAINTENANCE.SchemaName, IBER_INDEX_MAINTENANCE.TableName, IBER_INDEX_MAINTENANCE.IndexName, IBER_INDEX_MAINTENANCE.Sentence from IBER_INDEX_MAINTENANCE
 where IBER_INDEX_MAINTENANCE.IndexName is null
 order by Rank desc
OPEN dbStatistics_cursor;
FETCH NEXT FROM dbStatistics_cursor INTO @databasename,@schemaname,@tablename,@indexname,@sentence
WHILE @@fetch_status = 0
BEGIN   
	set @sdate = CONVERT (datetime, GETDATE())
   exec (@sentence)
	set @edate  = CONVERT (datetime, GETDATE())
    set @duration  = Datediff(s, @sdate, @edate) 
	
	update IBER_INDEX_MAINTENANCE set StartDate = @sdate, EndDate = @edate,
	Duration = @duration where DatabaseName = @databasename
	and SchemaName = @schemaname and TableName = @tablename
	and ((IndexName is null and @indexname is null) or (IndexName = @indexname))
        FETCH NEXT FROM dbStatistics_cursor INTO @databasename,@schemaname,@tablename,@indexname,@sentence	
    

	
	
END
CLOSE dbStatistics_cursor
DEALLOCATE dbStatistics_cursor 
END