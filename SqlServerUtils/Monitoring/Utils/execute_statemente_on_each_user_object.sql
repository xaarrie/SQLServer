SELECT
--DEFINE THE SENTENCE HERE, YOU CAN USE THE o.[type] to filter user elements, tables, procedures, functions or views
/*    'DROP ' + CASE WHEN  type = 'U' THEN 'TABLE '
                   WHEN  type = 'P' THEN 'PROCEDURE '
                   WHEN  type = 'FN'THEN 'FUNCTION '
                   WHEN  type = 'V'THEN 'VIEW ' END
     + QUOTENAME(s.[name]) + '.' + QUOTENAME(o.[name]) as sentence*/
	 '' as sentence
into #sentences
FROM        sys.objects o 
INNER JOIN  sys.schemas s ON o.[schema_id] = s.[schema_id]
WHERE o.[is_ms_shipped] <> 1
  AND o.[type] IN ('U','P','FN','V')
DECLARE @Sentence varchar(max)
DECLARE sentence_cursor CURSOR FOR   
SELECT sentence  
FROM #sentences


OPEN sentence_cursor  

FETCH NEXT FROM sentence_cursor   
INTO @Sentence

WHILE @@FETCH_STATUS = 0  
BEGIN  
    PRINT ' '  
  
    PRINT @Sentence  
	EXECUTE (@Sentence)
    -- Declare an inner cursor based     
    -- on vendor_id from the outer cursor.  

   
    FETCH NEXT FROM sentence_cursor   
    INTO @Sentence
END   
CLOSE sentence_cursor;  
DEALLOCATE sentence_cursor;  
 
drop table #sentences