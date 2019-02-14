set transaction isolation level read uncommitted;

WITH cQueryStats
AS (
SELECT qs.plan_handle
,MAX(qs.execution_count) as execution_count
,SUM(qs.execution_count) as execution_count_for_dop
,SUM(qs.total_worker_time) as total_worker_time
,SUM(qs.total_logical_reads) as total_logical_reads
,SUM(qs.total_elapsed_time) as total_elapsed_time
,SUM(qs.total_dop) as total_dop

FROM sys.dm_exec_query_stats qs
GROUP BY qs.plan_handle
)
SELECT OBJECT_NAME(p.objectid, p.dbid) as [object_name] ,qs.execution_count,qs.execution_count_for_dop
,qs.total_worker_time
,qs.total_logical_reads
,qs.total_elapsed_time
,qs.total_dop
,p.query_plan
,q.text
,cp.plan_handle,
p.query_plan.value('declare namespace p="http://schemas.microsoft.com/sqlserver/2004/07/showplan";max(//p:RelOp/@Parallel)', 'float') as HasParallelPlan
into
#QueryInformation
FROM cQueryStats qs
INNER JOIN sys.dm_exec_cached_plans cp ON qs.plan_handle = cp.plan_handle
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) p
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) as q
WHERE cp.cacheobjtype = 'Compiled Plan'

ORDER BY qs.total_worker_time/qs.execution_count DESC

select
sum(qs.total_worker_time) as total_worker_time,
sum(case when qs.HasParallelPlan = 0 then total_worker_time else 0 end) as nonparallel_total_worker_time,
sum(case when qs.HasParallelPlan > 0 then total_worker_time else 0 end) as parallel_total_worker_time,
(cast(sum(case when qs.HasParallelPlan = 0 then total_worker_time else 0 end) as decimal(20,4))/cast(sum(qs.total_worker_time) as decimal(20,4)) )*100 as nonparallel_workertime_percentage,
(cast(sum(case when qs.HasParallelPlan > 0 then total_worker_time else 0 end) as decimal (20,4))/cast(sum(qs.total_worker_time) as decimal(20,4)) )*100 as parallel_workertime_percentage,

sum(qs.execution_count) as total_execution_count,
sum(case when qs.HasParallelPlan = 0 then execution_count else 0 end) as nonparallel_execution_count,
sum(cast(case when qs.HasParallelPlan = 0 then total_dop else 0 end as decimal(20,4))) as nonparallel_total_dop,
sum(case when qs.HasParallelPlan > 0 then execution_count else 0 end) as parallel_execution_count,
sum(cast(case when qs.HasParallelPlan > 0 then total_dop else 0 end as decimal(20,4))) as parallel_total_dop,
(cast(sum(case when qs.HasParallelPlan = 0 then execution_count else 0 end) as decimal(20,4))/cast(sum(qs.execution_count) as decimal(20,4)) )*100 as nonparallel_execution_count_percentage,
(cast(sum(case when qs.HasParallelPlan > 0 then execution_count else 0 end) as decimal (20,4))/cast(sum(qs.execution_count) as decimal(20,4)) )*100 as parallel_execution_count_percentage,

sum(cast(case when qs.HasParallelPlan = 0 then total_dop else 0 end as decimal(20,4)))/sum(cast(case when qs.HasParallelPlan = 0 then execution_count_for_dop else 0 end as decimal(20,4))) as nonparallel_avg_dop,
sum(cast(case when qs.HasParallelPlan > 0 then total_dop else 0 end as decimal(20,4)))/sum(cast(case when qs.HasParallelPlan > 0 then execution_count_for_dop else 0 end as decimal(20,4))) as parallel_avg_dop

from #QueryInformation as qs

drop table #QueryInformation