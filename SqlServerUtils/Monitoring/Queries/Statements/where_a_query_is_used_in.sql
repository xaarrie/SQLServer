--HERE WE SHOW THE TOP N QUERIES CONTAINING THE SPECIFIED TEXT

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @N integer = 20 --Number of top elements
DECLARE @Text as varchar(max) = '' --TEXT TO SEARCH



SET @Text = '%'+ @Text + '%'
Select Top (@N)

qt.text as [Parent Query],
DB_Name(qp.dbid) as DatabaseName,
qp.query_plan,
	SUBSTRING(qt.text,qs.statement_start_offset/2+1,
		(( CASE WHEN qs.statement_end_offset = -1
		then LEN(CONVERT(NVARCHAR(MAX),qt.text))*2
		ELSE qs.statement_end_offset
		END - qs.statement_start_offset)/2)+1) as SqlText

from
sys.dm_exec_query_stats qs
cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
cross apply sys.dm_exec_query_plan(qs.plan_handle) as qp

where

SUBSTRING(qt.text,qs.statement_start_offset/2+1,
		(( CASE WHEN qs.statement_end_offset = -1
		then LEN(CONVERT(NVARCHAR(MAX),qt.text))*2
		ELSE qs.statement_end_offset
		END - qs.statement_start_offset)/2)+1) like @Text 

		and (qp.dbid = DB_ID() --to restrict query to current database
		or qp.dbid is null) --adhoc queries