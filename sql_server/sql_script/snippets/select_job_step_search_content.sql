USE msdb
GO

SELECT	Job.name AS JobName,
		Job.enabled AS ActiveStatus,
		JobStep.step_name AS JobStepName,
		JobStep.command AS JobCommand
FROM	sysjobs Job
		INNER JOIN sysjobsteps JobStep ON Job.job_id = JobStep.job_id 
WHERE	JobStep.command LIKE '%search_string%'  --You can change here what you are searching for