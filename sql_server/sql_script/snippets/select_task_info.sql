USE MilleDesk
GO


/*&
P000018230
P000018231
*/

DECLARE @vIdTask INT = 1437475
DECLARE @CIF VARCHAR(10)-- = 'P000018231'

DECLARE @tTasks TABLE 
(
	TaskId INT
)

INSERT INTO @tTasks(TaskId)
SELECT	DISTINCT FT.ID
FROM	dbo.FO_TASK	FT
WHERE	1 = 1
		AND FT.CIF = ISNULL(@CIF, FT.CIF)
		AND FT.ID = ISNULL(@vIdTask, FT.ID)
		--AND FT.IDTaskStatus != 'FCLSD'


SELECT	
	'FO_TASK' TableName
,	CTTTD.TaskTypeCode
,	dbo.CheckCampaign(FT.IDTaskDefinition) CheckCampaign
,	FT.CreationDate, *
FROM	
	dbo.FO_TASK FT WITH(NOLOCK) 
JOIN 
	dbo.COM_TASK_TYPE_TASK_DEFINITION CTTTD WITH(NOLOCK) ON FT.IDTaskDefinition = CTTTD.IDTaskDefinition
WHERE 1 = 1	
	AND FT.ID IN (SELECT TaskId FROM @tTasks)
	--AND FT.IDTaskStatus = 'ACTV'
ORDER BY 
	FT.ID

SELECT
	'FO_TASK_PROPERTY' TableName
,	FTP.ID
,	FTP.IDTask
,	FTP.PropertyCode
,	FTP.PropertyValue
,	FTP.Hidden
,	dbo.Translate(NULL, FTP.IDPropertyName) IDPropertyNameTr
,	dbo.Translate(NULL, FTP.IDPropertyValue) IDPropertyValueTr
,	FTP.CreationDate	
,	'###'
,	FTP.*
FROM
	dbo.FO_TASK_PROPERTY FTP WITH(NOLOCK)
JOIN
	dbo.FO_TASK FT WITH(NOLOCK) ON FTP.IDTask = FT.ID
WHERE 1 = 1
	AND FT.ID IN (SELECT TaskId FROM @tTasks)
ORDER BY 
	FT.ID
,	FTP.ID

SELECT
	'FO_TASK_PROPERTY_CHANGE' TableName
,	FTPC.*
FROM
	FO_TASK_PROPERTY_CHANGE FTPC
JOIN
	dbo.FO_TASK FT WITH(NOLOCK) ON FTPC.IDTask = FT.ID
WHERE 1 = 1
	AND FT.ID IN (SELECT TaskId FROM @tTasks)
ORDER BY
	FTPC.IDTask
,	FTPC.ID

SELECT 
	'FO_TASK_CHANGE' TableName
,	FTC.*
FROM
	dbo.FO_TASK_CHANGE FTC WITH(NOLOCK)
JOIN
	dbo.FO_TASK FT WITH(NOLOCK) ON FTC.IDTask = FT.ID
WHERE 1 = 1
	AND FT.ID IN (SELECT TaskId FROM @tTasks)
ORDER BY 
	FT.ID
,	FTC.ID 

SELECT
	'FO_ISSUE' TableName
,	FI.ID IDIssue
,	CIDO.IDOrigin
,	CIDO.IDIssueDefinitionOriginType
,	dbo.Translate(NULL, FID.IDName) IssueName
,	dbo.Translate(NULL, FID.IDExternalName) ExternalName
,	FID.IsATM
,	FID.IsMillenet
,	FI.*
FROM
	dbo.FO_ISSUE FI WITH(NOLOCK)
JOIN
	dbo.COM_ISSUE_DEFINITION_ORIGIN CIDO WITH(NOLOCK) ON FI.IDIssueDef = CIDO.IDIssueDefinition
JOIN
	dbo.FO_ISSUE_DEFINITION FID WITH(NOLOCK) ON FI.IDIssueDef = FID.ID
JOIN
	dbo.FO_TASK FT WITH(NOLOCK) ON FI.IDTask = FT.ID
