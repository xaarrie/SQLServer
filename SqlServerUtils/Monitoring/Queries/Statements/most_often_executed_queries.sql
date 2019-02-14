--HERE WE SHOW THE TOP N MOST OFTEN USED QUERIES

DECLARE @N integer = 20 --Number of top elements


Select Top (@N)
qs.execution_count,
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

where (qp.dbid = DB_ID() --to restrict query to current database
or qp.dbid is null) --ad hoc queries
ORDER BY  qs.execution_count desc
