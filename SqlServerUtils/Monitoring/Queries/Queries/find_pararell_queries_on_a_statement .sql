set transaction isolation level read uncommitted

DECLARE @Text as varchar(max) = '' --TEXT TO SEARCH

SELECT 
SUBSTRING(q.text,qs.statement_start_offset/2+1,
		(( CASE WHEN qs.statement_end_offset = -1
		then LEN(CONVERT(NVARCHAR(MAX),q.text))*2
		ELSE qs.statement_end_offset
		END - qs.statement_start_offset)/2)+1) as SqlText,
q.text as [Parent Query], --query
p.*,
q.*,
qs.*,
qs.total_worker_time/qs.execution_count as avg_worker_time,
cp.plan_handle,
DB_Name(q.dbid) as DatabaseName 
FROM
sys.dm_exec_cached_plans cp
CROSS apply sys.dm_exec_query_plan(cp.plan_handle) p
CROSS apply sys.dm_exec_sql_text(cp.plan_handle) AS q
JOIN sys.dm_exec_query_stats qs
ON qs.plan_handle = cp.plan_handle
WHERE
cp.cacheobjtype = 'Compiled Plan' AND
p.query_plan.value('declare namespace p="http://schemas.microsoft.com/sqlserver/2004/07/showplan";
max(//p:RelOp/@Parallel)', 'float') > 0 and q.text like '%'+@Text+'%'
