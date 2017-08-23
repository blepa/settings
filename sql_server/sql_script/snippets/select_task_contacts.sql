select	fc.*
from	dbo.FO_TASK ft 
		join dbo.FO_ISSUE fi on ft.id = fi.IDTask
		join dbo.FO_ISSUE_CHANGE fic on fi.id = fic.IDIssue
		join dbo.FO_CONTACT fc on fic.IDContact = fc.ID
where	ft.ID = 142592554
order	by fc.ID desc