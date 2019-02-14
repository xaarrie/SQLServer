set transaction isolation level read uncommitted
select

DB_NAME(resource_database_id) as DatabaseName,
request_session_id,
resource_type,
case 
	when resource_type = 'OBJECT'
	then OBJECT_NAME(resource_associated_entity_id)
	when resource_type in ('KEY','PAGE','RID')
	then (SELECT OBJECT_NAME(OBJECT_ID)
	from sys.partitions p 
	where p.hobt_id = l.resource_associated_entity_id)
END as resource_type_name,
request_status,
request_mode
from sys.dm_tran_locks l
where request_session_id != @@spid
order by request_session_id