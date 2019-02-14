set transaction isolation level read uncommitted
DECLARE @N int = 20 --number of seconds to wait
CREATE TABLE #PerfCounters
(
RunDateTime datetime NOT NULL,
object_name nchar(128) NOT NULL,
counter_name nchar(128) NOT NULL,
instance_name nchar(128) NULL,
cntr_value bigint NOT NULL,
cntr_type int NOT NULL
)

ALTER TABLE #PerfCounters
ADD CONSTRAINT DF_PerfCounters_RunDateTime
DEFAULT(getdate()) for RunDateTime

while @N > 0
begin
INSERT INTO #PerfCounters
(object_name,counter_name,instance_name,cntr_value,cntr_type)
(select
object_name,counter_name,instance_name,cntr_value,cntr_type
from sys.dm_os_performance_counters)

WAITFOR DELAY '00:00:01'
set @N = @N-1
end


select * from #PerfCounters
ORDER BY RunDateTime,object_name,counter_name, instance_name

DROP TABLE #PerfCounters