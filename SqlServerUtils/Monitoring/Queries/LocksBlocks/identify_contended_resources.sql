set transaction isolation level read uncommitted

select
tl1.resource_type,
DB_NAME(tl1.resource_database_id) as DatabaseName,
tl1.resource_associated_entity_id,
tl1.request_session_id,
tl1.request_mode,
tl1.request_status,
case 
	when tl1.resource_type = 'OBJECT'
	then OBJECT_NAME(tl1.resource_associated_entity_id)
	when tl1.resource_type in ('KEY','PAGE','RID')
	then (SELECT OBJECT_NAME(OBJECT_ID)
	from sys.partitions p 
	where p.hobt_id = tl1.resource_associated_entity_id)
END as resource_type_name,
t.text as ParentQuery,
SUBSTRING(t.text,r.statement_start_offset/2+1,
		(( CASE WHEN r.statement_end_offset = -1
		then LEN(CONVERT(NVARCHAR(MAX),t.text))*2
		ELSE r.statement_end_offset
		END - r.statement_start_offset)/2)+1) as SqlText
from
sys.dm_tran_locks as tl1
inner join sys.dm_tran_locks as tl2 on tl1.resource_associated_entity_id = tl1.resource_associated_entity_id
and tl1.request_status <> tl2.request_status
and (tl1.resource_description = tl2.resource_description or (tl1.resource_description is null and tl2.resource_description is null))
inner join sys.dm_exec_connections c on tl1.request_session_id = c.most_recent_session_id
cross apply sys.dm_exec_sql_text(c.most_recent_sql_handle) t
left outer join sys.dm_exec_requests r on c.connection_id = r.connection_id
order by tl1.resource_associated_entity_id, tl1.request_status