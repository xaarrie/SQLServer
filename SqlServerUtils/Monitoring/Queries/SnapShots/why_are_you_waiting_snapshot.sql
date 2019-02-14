set transaction isolation level read uncommitted

DECLARE @DelayTime varchar(10) = '00:01:00'

select
wait_type, --name of the wait time
wait_time_ms, --total time spent waiting in milliseconds
signal_wait_time_ms --total time waiting to get on the CPU, after waiting the original cause of wait
into #PreWorkWaitStats
from sys.dm_os_wait_stats

WAITFOR DELAY @DelayTime

select
wait_type, --name of the wait time
wait_time_ms, --total time spent waiting in milliseconds
signal_wait_time_ms --total time waiting to get on the CPU, after waiting the original cause of wait
into #PostWorkWaitStats
from sys.dm_os_wait_stats


select
p2.wait_type, --name of the wait time
p2.wait_time_ms - ISNULL(p1.wait_time_ms,0) as wait_time_ms, --total time spent waiting in milliseconds
p2.signal_wait_time_ms - ISNULL(p1.signal_wait_time_ms,0) as signal_wait_time_ms, --total time waiting to get on the CPU, after waiting the original cause of wait
(p2.wait_time_ms - ISNULL(p1.wait_time_ms,0)) - (p2.signal_wait_time_ms - ISNULL(p1.signal_wait_time_ms,0)) as RealWait --the real wait time

from #PreWorkWaitStats p1
RIGHT OUTER JOIN #PostWorkWaitStats p2 on p2.wait_type = ISNULL(p1.wait_type,p2.wait_type)
where p2.wait_time_ms - ISNULL(p1.wait_time_ms,0) > 0
and p2.wait_type not like '%SLEEP'
and p2.wait_type != 'WAITFOR'
ORDER BY RealWait desc

drop table #PreWorkWaitStats
drop table #PostWorkWaitStats

--CXPACKET -> if the value of this wait is greater thatn 10% or 5% in OLPT it may need correcting. See the DOP or the Cost Threshold for parallelism

--LCK_x -> task waitint on a locked resource. Blocking problems. Often side effect of inappropiate transaction isolation level or long running transactions.
--Can also relate to memory shortage or excessive IO

--ASYNC_IO_COMPLETION -> waiting for async io to finish. Disk subsystem may be suboptimal. Move files/filegroups to less used drives.
--Ivestigate queries with most IO and longest blocking. consider appropiate missing indexes, checl for table or full scan on tables

--ASYNC_NETWORK_IO -> Network issues between SQLServer and the client or app is procesing results inneficiently.

--LATCH_x-> Short term synchronization objects(light locks). Internal contention on internal caches, cached data pages and other in memory objets. Usually memory problems

--PAGELATCH_x->Synchronize access to buffer pages. Indicates cache contention

--PAGEIOLATCH_x-> Waiting for datapage IO to complete. IO system is busy. Tupically disk to memory problems

--IO_Completion->Waiting for no data page IO operations to complete.Disk subsystem may be suboptimal. Investigate bulk inserts. Check for 
--the growth of the database files. Check queries with most IO. Investigate missing indexes. Check sys.dm_io_virtual_file_stats to target specific files fot stalls7

--WRITELOG -> Waiting for the log flush to finish. Transaction commmits or a checkpoint is taken. Check log files on sys.dm_io_virtual_file_stats fot stalls.
--Consider moving log files to less used drives

--SOS_SCHEDULER_YIELD -> When a task voluntarily yields the scheduler to another task. High value indicates CPU pressure.

--SQLTRACE_BUFFER_FLUSH -> SQL Trace Task pauses between flushes. If user initiated traces are not active this value represents the default trace.
--This can be used as a bemchmark against which is the impact of other waits compared.