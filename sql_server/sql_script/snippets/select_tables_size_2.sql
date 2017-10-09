
if object_id('tempdb..#tmp_table_size') is not null drop table #tmp_table_size
if object_id('tempdb..#table_size') is not null drop table #table_size
if object_id('tempdb..#tmp_table_size_agg') is not null drop table #tmp_table_size_agg


select	s.Name AS schema_name,
		t.NAME AS table_name,    
		p.rows AS row_count,
		a.total_pages, 
		a.used_pages
into	#tmp_table_size   
from    sys.tables t with(nolock)
		join sys.indexes i with(nolock) ON t.object_id = i.object_id
		join sys.partitions p with(nolock) ON i.object_id = p.object_id AND i.index_id = p.index_id
		join sys.allocation_units a with (nolock) ON p.partition_id = a.container_id
		join sys.schemas s with(nolock) ON t.schema_id = s.schema_id
WHERE 1 = 1  
		and t.is_ms_shipped = 0
		and i.object_id > 255 
		and t.type = 'U'
--		and s.name =  'ods_icbs'
--		and t.name = 'BEN001P'

create nonclustered index ix_tmp_table_size__schema_name_table_name_row_count on #tmp_table_size(schema_name,table_name,row_count)

select	t.schema_name, t.table_name, row_count, sum(total_pages) total_pages, sum(used_pages) used_pages
into	#tmp_table_size_agg
from	#tmp_table_size t
group	by t.schema_name, t.table_name, row_count

drop table #tmp_table_size

select	'[' + t.schema_name + '].[' + t.table_name + ']' table_name_full,
		t.row_count,
		cast((((t.total_pages * 8.0) / 1024.0) / 1024.0) as decimal(10,2)) total_space_gb,
		cast((((t.used_pages * 8.0) / 1024.0) / 1024.0) as decimal(10,2)) used_space_gb,
		cast((((t.total_pages * 8.0) / 1024.0) / 1024.0) as decimal(10,2)) - cast((((t.used_pages * 8.0) / 1024.0) / 1024.0) as decimal(10,2)) unused_space_gb,
		cast(((t.total_pages * 8.0) / 1024.0) as decimal(10,2)) total_space_mb,
		cast(((t.used_pages * 8.0) / 1024.0) as decimal(10,2)) used_space_mb,
		cast(((t.total_pages * 8.0) / 1024.0) as decimal(10,2)) - cast(((t.used_pages * 8.0) / 1024.0) as decimal(10,2)) unused_space_mb,	
		(t.total_pages * 8) total_space_kb,
		(t.used_pages * 8) used_pages_kb,
		(t.total_pages * 8) - (t.used_pages * 8) unused_space_kb,
		t.schema_name,
		t.table_name,
		t.total_pages,
		t.used_pages		
into	#table_size
from	#tmp_table_size_agg t


select	t.table_name_full, t.schema_name, t.table_name
	,	sum(t.total_space_gb) total_space_gb
	,	sum(t.used_space_gb) used_space_gb
	,	sum(t.unused_space_gb) unused_space_gb
	,	sum(t.total_space_mb) total_space_mb
	,	sum(t.used_space_mb) used_space_mb
	,	sum(t.unused_space_mb) unused_space_mb
	,	sum(t.total_space_kb) total_space_kb
	,	sum(t.used_pages_kb) used_pages_kb
	,	sum(t.unused_space_kb) unused_space_kb
	,	sum(t.used_pages) used_pages
	,	sum(t.total_pages) total_pages
	,	sum(t.row_count) row_count	
from	#table_size t
--where	t.table_name_full = '[dbo].[bik_result_SAS]'
group   by t.table_name_full, t.schema_name, t.table_name
order	by t.table_name_full


--exec sp_spaceused N'[dbo].[bik_result_SAS]'

