--Get the deadlocks from the system_health extended events and the sqltext for each of the process of the deadlock.
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
select Creation_Date,
--Extend_Event,
VictimIDs, ProcessID, ParentSqlText,
		SUBSTRING(ParentSqlText,stmtstart/2+1,
		(( CASE WHEN stmtend is null
		then LEN(CONVERT(NVARCHAR(MAX),ParentSqlText))*2
		ELSE stmtend
		END - stmtstart)/2)+1) as SqlText,
		handle,
		stmtstart,
		stmtend
		/*--TO KNOW THE LENGTH OF THE XML BEACOUSE THE MAX THAT WILL BE SHOWED IS 4MB
		,DATALENGTH(Extend_Event) AS xml_length_bytes,
		ROUND(DATALENGTH(Extend_Event)/1024., 1) AS xml_length_kb,
		ROUND(DATALENGTH(Extend_Event)/1024./1024,1) AS xml_length_MB
		*/
 from (
SELECT    xed.value('@timestamp', 'datetime') as Creation_Date,
        xed.query('.') AS Extend_Event, 
		V.VictimIDs,
		Process.node.value('(@id)[1]','nvarchar(max)') as ProcessID,
		T.text as ParentSqlText
		
		, 
		Process.node.value('(executionStack/frame/@sqlhandle)[1]','nvarchar(max)') as handle,
		Process.node.value('(executionStack/frame/@stmtstart)[1]','nvarchar(max)') as stmtstart,
		Process.node.value('(executionStack/frame/@stmtend)[1]','nvarchar(max)') as stmtend					
FROM    (   
 SELECT    CAST([target_data] AS XML) AS Target_Data
            FROM    sys.dm_xe_session_targets AS xt
                    INNER JOIN sys.dm_xe_sessions AS xs
                    ON xs.address = xt.event_session_address
            WHERE    xs.name = N'system_health'
                    AND xt.target_name = N'ring_buffer')
AS XML_Data 
CROSS APPLY Target_Data.nodes('RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEventData(xed)
 OUTER APPLY xed.nodes('data/value/deadlock/process-list/process') as Process(node)
OUTER APPLY (select text from sys.dm_exec_sql_text(CONVERT ( varbinary(64),Process.node.value('(executionStack/frame/@sqlhandle)[1]','nvarchar(max)')  ,1)) as SqlText) as T
OUTER APPLY(
SELECT  
        STUFF((SELECT '\r\n' + B.victim.value('(@id)[1]', 'NVARCHAR(MAX)')
               FROM   X.victimlist.nodes('./victimProcess') B ( victim )
               FOR XML PATH(''),TYPE).value('.', 'NVARCHAR(MAX)'),
              1, 4, '') AS VictimIDs
FROM    xed.nodes('data/value/deadlock/victim-list') X ( victimlist )
) as V) as Data
ORDER BY Creation_Date DESC





