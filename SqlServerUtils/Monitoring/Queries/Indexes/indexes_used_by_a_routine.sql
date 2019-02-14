--HERE WE SHOW THE INDEXES USED BY A GIVEN ROUTINE
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

select
SchemaName = ss.name,
TableName = st.name,
IndexName = ISNULL(si.name,''),
IndexType = si.type_desc,
user_updates = ISNULL(ius.user_updates,0),
user_seeks = ISNULL(ius.user_seeks,0),
user_scans = ISNULL(ius.user_scans,0),
user_lookups = ISNULL(ius.user_lookups,0),
ssi.rowcnt,
ssi.rowmodctr,
si.fill_factor
into #IndexStatsPre
from
sys.dm_db_index_usage_stats ius
RIGHT OUTER JOIN sys.indexes si ON ius.[object_id] = si.[object_id] AND ius.index_id = si.index_id
INNER JOIN sys.sysindexes ssi ON si.object_id = ssi.id AND si.name = ssi.name
INNER JOIN sys.tables st ON st.[object_id] = si.[object_id]
INNER JOIN sys.schemas ss ON ss.[schema_id] = st.[schema_id]
WHERE ius.database_id = DB_ID()
AND OBJECTPROPERTY(ius.[object_id],'IsMsShipped') = 0

----------------------------------------------------------------
--HERE GOES THE SENTENCES YOU WANT TO LOOK THE INDEX USAGE FOR
----------------------------------------------------------------




----------------------------------------------------------------

select
SchemaName = ss.name,
TableName = st.name,
IndexName = ISNULL(si.name,''),
IndexType = si.type_desc,
user_updates = ISNULL(ius.user_updates,0),
user_seeks = ISNULL(ius.user_seeks,0),
user_scans = ISNULL(ius.user_scans,0),
user_lookups = ISNULL(ius.user_lookups,0),
ssi.rowcnt,
ssi.rowmodctr,
si.fill_factor
into #IndexStatsPost
from
sys.dm_db_index_usage_stats ius
RIGHT OUTER JOIN sys.indexes si ON ius.[object_id] = si.[object_id] AND ius.index_id = si.index_id
INNER JOIN sys.sysindexes ssi ON si.object_id = ssi.id AND si.name = ssi.name
INNER JOIN sys.tables st ON st.[object_id] = si.[object_id]
INNER JOIN sys.schemas ss ON ss.[schema_id] = st.[schema_id]
WHERE ius.database_id = DB_ID()
AND OBJECTPROPERTY(ius.[object_id],'IsMsShipped') = 0


select
DB_NAME() as DatabaseName,
po.SchemaName,
po.TableName,
po.IndexName,
po.IndexType,
po.user_updates - ISNULL(pr.user_updates,0) as [User Updates],
po.user_seeks - ISNULL(pr.user_seeks,0) as [User Seeks],
po.user_scans - ISNULL(pr.user_scans,0) as [User Scans],
po.user_lookups - ISNULL(pr.user_lookups,0) as [User Lookups],
po.rowcnt - pr.rowcnt as [Rows Inserted],
po.rowmodctr - pr.rowmodctr as [Updates I/U/D],
po.fill_factor

from
#IndexStatsPost po LEFT OUTER JOIN #IndexStatsPre pr
ON pr.SchemaName = po.SchemaName AND pr.TableName = po.TableName AND pr.IndexName = po.IndexName and pr.IndexType = po.IndexType
WHERE ISNULL(pr.user_updates,0)!= po.user_updates
OR ISNULL(pr.user_seeks,0) != po.user_seeks
OR ISNULL(pr.user_scans,0) != po.user_scans
OR ISNULL(pr.user_lookups,0) != po.user_lookups
ORDER BY po.SchemaName, po.TableName, po.IndexName


DROP TABLE #IndexStatsPre
DROP TABLE #IndexStatsPost