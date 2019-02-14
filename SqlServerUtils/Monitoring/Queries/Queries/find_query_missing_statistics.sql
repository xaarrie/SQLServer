set transaction isolation level read uncommitted

DECLARE @N integer = 20 --Number of top elements

select top (@N)
st.text as [Parent Query],
DB_Name(qp.dbid) as [DatabaseName],
cp.usecounts as [Usage Count],
qp.query_plan
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
where CAST(qp.query_plan as NVARCHAR(MAX)) LIKE '%<ColumnsWithNoStatistics>%'

and (qp.dbid = DB_ID() --to look in the current database
or qp.dbid is null) --for adhoc queries
order by cp.usecounts DESC