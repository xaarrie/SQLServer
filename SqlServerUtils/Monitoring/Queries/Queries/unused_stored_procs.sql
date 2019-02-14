set transaction isolation level read uncommitted
select s.name, s.type_desc from sys.procedures s left outer join 
sys.dm_exec_procedure_stats d on s.object_id = d.object_id where d.object_id is null
order by s.name