set transaction isolation level read uncommitted
DECLARE @TableName varchar(max) = ''
SELECT DISTINCT o.name, o.xtype,c.text
FROM syscomments c
INNER JOIN sysobjects o ON c.id=o.id
WHERE c.TEXT LIKE '%'+@TableName+'%'