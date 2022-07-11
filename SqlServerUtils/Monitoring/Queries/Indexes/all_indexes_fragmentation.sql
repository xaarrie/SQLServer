

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
				(s.user_seeks + s.user_scans + s.user_lookups) as [DiffReadUsage],
				s.user_updates as DiffUpdateUsage,
				i.fill_factor,
				
			CAST((s.user_seeks + s.user_scans + s.user_lookups) as bigint) DiffReadAccumulated,
			CAST(s.user_updates as bigint) DiffUpdateAccumulated,
			ss.avg_fragmentation_in_percent as FragmentationPercent,
			ss.page_count as Page_Count
				
				FROM 
				sys.dm_db_index_usage_stats s
				INNER JOIN sys.indexes i on s.[object_id] = i.[object_id] AND s.index_id = i.index_id
				INNER JOIN sys.objects o on i.[object_id] = o.[object_id]
				join (select *  from 
sys.dm_db_index_physical_stats(DB_ID(),null,null,null,'LIMITED')as k) as ss on ss.index_id = i.index_id and ss.object_id = i.object_id

				WHERE 
				s.database_id = DB_ID() AND i.name is not null AND OBJECTPROPERTY(s.[object_id],'IsMsShipped') = 0
                order by FragmentationPercent desc