
;with sql_handle_convert_table(row_id,schema_name/*,t_sql_handle,t_display_option,t_display_optionIO,t_sql_handle_text*/
,t_SPRank,t_obj_name,t_obj_type,t_SQLStatement,t_execution_count,t_plan_generation_num,t_last_execution_time,t_avg_worker_time
,t_total_worker_time,t_last_worker_time,t_min_worker_time,t_max_worker_time,t_avg_logical_reads,t_total_logical_reads
,t_last_logical_reads,t_min_logical_reads,t_max_logical_reads,t_avg_logical_writes,t_total_logical_writes,t_last_logical_writes
,t_min_logical_writes,t_max_logical_writes,t_avg_logical_IO,t_total_logical_IO,t_last_logical_IO,t_min_logical_IO
,t_max_logical_IO
)
as
(
      Select top 100 percent
      ROW_NUMBER() OVER (ORDER BY s3.name, s1.sql_handle)
      ,case when sch.name is null then '' else '['+sch.name+'].' end as schema_name
--    ,       sql_handle
--    ,       sql_handle as chart_display_option 
--    ,       sql_handle as chart_display_optionIO 
--    ,       master.dbo.fn_varbintohexstr(sql_handle)
      ,       dense_rank() over (order by s2.objectid) as SPRank 
      ,       s3.name as [Obj Name]
      ,       s3.type as [Obj Type]
      ,       (select top 1 substring(text,(s1.statement_start_offset+2)/2, (case when s1.statement_end_offset = -1  then len(convert(nvarchar(max),text))*2 else s1.statement_end_offset end - s1.statement_start_offset) /2  ) from sys.dm_exec_sql_text(s1.sql_handle)) as [SQL Statement]
      ,       execution_count
      ,       plan_generation_num
      ,       last_execution_time
      ,       ((total_worker_time+0.0)/execution_count)/1000 as [avg_worker_time]
      ,       total_worker_time/1000.0
      ,       last_worker_time/1000.0
      ,       min_worker_time/1000.0
      ,       max_worker_time/1000.0
      ,       ((total_logical_reads+0.0)/execution_count) as [avg_logical_reads]
      ,       total_logical_reads
      ,       last_logical_reads
      ,       min_logical_reads
      ,       max_logical_reads
      ,       ((total_logical_writes+0.0)/execution_count) as [avg_logical_writes]
      ,       total_logical_writes
      ,       last_logical_writes
      ,       min_logical_writes
      ,       max_logical_writes
      ,       ((total_logical_writes+0.0)/execution_count + (total_logical_reads+0.0)/execution_count) as [avg_logical_IO]
      ,       total_logical_writes + total_logical_reads
      ,       last_logical_writes +last_logical_reads
      ,       min_logical_writes +min_logical_reads
      ,       max_logical_writes + max_logical_reads 
      from    sys.dm_exec_query_stats s1 
      cross apply sys.dm_exec_sql_text(sql_handle) as  s2 
      inner join sys.objects s3  on ( s2.objectid = s3.object_id ) 
      left outer join sys.schemas sch on(s3.schema_id = sch.schema_id) 
      where s2.dbid = db_id()
		and  s3.name = 'Monitoring_PM_Errors_V2'
		and s1.last_execution_time > '2017-07-11 16:30:00'
      order by  s3.name, s1.sql_handle
)
select * from sql_handle_convert_table order by t_avg_worker_time desc