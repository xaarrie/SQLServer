--HERE WE SHOW THE TOP N CPU USING QUERIES

DECLARE @N integer = 20 --Number of top elements


Select Top (@N)
CAST(qs.total_worker_time/1000000.0 as DECIMAL(28,2)) as [Total CPU time (s)],
CAST(qs.total_worker_time*100.0/qs.total_elapsed_time as DECIMAL(28,2)) as [% CPU],
CAST((qs.total_elapsed_time - qs.total_worker_time)*100.0 /qs.total_elapsed_time as DECIMAL(28,2)) as [% Waiting],
qs.execution_count,
CAST((qs.total_worker_time/1000000.0/qs.execution_count) as DECIMAL(28,2)) as [Average Duration (s)],
qt.text as [Parent Query],
DB_Name(qp.dbid) as DatabaseName,
qp.query_plan,
	SUBSTRING(qt.text,qs.statement_start_offset/2+1,
		(( CASE WHEN qs.statement_end_offset = -1
		then LEN(CONVERT(NVARCHAR(MAX),qt.text))*2
		ELSE qs.statement_end_offset
		END - qs.statement_start_offset)/2)+1) as SqlText

from
sys.dm_exec_query_stats qs
cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
cross apply sys.dm_exec_query_plan(qs.plan_handle) as qp

where
qs.total_elapsed_time > 0 
and (qp.dbid = DB_ID() --to restrict query to current database
or qp.dbid is null) --ad hoc queries
ORDER BY [Total CPU time (s)] desc
