set transaction isolation level read uncommitted
DECLARE @N int = 20
select TOP (@N)
x.name as SchemaName,
OBJECT_NAME(s.object_id) as TableName,
i.name as IndexName,
s.page_latch_wait_in_ms ,
s.page_latch_wait_count
from sys.dm_db_index_operational_stats(DB_ID(),null,null,null) s
inner join sys.objects o on s.object_id = o.object_id
inner join sys.indexes i on s.index_id = i.index_id and i.object_id = o.object_id
inner join sys.schemas x on x.schema_id = o.schema_id
where s.page_latch_wait_in_ms > 0 and o.is_ms_shipped = 0
order by s.page_latch_wait_in_ms  desc