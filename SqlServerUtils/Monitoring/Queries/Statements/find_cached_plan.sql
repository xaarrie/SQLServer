--HERE WE SHOW THE TOP N CACHED PLANS WITH A GIVEN TEXT ON IT
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @N integer = 20 --Number of top elements
DECLARE @Text as varchar(max) = '' --TEXT TO SEARCH



SET @Text = '%'+ @Text + '%'
Select Top (@N)
cp.plan_handle,
st.text as [SQL],
cp.cacheobjtype,
COALESCE(DB_Name(qp.dbid),DB_Name(CAST(pa.value as int)) + '*', 'Resource') as [DatabaseName],
cp.usecounts as [Plan Usage],
qp.query_plan
from
sys.dm_exec_cached_plans cp
cross apply sys.dm_exec_sql_text(cp.plan_handle) as st
cross apply sys.dm_exec_query_plan(cp.plan_handle) as qp
cross apply sys.dm_exec_plan_attributes(cp.plan_handle) as pa
where pa.attribute = 'dbid' and st.text like @Text
and (qp.dbid = DB_ID() --to restrict query to current database
or qp.dbid is null --adhoc queries
)