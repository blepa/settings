declare @vDatabaseName varchar(1000) = 'DataBaseName';

declare @vNewLine varchar(10) = CHAR(13)+CHAR(10);
declare @vCmd varchar(max) = '';

select @vCmd += 'use [master]' + @vNewLine + 'go' + @vNewLine;
select @vCmd += 'alter database ' + @vDatabaseName + @vNewLine + 'set single_user with rollback immediate' + @vNewLine + 'go' + @vNewLine;
select @vCmd += 'drop database ' + @vDatabaseName +  @vNewLine +'go'

print @vCmd;
