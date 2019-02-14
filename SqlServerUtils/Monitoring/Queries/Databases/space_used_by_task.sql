set transaction isolation level read uncommitted

set transaction isolation level read uncommitted

select

tu.session_id, ec.connection_id, es.login_name, es.host_name, st.text as LastQuery, ec.last_read, ec.last_write,es.program_name,
tu.user_objects_alloc_page_count,
tu.user_objects_dealloc_page_count,
tu.internal_objects_alloc_page_count,
tu.internal_objects_dealloc_page_count
from sys.dm_db_task_space_usage tu
inner join sys.dm_exec_sessions es on tu.session_id = es.session_id
left outer join sys.dm_exec_connections ec on tu.session_id = ec.most_recent_session_id
outer apply sys.dm_exec_sql_text(ec.most_recent_sql_handle) st
where tu.session_id > 50


select
cast (sum(
tu.user_objects_alloc_page_count+
tu.internal_objects_alloc_page_count)*(8.0/1024.0) as DECIMAL(20,3)) as [SpaceUsed MB],

cast (sum(
tu.user_objects_alloc_page_count-
tu.user_objects_dealloc_page_count+
tu.internal_objects_alloc_page_count-
tu.internal_objects_dealloc_page_count)*(8.0/1024.0) as DECIMAL(20,3)) as [SpaceStillUsed MB],
tu.session_id, ec.connection_id, es.login_name, es.host_name, st.text as LastQuery, 
SUBSTRING(st.text,er.statement_start_offset/2+1,
		(( CASE WHEN er.statement_end_offset = -1
		then LEN(CONVERT(NVARCHAR(MAX),st.text))*2
		ELSE er.statement_end_offset
		END - er.statement_start_offset)/2)+1) as SqlText,
ec.last_read, ec.last_write,es.program_name
from sys.dm_db_task_space_usage tu
inner join sys.dm_exec_sessions es on tu.session_id = es.session_id
left outer join sys.dm_exec_connections ec on tu.session_id = ec.most_recent_session_id
outer apply sys.dm_exec_sql_text(ec.most_recent_sql_handle) st
left outer join sys.dm_exec_requests er on tu.session_id = er.session_id
where tu.session_id > 50
group by tu.session_id, ec.connection_id, es.login_name, es.host_name, st.text, ec.last_read, ec.last_write,es.program_name,
SUBSTRING(st.text,er.statement_start_offset/2+1,
		(( CASE WHEN er.statement_end_offset = -1
		then LEN(CONVERT(NVARCHAR(MAX),st.text))*2
		ELSE er.statement_end_offset
		END - er.statement_start_offset)/2)+1)
		order by [SpaceStillUsed MB]