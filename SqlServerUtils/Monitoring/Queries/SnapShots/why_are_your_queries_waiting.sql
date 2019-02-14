set transaction isolation level read uncommitted
--ThisRoutimeIdentifier
DECLARE @N int = 1*60

CREATE TABLE #PerfCounters
(
RunDateTime datetime NOT NULL,
object_name nchar(128) NOT NULL,
counter_name nchar(128) NOT NULL,
instance_name nchar(128) NULL,
cntr_value bigint NOT NULL,
cntr_type int NOT NULL
)

ALTER TABLE #PerfCounters
ADD CONSTRAINT DF_PerfCounters_RunDateTime
DEFAULT(getdate()) for RunDateTime

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
into #PreWorkQuerySnapshot
from sys.dm_exec_query_stats

select
[object_name],[counter_name],[instance_name],[cntr_value],[cntr_type]
into #PreWorkOSSnapShot
from sys.dm_os_performance_counters

select
wait_type,
waiting_tasks_count,
wait_time_ms,
max_wait_time_ms,
signal_wait_time_ms
into #PreWorkWaitStats
from sys.dm_os_wait_stats


while @N > 0
begin
INSERT INTO #PerfCounters
(object_name,counter_name,instance_name,cntr_value,cntr_type)
(select
object_name,counter_name,instance_name,cntr_value,cntr_type
from sys.dm_os_performance_counters)

WAITFOR DELAY '00:00:01'
set @N = @N-1
end


select
wait_type,
waiting_tasks_count,
wait_time_ms,
max_wait_time_ms,
signal_wait_time_ms
into #PostWorkWaitStats
from sys.dm_os_wait_stats

select
[object_name],[counter_name],[instance_name],[cntr_value],[cntr_type]
into #PostWorkOSSnapShot
from sys.dm_os_performance_counters

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
into #PostWorkQuerySnapshot
from sys.dm_exec_query_stats



select
p2.total_elapsed_time - ISNULL(p1.total_elapsed_time,0) as [Duration],
p2.total_worker_time - ISNULL(p1.total_worker_time,0) as [Time on CPU],
(p2.total_elapsed_time -  ISNULL(p1.total_elapsed_time,0)) - (p2.total_worker_time -ISNULL(p1.total_worker_time,0)) as [Time Blocked],
p2.total_logical_reads - ISNULL(p1.total_logical_reads,0) as [Reads],
p2.total_logical_writes -  ISNULL(p1.total_logical_writes,0) as [Writes],
p2.total_clr_time - ISNULL(p1.total_clr_time,0) as [CLR time],
p2.execution_count - ISNULL(p1.execution_count,0) as [Executions],
SUBSTRING(qt.text,p2.statement_start_offset/2+1,
		(( CASE WHEN p2.statement_end_offset = -1
		then LEN(CONVERT(NVARCHAR(MAX),qt.text))*2
		ELSE p2.statement_end_offset
		END - p2.statement_start_offset)/2)+1) as SqlText,
qt.text as [Parent Query], --query
DB_Name(qt.dbid) as DatabaseName
from
#PreWorkQuerySnapshot p1 RIGHT OUTER JOIN #PostWorkQuerySnapshot p2 on p2.sql_handle = ISNULL(p1.sql_handle,p2.sql_handle)
and p2.plan_handle = ISNULL(p1.plan_handle,p2.plan_handle)
and p2.statement_start_offset = ISNULL(p1.statement_start_offset,p2.statement_start_offset)
and p2.statement_end_offset = ISNULL(p1.statement_end_offset,p2.statement_end_offset)
CROSS APPLY sys.dm_exec_sql_text(p2.sql_handle) as qt
where p2.execution_count != ISNULL(p1.execution_count,0)
and qt.text not like '--ThisRoutimeIdentifier%'
------------TO LOOK ONLY IN CURRENT BD, but should look in all beacouse counters are in all
--and qt.dbid = DB_ID()
ORDER BY [Time Blocked] DESC


select
p2.wait_type, --name of the wait time
p2.wait_time_ms - ISNULL(p1.wait_time_ms,0) as wait_time_ms, --total time spent waiting in milliseconds
p2.signal_wait_time_ms - ISNULL(p1.signal_wait_time_ms,0) as signal_wait_time_ms, --total time waiting to get on the CPU, after waiting the original cause of wait
(p2.wait_time_ms - ISNULL(p1.wait_time_ms,0)) - (p2.signal_wait_time_ms - ISNULL(p1.signal_wait_time_ms,0)) as RealWait --the real wait time

from #PreWorkWaitStats p1
RIGHT OUTER JOIN #PostWorkWaitStats p2 on p2.wait_type = ISNULL(p1.wait_type,p2.wait_type)
where p2.wait_time_ms - ISNULL(p1.wait_time_ms,0) > 0
and p2.wait_type not like '%SLEEP'
and p2.wait_type != 'WAITFOR'
ORDER BY RealWait desc

select 
p2.object_name,
p2.counter_name,
p2.instance_name,
ISNULL(p1.cntr_value,0) as InitialValue,
p2.cntr_value as FinalValue,
(p2.cntr_value -  ISNULL(p1.cntr_value,0)) as Change,
(p2.cntr_value - ISNULL(p1.cntr_value,0))*100/p1.cntr_value as [% Change]
from #PreWorkOSSnapShot p1
RIGHT OUTER JOIN #PostWorkOSSnapShot p2 on p2.object_name = ISNULL(p1.object_name,p2.object_name)
and p2.counter_name = ISNULL(p1.counter_name,p2.counter_name) 
and p2.instance_name = ISNULL(p1.instance_name,p2.instance_name)
WHERE p2.cntr_value - ISNULL(p1.cntr_value,0) > 0
and ISNULL(p1.cntr_value,0) != 0
order by [% Change] Desc, Change desc

select * from #PerfCounters
ORDER BY RunDateTime,object_name,counter_name, instance_name

DROP TABLE #PerfCounters
DROP TABLE #PostWorkQuerySnapshot
DROP TABLE #PostWorkWaitStats
DROP TABLE #PreWorkQuerySnapshot
DROP TABLE #PreWorkWaitStats
DROP TABLE #PostWorkOSSnapShot
DROP TABLE #PreWorkOSSnapShot