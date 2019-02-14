set transaction isolation level read uncommitted

select

su.session_id, ec.connection_id, es.login_name, es.host_name, st.text as LastQuery, ec.last_read, ec.last_write,es.program_name,
su.user_objects_alloc_page_count,
su.user_objects_dealloc_page_count,
su.internal_objects_alloc_page_count,
su.internal_objects_dealloc_page_count
from sys.dm_db_session_space_usage su
inner join sys.dm_exec_sessions es on su.session_id = es.session_id
left outer join sys.dm_exec_connections ec on su.session_id = ec.most_recent_session_id
outer apply sys.dm_exec_sql_text(ec.most_recent_sql_handle) st
where su.session_id > 50


select
cast (sum(
su.user_objects_alloc_page_count+
su.internal_objects_alloc_page_count)*(8.0/1024.0) as DECIMAL(20,3)) as [SpaceUsed MB],

cast (sum(
su.user_objects_alloc_page_count-
su.user_objects_dealloc_page_count+
su.internal_objects_alloc_page_count-
su.internal_objects_dealloc_page_count)*(8.0/1024.0) as DECIMAL(20,3)) as [SpaceStillUsed MB],
su.session_id, ec.connection_id, es.login_name, es.host_name, st.text as LastQuery, ec.last_read, ec.last_write,es.program_name
from sys.dm_db_session_space_usage su
inner join sys.dm_exec_sessions es on su.session_id = es.session_id
left outer join sys.dm_exec_connections ec on su.session_id = ec.most_recent_session_id
outer apply sys.dm_exec_sql_text(ec.most_recent_sql_handle) st
where su.session_id > 50
group by su.session_id, ec.connection_id, es.login_name, es.host_name, st.text, ec.last_read, ec.last_write,es.program_name
order by [SpaceStillUsed MB]