--with an sqlhandle we can retrieve the text of the query
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
DECLARE @handle NVARCHAR(MAX) = ''--here goes the sqlhandle of the deaddlock ej:'0x02000000d8562f08c7c37de1a33e4c5c8e854c70f845f8550000000000000000000000000000000000000000'
select * from sys.dm_exec_sql_text(CONVERT ( varbinary(64),@handle  ,1)) as T