--HERE WE SHOW THE TOP N QUERIES ORDERED BY LAST EXECUTION TIME

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @N integer = 20 --Number of top elements
DECLARE @Text as varchar(max) = '' --TEXT TO SEARCH



SET @Text = '%'+ @Text + '%'
Select Top (@N)
qt.text as [Parent Query],
DB_Name(qp.dbid) as DatabaseName,
qp.query_plan,
qs.last_execution_time
from
sys.dm_exec_query_stats qs
cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
cross apply sys.dm_exec_query_plan(qs.plan_handle) as qp

where
qt.text like @Text
and (qp.dbid = DB_ID() --to restrict query to current database
or qp.dbid is null) --adhoc queries
ORDER BY qs.last_execution_time