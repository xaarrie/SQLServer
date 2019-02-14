set transaction isolation level read uncommitted
--ThisRoutineIdentifier99%
DECLARE @DelayTime varchar(10) = '00:05:00'

select
sql_handle,
plan_handle,
total_elapsed_time,
total_worker_time,
total_logical_reads,
total_logical_writes,
total_clr_time,
execution_count,
statement_start_offset,
statement_end_offset
into #PreWorkSnapshot
from sys.dm_exec_query_stats

WAITFOR DELAY @DelayTime

select
sql_handle,
plan_handle,
total_elapsed_time,
total_worker_time,
total_logical_reads,
total_logical_writes,
total_clr_time,
execution_count,
statement_start_offset,
statement_end_offset
into #PostWorkSnapshot
from sys.dm_exec_query_stats

select
p2.total_elapsed_time -  isnull(p1.total_elapsed_time,0) as [Duration],
p2.total_worker_time - isnull(p1.total_worker_time,0) as [Time on CPU],
(p2.total_elapsed_time - isnull(p1.total_elapsed_time,0))-(p2.total_worker_time - ISNULL(p1.total_worker_time,0)) as [Time Blocked],
p2.total_logical_reads - ISNULL(p1.total_logical_reads,0) as [Reads],
p2.total_logical_writes - ISNULL(p1.total_logical_writes,0) as [Writes],
p2.total_clr_time - ISNULL(p1.total_clr_time,0) as [CLR time],
p2.execution_count - ISNULL(p1.execution_count,0) as [Executions],
SUBSTRING(qt.text,p2.statement_start_offset/2+1,
		(( CASE WHEN p2.statement_end_offset = -1
		then LEN(CONVERT(NVARCHAR(MAX),qt.text))*2
		ELSE p2.statement_end_offset
		END - p2.statement_start_offset)/2)+1) as SqlText,
qt.text as [Parent Query], --query
DB_Name(qp.dbid) as DatabaseName, --database name
qp.query_plan
from #PreWorkSnapshot as p1
right outer join #PostWorkSnapshot as p2 on p2.sql_handle = isnull(p1.sql_handle,p2.sql_handle) and p2.plan_handle = ISNULL(p1.plan_handle, p2.plan_handle)
and p2.statement_start_offset = ISNULL(p1.statement_start_offset, p2.statement_start_offset)
and p2.statement_end_offset = ISNULL(p1.statement_end_offset, p2.statement_end_offset)
cross apply sys.dm_exec_sql_text(p2.sql_handle) as qt
cross apply sys.dm_exec_query_plan(p2.plan_handle) as qp
where p2.execution_count != ISNULL(p1.execution_count,0) and qt.text not like '--ThisRoutineIdentifier99%' 

and (qp.dbid = DB_ID() -- to filter DB actual
or qp.dbid is null) --ad hoc queris
ORDER BY [Duration] DESC





drop table #PostWorkSnapshot
drop table #PreWorkSnapshot