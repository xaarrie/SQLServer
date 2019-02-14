set transaction isolation level read uncommitted

select
es.session_id,
es.login_name,
es.host_name,
est.text,
cn.last_read,
cn.last_write,
es.program_name
from 
sys.dm_exec_sessions es
inner join sys.dm_tran_session_transactions st on es.session_id = st.session_id
inner join sys.dm_exec_connections cn on es.session_id = cn.session_id
cross apply sys.dm_exec_sql_text(cn.most_recent_sql_handle) est
left outer join sys.dm_exec_requests er on st.session_id = er.session_id and er.session_id is null