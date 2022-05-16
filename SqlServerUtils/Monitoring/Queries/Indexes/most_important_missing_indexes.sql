--HERE WE SHOW THE TOP N MISSING INDEXES ORDERED BY COST DESCENDING
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
DECLARE @N integer = 20

SELECT TOP (@N)* from
(select
ROUND(s.avg_total_user_cost * s.avg_user_impact * (s.user_seeks + s.user_scans),0) as [Total Cost],
d.[statement] as [Table Name],
equality_columns,
inequality_columns,
included_columns
FROM
sys.dm_db_missing_index_groups g
INNER JOIN sys.dm_db_missing_index_group_stats s
	ON s.group_handle = g.index_group_handle
INNER JOIN sys.dm_db_missing_index_details d
	ON d.index_handle = g.index_handle
where database_id = DB_ID() --To restrict the query only to the current database
) as T order by [Total Cost] desc