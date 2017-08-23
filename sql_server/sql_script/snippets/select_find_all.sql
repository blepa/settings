SET NOCOUNT ON

DECLARE @strSQL as NVARCHAR(800)
DECLARE @databasename as varchar(200)

DECLARE @search VARCHAR(MAX) = 'Wyst¹pi³ b³ad podczas rezerwacji triad'

SELECT 'Searching For: '''+ @search + '''' as Current_Search

IF OBJECT_ID('tempdb..#FIND_WORKING') IS NOT NULL
DROP TABLE #FIND_WORKING

CREATE TABLE #FIND_WORKING (DatabaseName varchar(200),ObjectName varchar(70), ObjectType varchar(30))

DECLARE Curse CURSOR local fast_forward
FOR
SELECT	name 
FROM	master.dbo.sysdatabases 
WHERE	name  not in ('master', 'msdb', 'model', 'tempdb')

OPEN Curse

FETCH next FROM Curse INTO @databasename

WHILE @@fetch_status = 0
BEGIN
	SET @strSQL= 'use '  + @databasename + '

	insert into #FIND_WORKING
	select distinct
		''' + @databasename + ''',	  
		cast(o.[name] as varchar(40)) as objectname,
		o.type	  --	left(c.text,50) as place
	
	from 
		syscomments c
		inner join
		sysobjects o ON
		c.[id] = o.[id]
	  
	where 
		c.[text] like ''%' +@search+ '%'' 
	order by cast(o.[name] as varchar(40))
	'
	EXEC dbo.sp_executesql @strSQL

	FETCH next FROM Curse INTO @databasename
END
CLOSE Curse
DEALLOCATE Curse

SELECT	DatabaseName, ObjectName, ObjectType
FROM	#FIND_WORKING
ORDER BY 
		DatabaseName,ObjectName