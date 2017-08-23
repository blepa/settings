select	master.dbo.fn_varbintohexstr(convert(varbinary(16), job_id))
	,	j.*
from	msdb.dbo.sysjobs j 
where	master.dbo.fn_varbintohexstr(convert(varbinary(16), job_id)) in ('0xE9D99933B6B3B6459127CB62D22DC306', '0x6CB49EC4CD42D148BE4BB22FD0ABD38E')--, '0xC0F9C9A67581BF448A7E0A3AB96BBAA6', '0xE9D99933B6B3B6459127CB62D22DC306')



