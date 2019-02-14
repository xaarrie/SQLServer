﻿--This routine identifier
set transaction isolation level read uncommitted
DECLARE @DelayTime varchar(10) = '00:05:00'



select
x.name as SchemaName,
OBJECT_NAME(s.object_id) as TableName,
i.name as IndexName,
s.row_lock_wait_in_ms,
s.row_lock_wait_count
into #PreWorkIndexCount
from sys.dm_db_index_operational_stats(DB_ID(),null,null,null) s
inner join sys.objects o on s.object_id = o.object_id
inner join sys.indexes i on s.index_id = i.index_id and i.object_id = o.object_id
inner join sys.schemas x on x.schema_id = o.schema_id
where s.row_lock_wait_in_ms > 0 and o.is_ms_shipped = 0



--query stats counters
select 
sql_handle, plan_handle, total_elapsed_time, total_worker_time, total_logical_reads, total_logical_writes,
total_clr_time, execution_count, statement_start_offset,statement_end_offset
into #PreWorkQuerySnapshot
from sys.dm_exec_query_stats


WAITFOR DELAY @DelayTime

--query stats counters
select 
sql_handle, plan_handle, total_elapsed_time, total_worker_time, total_logical_reads, total_logical_writes,
total_clr_time, execution_count, statement_start_offset,statement_end_offset
into #PostWorkQuerySnapshot
from sys.dm_exec_query_stats




select
x.name as SchemaName,
OBJECT_NAME(s.object_id) as TableName,
i.name as IndexName,
s.row_lock_wait_in_ms,
s.row_lock_wait_count
into #PostWorkIndexCount
from sys.dm_db_index_operational_stats(DB_ID(),null,null,null) s
inner join sys.objects o on s.object_id = o.object_id
inner join sys.indexes i on s.index_id = i.index_id and i.object_id = o.object_id
inner join sys.schemas x on x.schema_id = o.schema_id
where s.row_lock_wait_in_ms > 0 and o.is_ms_shipped = 0


select 
p2.SchemaName,
p2.TableName,
p2.IndexName,
p2.row_lock_wait_in_ms - ISNULL(p1.row_lock_wait_in_ms,0) as RowLockWaitTimeDelta_ms
from #PreWorkIndexCount p1 right outer join #PostWorkIndexCount p2 on p2.SchemaName = ISNULL(p1.SchemaName, p2.SchemaName)
and p2.TableName = ISNULL(p1.TableName,p2.TableName)
and p2.IndexName = ISNULL(p1.IndexName,p2.IndexName)
where p2.row_lock_wait_in_ms - ISNULL(p1.row_lock_wait_in_ms,0) > 0
order by RowLockWaitTimeDelta_ms desc


--query stats delta
select
p2.total_elapsed_time - ISNULL(p1.total_elapsed_time,0) as [Duration],
p2.total_worker_time - ISNULL(p1.total_worker_time,0) as [Time on CPU],
(p2.total_elapsed_time - ISNULL(p1.total_elapsed_time,0)) - (p2.total_worker_time - ISNULL(p1.total_worker_time,0)) as [Time Blocked],
p2.total_logical_reads - ISNULL(p1.total_logical_reads,0) as [Reads],
p2.total_logical_writes - ISNULL(p1.total_logical_writes, 0) as [Writes],
p2.total_clr_time -  ISNULL(p1.total_clr_time, 0) as [CLR time],
p2.execution_count -  ISNULL(p1.execution_count,0) as [Executions],
SUBSTRING(qt.text,p2.statement_start_offset/2+1,
		(( CASE WHEN p2.statement_end_offset = -1
		then LEN(CONVERT(NVARCHAR(MAX),qt.text))*2
		ELSE p2.statement_end_offset
		END - p2.statement_start_offset)/2)+1) as SqlText,
qt.text as [Parent Query], --query
DB_Name(qt.dbid) as DatabaseName --database name

from #PreWorkQuerySnapshot p1
right outer join #PostWorkQuerySnapshot p2 on p2.sql_handle = ISNULL(p1.sql_handle,p2.sql_handle)
and p2.statement_start_offset = ISNULL(p1.statement_start_offset, p2.statement_start_offset)
and p2.statement_end_offset = ISNULL(p1.statement_end_offset, p2.statement_end_offset)
cross apply sys.dm_exec_sql_text(p2.sql_handle) as qt
where p2.execution_count != ISNULL(p1.execution_count, 0)
and qt.text not like '--This routine identifier'

drop table #PostWorkIndexCount
drop table #PostWorkQuerySnapshot
drop table #PreWorkIndexCount
drop table #PreWorkQuerySnapshot
