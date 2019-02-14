set transaction isolation level read uncommitted

select 
name as DatabaseName
,is_auto_create_stats_on as AutoCreateStatistics
,is_auto_update_stats_on as AutoUpdateStatistics
,is_auto_update_stats_async_on as AutoUpdateStatisticsAsync
from sys.databases
order by databasename