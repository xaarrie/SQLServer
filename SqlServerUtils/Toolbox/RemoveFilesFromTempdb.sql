--if it does not work restart the sqlserver
USE tempdb;  
GO  
DBCC SHRINKFILE('tempdev2', EMPTYFILE)  
GO  
USE master;  
GO  
ALTER DATABASE tempdb  
REMOVE FILE tempdev2; 
--if still does not work try to resize the file, restart and try the first script
ALTER DATABASE [tempdb] MODIFY FILE (  
NAME = N'tempdev2',  
SIZE = 1024KB );  