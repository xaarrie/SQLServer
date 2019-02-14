set transaction isolation level read uncommitted
select
es.session_id, es.host_name, es.login_name,--who is running the query
er.status,
DB_NAME(qp.dbid) as DatabaseName,
SUBSTRING(qt.text,er.statement_start_offset/2+1,
		(( CASE WHEN er.statement_end_offset = -1
		then LEN(CONVERT(NVARCHAR(MAX),qt.text))*2
		ELSE er.statement_end_offset
		END - er.statement_start_offset)/2)+1) as SqlText,
qt.text as [Parent Query], --query
es.program_name,
er.start_time,
qp.query_plan,
--until here what queries are running
er.wait_type,
er.total_elapsed_time,
er.cpu_time,
er.logical_reads,
--until here resources that are using or waiting
er.blocking_session_id,
er.open_transaction_count,
er.last_wait_type,
er.percent_complete
--details of blocking or transactions
from sys.dm_exec_requests as er
inner join sys.dm_exec_sessions as es on es.session_id = er.session_id
cross apply sys.dm_exec_sql_text(er.sql_handle) as qt
cross apply sys.dm_exec_query_plan(er.plan_handle) as qp
where es.is_user_process = 1
and es.session_id not in (@@SPID)
and (qp.dbid = DB_ID() -- to filter DB actual
or qp.dbid is null) --ad hoc queris
order by es.session_id