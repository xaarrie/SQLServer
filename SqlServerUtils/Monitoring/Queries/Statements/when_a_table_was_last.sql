set transaction isolation level read uncommitted
DECLARE @N as integer = 20 --number of elements
DECLARE @Table as nvarchar(255) = N'' --name of the table we want to know when was the last, delete, update or insert



select TOP (@N)
qs.last_execution_time, --last time
SUBSTRING(qt.text,qs.statement_start_offset/2+1,
		(( CASE WHEN qs.statement_end_offset = -1
		then LEN(CONVERT(NVARCHAR(MAX),qt.text))*2
		ELSE qs.statement_end_offset
		END - qs.statement_start_offset)/2)+1) as SqlText,
qt.text as [Parent Query], --query
qp.query_plan,
DB_Name(qp.dbid) as DatabaseName, --database name
qp.dbid
From sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
cross apply sys.dm_exec_query_plan(qs.plan_handle) as qp
where 
(
---------------------------------------------------
--INSERT-------------------------------------------
SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
((CASE WHEN qs.statement_end_offset = -1
THEN LEN(CONVERT(NVARCHAR(Max),qt.text)) *2
else
qs.statement_end_offset
end - qs.statement_start_offset)/2)+1)
LIKE '%INSERT INTO ' + @Table+ '%'
----------------------------------------------------
--UPDATE--------------------------------------------
OR
SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
((CASE WHEN qs.statement_end_offset = -1
THEN LEN(CONVERT(NVARCHAR(Max),qt.text)) *2
else
qs.statement_end_offset
end - qs.statement_start_offset)/2)+1)
LIKE '%DELETE ' + @Table+ '%'
----------------------------------------------------
--DELETE--------------------------------------------
OR
SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
((CASE WHEN qs.statement_end_offset = -1
THEN LEN(CONVERT(NVARCHAR(Max),qt.text)) *2
else
qs.statement_end_offset
end - qs.statement_start_offset)/2)+1)
LIKE '%UPDATE ' + @Table + '%'

--------------------------------------------------
)
----------------------------------------------------------------
and (qp.dbid = DB_ID() or qp.dbid is null) --to restrict query to current database
-----------------------------------------------------------------

ORDER BY qs.last_execution_time DESC