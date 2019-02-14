set transaction isolation level read uncommitted

select 

waits.wait_duration_ms/1000 as WaitInSeconds,
Blocking.session_id as BlockingSessionId,
DB_NAME(Blocked.database_id) as DatabaseName,
Sess.login_name as BlockingUser,
Sess.host_name as BlockingLocation,
BlockingSQL.text as BlockingSQL,
Blocked.session_id as BlockedSessionId,
BlockedSess.login_name as BlockedUser,
BlockedSess.host_name as BlockedLocation,
SUBSTRING(BlockedSQL.text,BlockedReq.statement_start_offset/2+1,
		(( CASE WHEN BlockedReq.statement_end_offset = -1
		then LEN(CONVERT(NVARCHAR(MAX),BlockedSQL.text))*2
		ELSE BlockedReq.statement_end_offset
		END - BlockedReq.statement_start_offset)/2)+1) as [Blocked Individual Query],
waits.wait_type
from
sys.dm_exec_connections as Blocking
inner join sys.dm_exec_requests as Blocked
on Blocking.session_id = Blocked.blocking_session_id
inner join sys.dm_exec_sessions Sess on Blocking.session_id = sess.session_id
inner join sys.dm_tran_session_transactions st on Blocking.session_id = st.session_id
left outer join sys.dm_exec_requests er on st.session_id = er.session_id
inner join sys.dm_os_waiting_tasks as waits on Blocked.session_id = waits.session_id
cross apply sys.dm_Exec_sql_text(Blocking.most_recent_sql_handle) as BlockingSQL
inner join sys.dm_exec_requests as BlockedReq on waits.session_id = BlockedReq.session_id
inner join sys.dm_exec_sessions as BlockedSess on waits.session_id = BlockedSess.session_id
cross apply sys.dm_exec_Sql_text(Blocked.sql_handle) as BlockedSQL
order by WaitInSeconds