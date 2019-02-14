set transaction isolation level read uncommitted
DECLARE @N integer = 100, --number of elements
 @ImpedancePercent integer = 20, --diference of worker time % change related with io % change
 @WorkerTimeFrom integer = 0

select top (@N) --basada en el tiempo de CPU de la query (worker_time)

qs.execution_count as [Runs],
(qs.total_worker_time - qs.last_worker_time)/(qs.execution_count - 1) as [Avg Time],
qs.last_worker_time as [Last Time],
(qs.last_worker_time - ((qs.total_worker_time - qs.last_worker_time)/ (qs.execution_count - 1))) as [Time Deviation],
case when qs.last_worker_time = 0
then 100
else (qs.last_worker_time - ((qs.total_worker_time - qs.last_worker_time)/ (qs.execution_count - 1))) * 100 
END / 
(((qs.total_worker_time - qs.last_worker_time) / (qs.execution_count -1.0))) as [% Time Deviation],
qs.last_logical_reads + qs.last_logical_writes + qs.last_physical_reads as [Last IO],
((qs.total_logical_reads + qs.total_logical_writes + qs.total_physical_reads ) - 
(qs.last_logical_reads + qs.last_logical_writes + qs.last_physical_reads)) / (qs.execution_count -1 ) as [AVG IO],
SUBSTRING(qt.text,qs.statement_start_offset/2+1,
		(( CASE WHEN qs.statement_end_offset = -1
		then LEN(CONVERT(NVARCHAR(MAX),qt.text))*2
		ELSE qs.statement_end_offset
		END - qs.statement_start_offset)/2)+1) as SqlText,
qt.text as [Parent Query], --query
qp.query_plan,
DB_Name(qp.dbid) as DatabaseName --database name
into #SoloQueries
from sys.dm_exec_query_stats qs
cross apply sys.dm_exec_sql_text(qs.sql_handle) qt
cross apply sys.dm_exec_query_plan(qs.plan_handle) as qp
where qs.execution_count > 1 and qs.total_worker_time != qs.last_worker_time
and qs.last_worker_time > @WorkerTimeFrom

and (qp.dbid = DB_ID() -- to filter DB actual
or qp.dbid is null) --ad hoc queris
order by [% Time Deviation] desc

select top (@N) 
[Runs],
[Avg Time],
[Last Time],
[Time Deviation],
[% Time Deviation],
[Last IO],
[Avg IO],
[Last IO] - [Avg IO] as [IO Deviation],
case when [Avg IO] =0 then 0
else([Last IO] - [Avg IO]) *100/[Avg IO] end as [% IO Deviation],
[SqlText],[Parent Query],query_plan,
[DatabaseName]
into #SlowQueriesByIO
from #SoloQueries
ORDER BY [% Time Deviation]

select TOP (@N)
[Runs],
[Avg Time],
[Last Time],
[Time Deviation],
[% Time Deviation],
[Last IO],
[Avg IO],
[% IO Deviation],
[Impedance] = [% Time Deviation] - [% IO Deviation],
[SqlText],[Parent Query],query_plan,
[DatabaseName]
from #SlowQueriesByIO
where ABS([% Time Deviation]) - ABS([% IO Deviation]) > @ImpedancePercent --se usan los absolutos para evitar que aparezcan aquellas con mejor rendimiento
order by [Impedance]

drop table #SoloQueries
drop table #SlowQueriesByIO