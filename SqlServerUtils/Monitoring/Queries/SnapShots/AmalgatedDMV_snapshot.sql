set transaction isolation level read uncommitted
--This routine identifier AMALGATEDDMV_snapshot
DECLARE @DelayTime varchar(10) = '00:05:00'
--index counters
select
index_group_handle,
index_handle,
avg_total_user_cost, avg_user_impact, user_seeks, user_scans
into #PreWorkMissingIndexes
from sys.dm_db_missing_index_groups g
inner join sys.dm_db_missing_index_group_stats s on s.group_handle = g.index_group_handle

--query stats counters
select 
sql_handle, plan_handle, total_elapsed_time, total_worker_time, total_logical_reads, total_logical_writes,
total_clr_time, execution_count, statement_start_offset,statement_end_offset
into #PreWorkQuerySnapshot
from sys.dm_exec_query_stats

--OS counters
select 
object_name,counter_name, instance_name,cntr_value, cntr_type
into #PreWorkOSSnapshot
from sys.dm_os_performance_counters

--wait stats counters
select 
wait_type,
waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms
into #PreWorkWaitStats
from sys.dm_os_wait_stats

WAITFOR DELAY @DelayTime

--wait stats counters
select 
wait_type,
waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms
into #PostWorkWaitStats
from sys.dm_os_wait_stats

--OS counters
select 
object_name,counter_name, instance_name,cntr_value, cntr_type
into #PostWorkOSSnapshot
from sys.dm_os_performance_counters

--query stats counters
select 
sql_handle, plan_handle, total_elapsed_time, total_worker_time, total_logical_reads, total_logical_writes,
total_clr_time, execution_count, statement_start_offset,statement_end_offset
into #PostWorkQuerySnapshot
from sys.dm_exec_query_stats

--index counters
select
index_group_handle,
index_handle,
avg_total_user_cost, avg_user_impact, user_seeks, user_scans
into #PostWorkMissingIndexes
from sys.dm_db_missing_index_groups g
inner join sys.dm_db_missing_index_group_stats s on s.group_handle = g.index_group_handle
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
and qt.text not like '--This routine identifier AMALGATEDDMV_snapshot'

--wait stats delta
select
p2.wait_time_ms - ISNULL(p1.wait_time_ms,0) as wait_time_ms,
p2.signal_wait_time_ms - ISNULL(p1.signal_wait_time_ms,0) as signal_wait_time_ms,
((p2.wait_time_ms - ISNULL(p1.wait_time_ms,0))-(p2.signal_wait_time_ms - ISNULL(p1.signal_wait_time_ms,0))) as RealWait,
p2.wait_type
from #PreWorkWaitStats p1
right outer join #PostWorkWaitStats p2 on p2.wait_type = ISNULL(p1.wait_type,p2.wait_type)
where p2.wait_time_ms - ISNULL(p1.wait_time_ms,0) > 0
and p2.wait_type not like '%SLEEP%'
and p2.wait_type != 'WAITFOR'
order by RealWait desc

--missing indexes delta
select
round((p2.avg_total_user_cost - ISNULL(p1.avg_total_user_cost,0))
* (p2.avg_user_impact - ISNULL(p1.avg_user_impact,0))
* ((p2.user_seeks - ISNULL(p1.user_seeks,0))
+ (p2.user_scans - ISNULL(p1.user_scans,0))),0) as [Total Cost],
p2.avg_user_impact - ISNULL(p1.avg_user_impact,0) as avg_user_impact,
p2.user_seeks - ISNULL(p1.user_seeks,0) as user_seeks,
p2.user_scans - ISNULL(p1.user_scans,0) as user_scans,
d.statement as TableName,
d.equality_columns,
d.inequality_columns,
d.included_columns
from #PreWorkMissingIndexes p1 right outer join #PostWorkMissingIndexes p2
on
p2.index_group_handle = ISNULL(p1.index_group_handle,p2.index_group_handle) and
p2.index_handle = ISNULL(p1.index_handle,p2.index_handle)
inner join sys.dm_db_missing_index_details d
on p2.index_handle = d.index_handle
where p2.avg_total_user_cost - ISNULL(p1.avg_total_user_cost,0) > 0
or p2.avg_user_impact -ISNULL(p1.avg_user_impact,0) > 0
or p2.user_seeks - ISNULL(p1.user_seeks,0) > 0
or p2.user_scans - ISNULL(p1.user_scans,0) > 0
order by [Total Cost] desc

--OS delta
select
p2.object_name, p2.counter_name,p2.instance_name,
ISNULL(p1.cntr_value,0) as InitialValue,
p2.cntr_value as FinalValue,
p2.cntr_value - ISNULL(p1.cntr_value,0) as Change,
(p2.cntr_value - ISNULL(p1.cntr_value,0))*100/p1.cntr_value as [% Change]
from
#PreWorkOSSnapshot p1 right outer join #PostWorkOSSnapshot p2
on p2.object_name = ISNULL(p1.object_name,p2.object_name)
and p1.counter_name = ISNULL(p1.counter_name,p2.counter_name)
and p2.instance_name = ISNULL(p1.instance_name,p2.instance_name)
where p2.cntr_value - ISNULL(p1.cntr_value,0) > 0
and ISNULL(p1.cntr_value,0) != 0
order by [% Change] desc, Change desc

drop table #PostWorkMissingIndexes
drop table #PostWorkOSSnapshot
drop table #PostWorkQuerySnapshot
drop table #PostWorkWaitStats
drop table #PreWorkMissingIndexes
drop table #PreWorkOSSnapshot
drop table #PreWorkQuerySnapshot
drop table #PreWorkWaitStats
