--HERE WE SHOW THE STATE OF OUT STATISTICS OF THE CURRENT DATABASE
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

select
ss.name as SchemaName,
st.name as TableName,
s.name as IndexName,
STATS_DATE(s.id,s.indid) AS 'Statistics Last Updated',
s.rowcnt as 'RowCount',
s.rowmodctr as 'Number of Changes',
CAST((CAST(s.rowmodctr as DECIMAL(28,8))/CAST(s.rowcnt as DECIMAL(28,2))*100) AS DECIMAL(28,2)) AS '% RowsChanged'

from
sys.sysindexes s
INNER JOIN sys.tables st ON st.[object_id] = s.[id]
INNER JOIN sys.schemas ss ON ss.[schema_id] = st.[schema_id]
WHERE s.id > 100 AND s.indid > 0 and s.rowcnt >= 500
ORDER BY SchemaName,TableName, IndexName