DECLARE
    @EngineEdition INT = CAST(SERVERPROPERTY(N'EngineEdition') AS INT)


;WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
,planCache
AS(
    SELECT 
        *
    FROM sys.dm_exec_query_stats as qs WITH(NOLOCK)
    CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) as qp
    WHERE qp.query_plan.exist('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex')=1
), analyzedPlanCache
AS(
    SELECT 
        sql_text = T.C.value('(@StatementText)[1]', 'nvarchar(max)')
        ,[impact%] = T.C.value('(./QueryPlan/MissingIndexes/MissingIndexGroup/@Impact)[1]', 'float')
        ,cachedPlanSize = T.C.value('(./QueryPlan/@CachedPlanSize)[1]', 'int')
        ,compileTime = T.C.value('(./QueryPlan/@CompileTime)[1]', 'int')
        ,compileCPU = T.C.value('(./QueryPlan/@CompileCPU)[1]', 'int')
        ,compileMemory = T.C.value('(./QueryPlan/@CompileMemory)[1]', 'int')
        ,database_name = T.C.value('(./QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Database)[1]','sysname')
        ,schema_name = T.C.value('(./QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Schema)[1]','sysname')
        ,object_name = T.C.value('(./QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Table)[1]','sysname')
        ,equality_columns = (
            SELECT 
                DISTINCT REPLACE(REPLACE(tb.col.value('(@Name)[1]', 'sysname'), N']', N''), N'[', N'') + ','
            FROM T.c.nodes('./QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/ColumnGroup') AS T(cg)
                CROSS APPLY T.cg.nodes('./Column') AS tb(col)
            WHERE T.cg.value('(@Usage)[1]', 'sysname') = 'EQUALITY'
            FOR  XML PATH('')
        )
        ,inequality_columns = (
            SELECT 
                DISTINCT REPLACE(REPLACE(tb.col.value('(@Name)[1]', 'sysname'), N']', N''), N'[', N'') + ','
            FROM T.c.nodes('./QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/ColumnGroup') AS T(cg)
                CROSS APPLY T.cg.nodes('./Column') AS tb(col)
            WHERE T.cg.value('(@Usage)[1]', 'sysname') = 'INEQUALITY'
            FOR  XML PATH('')
        )
        ,include_columns = (
            SELECT 
                DISTINCT REPLACE(REPLACE(tb.col.value('(@Name)[1]', 'sysname'), N']', N''), N'[', N'@') + ','
            FROM T.c.nodes('./QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/ColumnGroup') AS T(cg)
                CROSS APPLY T.cg.nodes('./Column') AS tb(col)
            WHERE T.cg.value('(@Usage)[1]', 'sysname') = 'INCLUDE'
            FOR  XML PATH('')
        )
        ,pc.*
    FROM planCache AS pc
        CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS T(C)
    WHERE C.exist('./QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex') = 1
)
SELECT 
    plan_handle
    ,query_plan
    ,query_hash
    ,query_plan_hash
    ,sql_text
    ,[impact%]
    ,cachedplansize
    ,compileTime
    ,compileCPU
    ,compileMemory
    ,object = database_name + '.' + schema_name + '.' + object_name
    ,miss_index_creation = 
            N'CREATE NONCLUSTERED INDEX ' + QUOTENAME(N'IX_' + REPLACE(LEFT(equality_columns, len(equality_columns) - 1), N',', N'_') + '_'
            + REPLACE(LEFT(inequality_columns, len(inequality_columns) - 1), N',', N'_') + '_'
            + REPLACE(LEFT(include_columns, len(include_columns) - 1), N',', N'_'), '[]')
            + N' ON ' + database_name + '.' + schema_name + '.' + object_name 
            + QUOTENAME(
                CASE 
                    WHEN equality_columns is not null and inequality_columns is not null 
                        THEN equality_columns + LEFT(inequality_columns, len(inequality_columns) - 1)
                    WHEN equality_columns is not null and inequality_columns is null 
                        THEN LEFT(equality_columns, len(equality_columns) - 1)
                    WHEN inequality_columns is not null 
                        THEN LEFT(inequality_columns, len(inequality_columns) - 1)
                END
                , '()')
            + CASE 
                    WHEN include_columns is not null 
                    THEN ' INCLUDE ' + QUOTENAME(REPLACE(LEFT(include_columns, len(include_columns) - 1), N'@', N''), N'()')
                    ELSE ''
                END
            + N' WITH (FILLFACTOR = 90'
            + CASE @EngineEdition 
                WHEN 3 THEN N',ONLINE = ON' 
                ELSE ''
                END + ');'
    ,creation_time
    ,last_execution_time
    ,execution_count
    ,total_worker_time
    ,last_worker_time
    ,min_worker_time
    ,max_worker_time
    ,total_physical_reads
    ,last_physical_reads
    ,min_physical_reads
    ,max_physical_reads
    ,total_logical_writes
    ,last_logical_writes
    ,min_logical_writes
    ,max_logical_writes
    ,total_logical_reads
    ,last_logical_reads
    ,min_logical_reads
    ,max_logical_reads
    ,total_clr_time
    ,last_clr_time
    ,min_clr_time
    ,max_clr_time
    ,total_elapsed_time
    ,last_elapsed_time
    ,min_elapsed_time
    ,max_elapsed_time
    ,total_rows
    ,last_rows
    ,min_rows
    ,max_rows
FROM analyzedPlanCache