set transaction isolation level read uncommitted
select
Blocking.session_id as BlockingSessionID,
sess.login_name as BlockingUser,
BlockingSQL.text as BlockingSQL,
Waits.wait_type WhyBlocked,
Blocked.session_id as BlockedSessionID,
USER_NAME(Blocked.user_id) as BlockedUser,
BlockedSQL.text as BlockedSQL,
DB_NAME(Blocked.database_id) as DatabaseName
from sys.dm_exec_connections as Blocking
inner join sys.dm_exec_requests as Blocked
	on Blocking.session_id = Blocked.blocking_session_id
inner join sys.dm_os_waiting_tasks as Waits
	on Blocked.session_id = Waits.session_id
right outer join sys.dm_exec_sessions Sess
	on Blocking.session_id =sess.session_id
CROSS APPLY sys.dm_exec_sql_text(Blocking.most_recent_sql_handle) as BlockingSQL
CROSS APPLY sys.dm_exec_sql_text(Blocked.sql_handle) as BlockedSQL

--------------current database
where Blocked.database_id = DB_ID()
ORDER BY BlockingSessionID, BlockedSessionID