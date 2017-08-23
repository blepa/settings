SELECT 
	pt.[instance_name] [db_name]
,	CAST([Data File(s) Size (KB)] * 1.0 / 1024.0 AS decimal(16,2)) [row_size_mb]
,	CAST([Log File(s) Size (KB)] * 1.0 / 1024.0 AS decimal(16,2)) [log_size_mb]
,	CAST([Log File(s) Used Size (KB)] * 1.0 / 1024.0 AS decimal(16,2)) [log_size_used_mb]
,	CAST([Data File(s) Size (KB)] * 1.0 / 1048576.0 AS decimal(16,2)) [row_size_gb]
,	CAST([Log File(s) Size (KB)] * 1.0 / 1048576.0 AS decimal(16,2)) [log_size_gb]
,	CAST([Log File(s) Used Size (KB)] * 1.0 / 1048576.0 AS decimal(16,2)) [log_size_used_gb]
,	[Percent Log Used] log_used_prc
,	log_reuse_wait_desc
FROM 
	(
		SELECT 
			os.counter_name
		,	os.instance_name
		,	os.cntr_value
		,	db.log_reuse_wait_desc
		FROM 
			sys.dm_os_performance_counters os
		INNER JOIN 
			sys.databases db 
			ON os.instance_name = db.name
		WHERE 
			os.counter_name IN 
			( 'Data File(s) Size (KB)' 
			, 'Log File(s) Size (KB)'
			, 'Log File(s) Used Size (KB)'
		    , 'Percent Log Used' 
			) 		
	) AS st
	PIVOT 
	(
		MAX(cntr_value) FOR counter_name IN
		(	[Data File(s) Size (KB)] 
		,	[Log File(s) Size (KB)]
		,	[Log File(s) Used Size (KB)]
		,	[Percent Log Used])
	) AS pt
WHERE 1 = 1
--	AND pt.instance_name = ''
--	AND pt.instance_name IN ('')
ORDER BY 
	pt.[Log File(s) Size (KB)] desc