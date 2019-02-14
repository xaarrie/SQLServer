set transaction isolation level read uncommitted
DECLARE @N int = 20
select top(@N)
qs.plan_generation_num, --number of recompilations
qs.execution_count,
SUBSTRING(qt.text,qs.statement_start_offset/2+1,
		(( CASE WHEN qs.statement_end_offset = -1
		then LEN(CONVERT(NVARCHAR(MAX),qt.text))*2
		ELSE qs.statement_end_offset
		END - qs.statement_start_offset)/2)+1) as SqlText,
qt.text as [Parent Query], --query
DB_Name(qp.dbid) as DatabaseName, --database name
qs.creation_time,
qs.last_execution_time
from
sys.dm_exec_query_stats as qs
cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
cross apply sys.dm_exec_query_plan(qs.plan_handle) as qp
where (qp.dbid = DB_ID() -- to filter DB actual
or qp.dbid is null) --ad hoc queris
order by plan_generation_num desc