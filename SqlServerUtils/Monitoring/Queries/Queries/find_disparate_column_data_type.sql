set transaction isolation level read uncommitted

select
COLUMN_NAME,
[%] = CONVERT(DECIMAL(12,2),COUNT(COLUMN_NAME)*100/COUNT(*) OVER())
into #Prevalence
from INFORMATION_SCHEMA.COLUMNS
GROUP BY COLUMN_NAME

select distinct
c1.Column_Name,
c1.Table_Schema,
c1.Table_Name,
c1.Data_Type,
c1.Character_Maximum_Length,
c1.Numeric_Precision,
c1.Numeric_Scale,
[%]
from INFORMATION_SCHEMA.COLUMNS C1
INNER JOIN INFORMATION_SCHEMA.COLUMNS C2 on C1.COLUMN_NAME = C2.COLUMN_NAME
INNER JOIN #Prevalence p ON p.Column_name = C2.Column_name
where ((C1.Data_type != C2.Data_type) 
or (C1.Character_maximum_length != c2.Character_maximum_length)
or (c1.numeric_precision != c2.numeric_precision)
or (c1.numeric_scale != c2.numeric_scale))
order by [%] desc, c1.column_name, c1.table_schema,c1.table_name

drop table #Prevalence
