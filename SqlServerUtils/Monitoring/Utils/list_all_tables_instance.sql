SET NOCOUNT ON
DECLARE @AllTables TABLE
        (
         ServerName NVARCHAR(200)
        ,DBName NVARCHAR(200)
        ,SchemaName NVARCHAR(200)
        ,TableName NVARCHAR(200)
        )
DECLARE @SearchSvr NVARCHAR(200)
       ,@SearchDB NVARCHAR(200)
       ,@SearchS NVARCHAR(200)
       ,@SearchTbl NVARCHAR(200)
       ,@SQL NVARCHAR(4000)

SET @SearchSvr = NULL  --Search for Servers, NULL for all Servers
SET @SearchDB = NULL  --Search for DB, NULL for all Databases
SET @SearchS = NULL  --Search for Schemas, NULL for all Schemas
SET @SearchTbl = NULL  --Search for Tables, NULL for all Tables

SET @SQL = 'SELECT @@SERVERNAME
        ,''?''
        ,s.name
        ,t.name
         FROM [?].sys.tables t 
         JOIN sys.schemas s on t.schema_id=s.schema_id 
         WHERE @@SERVERNAME LIKE ''%' + ISNULL(@SearchSvr, '') + '%''
         AND ''?'' LIKE ''%' + ISNULL(@SearchDB, '') + '%''
         AND s.name LIKE ''%' + ISNULL(@SearchS, '') + '%''
         AND t.name LIKE ''%' + ISNULL(@SearchTbl, '') + '%''
      -- AND ''?'' NOT IN (''master'',''model'',''msdb'',''tempdb'',''SSISDB'')
           '
-- Remove the '--' from the last statement in the WHERE clause to exclude system tables

INSERT  INTO @AllTables
        (
         ServerName
        ,DBName
        ,SchemaName
        ,TableName
        )
        EXEC sp_MSforeachdb @SQL
SET NOCOUNT OFF
SELECT  *
FROM    @AllTables
ORDER BY 1,2,3,4