WHERE 1 = 1

	AND FT.ID IN (SELECT TaskId FROM @tTasks)
ORDER BY  
	FT.ID
,	FI.ID

SELECT
	'FO_ISSUE_PROPERTY' TableName	
,	FIP.ID
,	FT.ID IDTask
,	FIP.IDIssue
,	FIP.PropertyCode
,	FIP.PropertyValue
,	FIP.Hidden
,	dbo.Translate(NULL, FIP.IDPropertyName) IDPropertyNameTr
,	dbo.Translate(NULL, FIP.IDPropertyValue) IDPropertyValueTr
,	FIP.CreationDate	
,	'###'
,	FIP.*
FROM
	dbo.FO_ISSUE_PROPERTY FIP WITH(NOLOCK)
JOIN
	dbo.FO_ISSUE FI WITH(NOLOCK) ON FIP.IDIssue = FI.ID
JOIN
	dbo.FO_TASK FT WITH(NOLOCK) ON FI.IDTask = FT.ID	
WHERE 1 = 1
	AND FT.ID IN (SELECT TaskId FROM @tTasks)
ORDER BY  
	FT.ID
,	FI.ID
,	FIP.ID

SELECT
	'FO_ISSUE_PROPERTY_CHANGE' TableName
,	FIPC.*
FROM
	dbo.FO_ISSUE_PROPERTY_CHANGE FIPC WITH(NOLOCK)
JOIN
	dbo.FO_ISSUE FI WITH(NOLOCK) ON FIPC.IDIssue = FI.ID
JOIN
	dbo.FO_TASK FT WITH(NOLOCK) ON FI.IDTask = FT.ID	
WHERE 1 = 1
	AND FT.ID IN (SELECT TaskId FROM @tTasks)
ORDER BY  
	FT.ID
,	FI.ID
,	FIPC.IDIssue
,	FIPC.ID


SELECT
	'FO_TASK_RULE_LOG' TableName
,	FTRL.*
FROM
	dbo.FO_TASK_RULE_LOG FTRL WITH(NOLOCK)
JOIN
	dbo.FO_TASK FT WITH(NOLOCK) ON FTRL.TaskID = FT.ID
WHERE 1 = 1
	AND FT.ID IN (SELECT TaskId FROM @tTasks)	
ORDER BY  
	FT.ID
,	FTRL.ID

SELECT
	'FO_TASK_RULE_PARAMETERS' TableName
,	FTRL.RuleCode 
,	FTRP.*
FROM
	dbo.FO_TASK_RULE_LOG FTRL WITH(NOLOCK)
JOIN
	dbo.FO_TASK FT WITH(NOLOCK) ON FTRL.TaskID = FT.ID
JOIN 
	dbo.COM_TASK_RULE_ORIGIN CTRO WITH(NOLOCK) ON FTRL.RuleCode = CTRO.BOCode
JOIN
	dbo.FO_TASK_RULE_PARAMETERS FTRP WITH(NOLOCK) ON CTRO.TaskRuleID = FTRP.IDTaskRule
WHERE 1 = 1
	AND FT.ID IN (SELECT TaskId FROM @tTasks)	
ORDER BY  
	FT.ID
,	FTRL.ID

SELECT	
	'FO_TASK_MESSAGE' TableName
,	CTTTD.TaskTypeCode
,	dbo.CheckCampaign(FT.IDTaskDefinition) CheckCampaign
,	FT.CreationDate
,	FTM.*
FROM	
	dbo.FO_TASK FT WITH(NOLOCK) 
JOIN 
	dbo.COM_TASK_TYPE_TASK_DEFINITION CTTTD WITH(NOLOCK) ON FT.IDTaskDefinition = CTTTD.IDTaskDefinition
JOIN
	dbo.FO_TASK_MESSAGE FTM WITH(NOLOCK) ON FT.ID = FTM.IDTask
WHERE 1 = 1	
	AND FT.ID IN (SELECT TaskId FROM @tTasks)
	--AND FT.IDTaskStatus = 'ACTV'
ORDER BY 
	FT.ID