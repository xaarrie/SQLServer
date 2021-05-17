DECLARE @name varchar(max), @definition varchar(max)
DECLARE @destination varchar(max) = ''
DECLARE c_views  CURSOR  FOR
select o.name, 
replace(
replace(
    replace(
        replace(
            replace(definition,'[RPS2017].',@destination),
        '[rps2017].',@destination),
    'CREATE VIEW','ALTER VIEW'),
'CREATE FUNCTION','ALTER FUNCTION')
,'CREATE PROCEDURE','ALTER PROCEDURE')

 

as sentence
from sys.objects     o
join sys.sql_modules m on m.object_id = o.object_id
where o.type in('V','FN','IF','P','TF')

 

OPEN c_views  

 

FETCH NEXT FROM c_views   
INTO @name, @definition  

 

WHILE @@FETCH_STATUS = 0  
BEGIN
PRINT @name
begin try
exec (@definition)
end try
begin catch
print 'Error ' + @name
end catch

 

exec ('select top 1 * from ['+@name+']')
FETCH NEXT FROM c_views   
    INTO @name, @definition  
END   
CLOSE c_views;  
DEALLOCATE c_views;  