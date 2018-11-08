if object_id('tempdb..#tmp_loginfo') is not null drop table #tmp_loginfo

declare @c_accountname varchar(1000) = --login name
declare @v_groupname varchar(1000)

create table #tmp_loginfo 
(
	[account name] varchar(1000)
,	type varchar(100)
,	privilege varchar(100)
,	[mapped login name] varchar(1000)
,	[permission path] varchar(1000)
)

declare @groups table 
(
	name varchar(1000)
,	is_processed bit 
)

insert @groups (name, is_processed)
select	p.name, 0
from	sys.database_principals p
where	p.type = 'G'




while exists ( select 1 from @groups where is_processed = 0 )
begin
	select	@v_groupname = g.name
	from	@groups g
	where	g.is_processed = 0

	
	insert into #tmp_loginfo
	exec  master..xp_logininfo @acctname = @v_groupname, @option = 'members'

	update	g
	set		g.is_processed = 1
	from	@groups g
	where	g.name = @v_groupname
end

select	* 
from	#tmp_loginfo t
where	t.[account name] = @c_accountname

-- role for group
select	p1.name db_role_name
	,	p2.name member_name
from	sys.database_role_members rm 
		join sys.database_principals p1 on rm.role_principal_id = p1.principal_id
		join sys.database_principals p2 on rm.member_principal_id  = p2.principal_id
		join #tmp_loginfo t on p2.name = t.[permission path]
where	p1.type = 'R' 
		and t.[account name] = @c_accountname		
order	by p1.name
