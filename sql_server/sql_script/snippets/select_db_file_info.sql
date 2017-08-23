select	t2.*
from	(
			select	t.file_type
				,	t.file_name	
				,	t.file_group_name
				,	t.physical_name
				,	t.size_mb	
				,	t.spaceused_mb
				,	(t.size_mb - t.spaceused_mb) free_space_mb
				,	cast((t.size_mb / 1024.0) as decimal(10,2)) size_gb
				,	cast((t.spaceused_mb / 1025) as decimal(10,2)) spaceused_gb
				,	cast(((t.size_mb - t.spaceused_mb) / 1024.0 ) as decimal(10,2)) free_space_gb
				,	cast(((t.size_mb - t.spaceused_mb) / (t.size_mb) * 100) as decimal(10,2)) free_space_prc	
				,	t.growth
				
			from	(

						select	df.type_desc file_type
							,	df.name file_name
							,	fg.name file_group_name
							,	df.physical_name
							,	cast(cast(df.size as decimal(10,2))/cast(128.0 as decimal(10,2)) as decimal(10,2)) size_mb							
							,	cast(cast(fileproperty(df.name, 'spaceused') as decimal(10,2)) / cast(128.0 as decimal(10,2)) as decimal(10,2)) spaceused_mb						
							
							,	case growth
									when 0 then 'disabled'
									else 'auto'
								end growth				
						from	sys.database_files df
								left join sys.filegroups fg on df.data_space_id = fg.data_space_id			
								
								
								--sys.allocation_units au on filegroup_name(au.data_space_id) = fg.name
					) t
			) t2
order	by t2.free_space_mb desc


SELECT
FILEGROUP_NAME(AU.data_space_id) AS FileGroupName,
OBJECT_NAME(Parti.object_id) AS TableName,
ind.name AS ClusteredIndexName,
AU.total_pages/128 AS TotalTableSizeInMB,
AU.used_pages/128 AS UsedSizeInMB,
AU.data_pages/128 AS DataSizeInMB
FROM sys.allocation_units AS AU
INNER JOIN sys.partitions AS Parti ON AU.container_id = CASE WHEN AU.type in(1,3) THEN Parti.hobt_id ELSE Parti.partition_id END
LEFT JOIN sys.indexes AS ind ON ind.object_id = Parti.object_id AND ind.index_id = Parti.index_id 
--where FILEGROUP_NAME(AU.data_space_id) = 'PRIMARY'
ORDER BY TotalTableSizeInMB DESC


