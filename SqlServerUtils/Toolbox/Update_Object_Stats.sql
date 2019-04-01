--Update the stats for the objects in the server.
--Used when we had timeouts comparing schemas or publishing with the database project
--Must be executed in the database with problems
DECLARE @SQL nvarchar(MAX) =
	(
		SELECT 
			  N'UPDATE STATISTICS ' 
			  + QUOTENAME(OBJECT_SCHEMA_NAME(i.object_id)) 
			  + N'.' 
			  + QUOTENAME(OBJECT_NAME(i.object_id)) 
			  + N';'
		FROM sys.indexes AS i
		JOIN sys.partitions AS p ON
			p.object_id = i.object_id
			AND p.index_id = i.index_id
		WHERE 
			OBJECTPROPERTYEX(i.object_id, 'IsSystemTable') = 1
			AND i.index_id > 0
			AND p.rows > 0
		FOR XML PATH(''), TYPE).value('.','nvarchar(MAX)'
	);
EXEC sp_executesql @SQL;