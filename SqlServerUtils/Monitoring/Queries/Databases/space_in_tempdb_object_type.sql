set transaction isolation level read uncommitted
select
sum(isnull(user_object_reserved_page_count,0)) *(8.0/1024.0) as [User Objects MB], 
sum(isnull(internal_object_reserved_page_count,0))*(8.0/1024.0) as [Internal Objects MB] ,
sum(isnull(version_store_reserved_page_count,0))*(8.0/1024.0) as [Version Store Objects MB] ,
sum(isnull(mixed_extent_page_count,0))*(8.0/1024.0) as [Mixed Extent Objects MB] ,
sum(isnull(unallocated_extent_page_count,0))*(8.0/1024.0) as [Unallocated Objects MB]

from sys.dm_db_file_space_usage