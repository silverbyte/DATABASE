exec sp_addextendedproc 'xp_smtp_sendmail','C:\Program Files (x86)\Microsoft SQL Server\80\COM\xpsmtp80.dll'
exec sp_dropextendedproc 'xp_smtp_sendmail'

grant execute on xp_smtp_sendmail  to public

exec master.dbo.xp_smtp_sendmail
@from = 'joe@trans-plus.com',
@to = 'joe@trans-plus.com',
@cc= '',
@subject = 'Mail Subject',
@message = '<h1>Mail ??</h1>',
@type = 'text/html',
@server = 'smtp-relay.gmail.com'


