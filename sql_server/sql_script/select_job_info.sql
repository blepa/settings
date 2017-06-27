if object_id('tempdb..#tmp_job') is not null
	drop table #tmp_job

if object_id('tempdb..#tmp_job_2') is not null
	drop table #tmp_job_2

if object_id('tempdb..#tmp_job_history') is not null
	drop table #tmp_job_history

declare	@vstart_date varchar(8) = '20170404'
declare @vstop_date varchar(8)  = '20170405'

declare @vstart_datetime datetime = '2017-04-04 00:00:00'
declare @vstop_datetime datetime = '2017-04-04 12:00:00'

declare @tjob_list table 
(
	job_name varchar(max)
)

select	jh.*
	,	cast(null as datetime) start_datetime
	,	cast(null as datetime) stop_datetime
	,	cast(null as char(8)) duration_time
into	#tmp_job_history
from	[msdb].[dbo].[sysjobhistory] jh with(nolocK)
where	jh.run_date between isnull(@vstart_date, '19000101') and isnull(@vstop_date, '99991231')

update	t
set		t.start_datetime = msdb.dbo.agent_datetime(t.run_date, t.run_time) 
	,	t.stop_datetime = dateadd(second, datediff(second,msdb.dbo.agent_datetime(t.run_date, '0'),msdb.dbo.agent_datetime(t.run_date, t.run_duration)), msdb.dbo.agent_datetime(t.run_date, t.run_time))
	,	t.duration_time = right(stuff(stuff(stuff(right(replicate('0', 8) + CAST(t.run_duration as varchar(8)), 8), 3, 0, ':'), 6, 0, ':'), 9, 0, ':'), 8)
from	#tmp_job_history t

delete	t
from	#tmp_job_history t
where	t.start_datetime not between isnull(@vstart_datetime,'1900-01-01') and isnull(@vstop_datetime,'9999-12-31')

/*
select	count(1) history_count
from	#tmp_job_history th
where	th.step_name != '(Job outcome)'
*/

select	--distinct
		jh.instance_id job_history_instance_id
	,	j.job_id
	,	j.name job_name
	,	case
			when jh.run_status = 0 then 'Failed'
			when jh.run_status = 1 then 'Succeeded'
			when jh.run_status = 2 then 'Retry'
			when jh.run_status = 3 then 'Canceled'
		end job_run_status
	,	jh.start_datetime job_start_date
	,	jh.stop_datetime job_stop_date	
	,	datediff(second,jh.start_datetime,jh.stop_datetime)  job_duration_sec
	,	jh.run_duration job_duration
	,	jh.duration_time job_duration_time
	,	j.start_step_id
	,	jsh.instance_id step_instance_id
	,	js.step_id
	,	js.step_name
	,	case
			when jsh.run_status = 0 then 'Failed'
			when jsh.run_status = 1 then 'Succeeded'
			when jsh.run_status = 2 then 'Retry'
			when jsh.run_status = 3 then 'Canceled'
		end step_run_status		
	,	jsh.start_datetime step_start_date
	,	jsh.stop_datetime step_stop_date
	,	datediff(second,jsh.start_datetime,jsh.stop_datetime) step_duration_sec
	,	jsh.run_duration step_duration
	,	right(stuff(stuff(stuff(right(replicate('0', 8) + CAST(jh.run_duration as varchar(8)), 8), 3, 0, ':'), 6, 0, ':'), 9, 0, ':'), 8) step_duration_time
into	#tmp_job
from	
	[msdb].[dbo].[sysjobs] j
	join
		#tmp_job_history jh	on j.job_id = jh.job_id and jh.step_name = '(Job outcome)'
	join 
		[msdb].[dbo].[sysjobsteps] js on j.job_id = js.job_id
	join 
		#tmp_job_history jsh on js.job_id = jsh.job_id and js.step_id = jsh.step_id
where 
	1 = 1		
	and jsh.start_datetime between jh.start_datetime and jh.stop_datetime

/*
select	count(1)
from	#tmp_job
*/

select	t.job_id
	,	t.job_name	
	,	t.job_run_status
	,	convert(varchar(19),t.job_start_date,121) job_start_date
	,	convert(varchar(19),t.job_stop_date,121) job_stop_date
	,	t.job_duration_time
	,	t.step_name
	,	t.step_run_status
	,	convert(varchar(19),t.step_start_date,121) step_start_date
	,	convert(varchar(19),t.step_stop_date,121) step_stop_date
	,	t.step_duration_time
into	#tmp_job_2 
from	#tmp_job t
where	1 = 1 
		--and t.job_start_date > '2017-03-01'
		--and t.job_stop_date < '2017-03-02'
		--and t.job_name in ('')
order	by t.job_duration_time desc 

select	dense_rank() over (order by t.job_id) job_number,
		t.* 
from	#tmp_job_2 t
