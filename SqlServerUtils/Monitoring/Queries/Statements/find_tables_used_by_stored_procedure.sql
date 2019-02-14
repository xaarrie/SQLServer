set transaction isolation level read uncommitted
DECLARE @Stored varchar(max) = ''
;WITH stored_procedures AS (
SELECT 
o.name AS proc_name, oo.name AS table_name,
ROW_NUMBER() OVER(partition by o.name,oo.name ORDER BY o.name,oo.name) AS row
FROM sysdepends d 
INNER JOIN sysobjects o ON o.id=d.id
INNER JOIN sysobjects oo ON oo.id=d.depid
WHERE o.xtype = 'P')
SELECT proc_name, table_name FROM stored_procedures
WHERE row = 1
and proc_name like '%'+@Stored+'%'
ORDER BY proc_name,table_name