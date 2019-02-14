set transaction isolation level read uncommitted
select
instance_name,
counter_name,
cntr_value / 1024.0 as [Size in MB]
from sys.dm_os_performance_counters
where rtrim(object_name) like '%:Databases' and
counter_name in (
'Data File(s) Size (KB)',
'Log File(s) Size (KB)',
'Log File(s) Used Size (KB)')
order by instance_name, counter_name
