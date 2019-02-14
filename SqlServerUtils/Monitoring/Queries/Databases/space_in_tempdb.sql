set transaction isolation level read uncommitted
select
sum(isnull(user_object_reserved_page_count,0)+
isnull(internal_object_reserved_page_count,0)+
isnull(version_store_reserved_page_count,0)+
isnull(mixed_extent_page_count,0)+
isnull(unallocated_extent_page_count,0))*(8.0/1024.0) as [Total Size of Tempdb in MB],
sum(isnull(user_object_reserved_page_count,0)+
isnull(internal_object_reserved_page_count,0)+
isnull(version_store_reserved_page_count,0)+
isnull(mixed_extent_page_count,0))*(8.0/1024.0) as [Used Size of Tempdb in MB]
from sys.dm_db_file_space_usage