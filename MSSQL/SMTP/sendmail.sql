-- Useful Tables
use msdb
-- Contains the bits necessary to interact with SMTP server
select * from msdb.dbo.sysmail_account
-- Contains useful logs to inspect if something goes wrong
select * from msdb.dbo.sysmail_log
-- Contains details of each email sent
select * from msdb.dbo.sysmail_mailitems
-- Contains flags, bits, and values that drive email behavior
select * from msdb.dbo.sysmail_configuration
-- Provides the identifier the sp_send_dbmail proc uses to trigger an email
select * from msdb.dbo.sysmail_profile
-- Associative table between sysmail_profile and sysmail_account
select * from msdb.dbo.sysmail_profileaccount
-- Contains configuration around the SMTP server used to send mail
select * from msdb.dbo.sysmail_server

--Enabling Database Mail
use msdb
exec sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE;  
GO  
exec sp_configure 'Database Mail XPs', 1;  
GO  
RECONFIGURE  
GO 

-- Create a Database Mail account  
EXECUTE msdb.dbo.sysmail_add_account_sp  
    @account_name = 'company.com',  
    @description = 'company account for sending outgoing notifications.',  
    @email_address = 'webmaster@company.com',  
    @display_name = 'Automated Mailer',  
    @mailserver_name = 'smtp-relay.gmail.com',
    @port = 587,
    @enable_ssl = 1,
    @username = 'webmaster@company.com',
    @password = 'password' ;  
GO


-- Create a Database Mail profile  
EXECUTE msdb.dbo.sysmail_add_profile_sp  
    @profile_name = 'Notifications',  
    @description = 'Profile used for sending outgoing notifications using company.com' ;  
GO

-- Add the account to the profile  
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp  
    @profile_name = 'Notifications',  
    @account_name = 'company.com',  
    @sequence_number =1 ;  
GO

/*

https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-send-dbmail-transact-sql?view=sql-server-ver15

sp_send_dbmail [ [ @profile_name = ] 'profile_name' ]  
    [ , [ @recipients = ] 'recipients [ ; ...n ]' ]  
    [ , [ @copy_recipients = ] 'copy_recipient [ ; ...n ]' ]  
    [ , [ @blind_copy_recipients = ] 'blind_copy_recipient [ ; ...n ]' ]  
    [ , [ @from_address = ] 'from_address' ]  
    [ , [ @reply_to = ] 'reply_to' ]   
    [ , [ @subject = ] 'subject' ]   
    [ , [ @body = ] 'body' ]   
    [ , [ @body_format = ] 'body_format' ]  
    [ , [ @importance = ] 'importance' ]  
    [ , [ @sensitivity = ] 'sensitivity' ]  
    [ , [ @file_attachments = ] 'attachment [ ; ...n ]' ]  
    [ , [ @query = ] 'query' ]  
    [ , [ @execute_query_database = ] 'execute_query_database' ]  
    [ , [ @attach_query_result_as_file = ] attach_query_result_as_file ]  
    [ , [ @query_attachment_filename = ] query_attachment_filename ]  
    [ , [ @query_result_header = ] query_result_header ]  
    [ , [ @query_result_width = ] query_result_width ]  
    [ , [ @query_result_separator = ] 'query_result_separator' ]  
    [ , [ @exclude_query_output = ] exclude_query_output ]  
    [ , [ @append_query_error = ] append_query_error ]  
    [ , [ @query_no_truncate = ] query_no_truncate ]   
    [ , [ @query_result_no_padding = ] @query_result_no_padding ]   
    [ , [ @mailitem_id = ] mailitem_id ] [ OUTPUT ]  
*/


EXEC msdb.dbo.sp_send_dbmail  
    @profile_name = 'Notifications',  
    @recipients = '<user@company.com>',  
	@body = '
	<div style="font-size:2em">
		HELLO
		<img src="cid:tplogo.png" style="display:block" />
		<img src="https://www.company.ca/img/company.png" style="display:block" />
	</div>
	',  
	@body_format = 'HTML',
    @subject = 'Test Email from Synergize',
	@from_address = '<no-reply@company.com>',
	@reply_to = '<no-reply@company.com>',
	@file_attachments = '\\Tpservicesvr\synergize\2017\SHIPDOCS\1\36\46\Syn3217027.tif;\\Tpservicesvr\synergize\2017\SHIPDOCS\1\36\46\Syn3217036.tif;\\Tpservicesvr\synergize\2017\SHIPDOCS\1\36\47\Syn3217526.tif;'
	

	
	--select * from SHIPDOCS.dbo.main where in_docid = 'Syn3217027'
	--select * from SHIPDOCS.dbo.storedev 
	
	select 
		m.In_DocLocation
		,substring(m.In_DocLocation,1,  CHARINDEX('\',m.In_DocLocation,0)-1 ) inMappedDrNo
		, p.In_MappedDrName
		, substring(m.In_DocLocation,CHARINDEX('\',m.In_DocLocation,0),len(In_DocLocation))
		, p.In_MappedDrName + substring(m.In_DocLocation,CHARINDEX('\',m.In_DocLocation,0),len(In_DocLocation)) + '\' + m.In_DocID + '.' + m.In_DocFileExt as filelocation
	from SHIPDOCS.dbo.main m 
		left outer join SHIPDOCS.dbo.storedev p on substring(m.In_DocLocation,1,  CHARINDEX('\',m.In_DocLocation,0)-1 ) = p.In_MappedDrNo
	where in_docid = 'Syn3217027'
	

	select 
 p.In_MappedDrName + substring(m.In_DocLocation,CHARINDEX('\',m.In_DocLocation,0),len(In_DocLocation)) + '\' + m.In_DocID + '.' + m.In_DocFileExt as filelocation
	from SHIPDOCS.dbo.main m 
		left outer join SHIPDOCS.dbo.storedev p on substring(m.In_DocLocation,1,  CHARINDEX('\',m.In_DocLocation,0)-1 ) = p.In_MappedDrNo
	

	/*
	--check security config
	EXEC sp_configure 'Ole Automation Procedures';
	GO
	--enable security config
	sp_configure 'show advanced options', 1;
	GO
	RECONFIGURE;
	GO
	sp_configure 'Ole Automation Procedures', 1;
	GO
	RECONFIGURE;
	GO


	---HTTP GET 
	DECLARE @status int
	DECLARE @responseText as table(responseText nvarchar(max))
	DECLARE @res as Int;
	DECLARE @url as nvarchar(1000) = 'https://api.company.ca/bookingstatus/LT943995'
	EXEC sp_OACreate 'MSXML2.ServerXMLHTTP', @res OUT
	EXEC sp_OAMethod @res, 'open', NULL, 'GET',@url,'false'
	EXEC sp_OAMethod @res, 'send'
	EXEC sp_OAGetProperty @res, 'status', @status OUT
	INSERT INTO @ResponseText (ResponseText) EXEC sp_OAGetProperty @res, 'responseText'
	EXEC sp_OADestroy @res
	SELECT @status, responseText FROM @responseText
	*/




-------- create procedure to send emails -------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		JOE CAVALIERE
-- Create date: 20210714
-- Description:	SEND SYNERGIZE DOCS BY EMAIL
/*
DECLARE @RETV AS INT
DECLARE @RETT AS VARCHAR(500)
EXEC JCP_EMAILDOCS 
	'LT943995'
	,'user@company.COM'
	,'Email From Procedure'
	,@RETV OUTPUT	--@RETVAL INT = 0 OUTPUT,
	,@RETT OUTPUT	--@RETTXT VARCHAR(500) = '' OUTPUT

SELECT @RETV,@RETT
*/
-- =============================================
ALTER PROCEDURE JCP_EMAILDOCS 
	@Bill_Key as varchar(20),
	@TO AS VARCHAR(4000),
	@SUBJECT AS VARCHAR(4000),
	@RETVAL INT = 0 OUTPUT,
	@RETTXT VARCHAR(4000) = '' OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON
	DECLARE @DOCS CURSOR
	DECLARE @FILE as varchar(4000)
    DECLARE @FILES as varchar(4000)
	SET @FILES = ''
	declare @Counter int
	set @Counter = 0


    SET @DOCS = CURSOR FOR
		select 
 			p.In_MappedDrName + substring(m.In_DocLocation,CHARINDEX('\',m.In_DocLocation,0),len(In_DocLocation)) + '\' + m.In_DocID + '.' + m.In_DocFileExt + ';'
		from SHIPDOCS.dbo.main m 
			left outer join SHIPDOCS.dbo.storedev p on substring(m.In_DocLocation,1,  CHARINDEX('\',m.In_DocLocation,0)-1 ) = p.In_MappedDrNo      
		WHERE M.BILL_KEY = @Bill_Key
    OPEN @DOCS 
    FETCH NEXT FROM @DOCS INTO @FILE

    WHILE @@FETCH_STATUS = 0
    BEGIN
      /*
         YOUR ALGORITHM GOES HERE   
      */
	  set @Counter = @Counter + 1
	  set @FILES = @FILES + @FILE

      FETCH NEXT FROM @DOCS INTO @FILE 
    END; 
    CLOSE @DOCS 
    DEALLOCATE @DOCS	


	set @FILES = LEFT(@FILES, LEN(@FILES) - 1)
	
	DECLARE @EMAILBODY as VARCHAR(8000);
	set @EMAILBODY = '
	<div style="font-size:2em">
		There are '+ str(@Counter) +' Files in this email		
		<img src="https://www.company.ca/img/company.png" style="display:block" />
	</div>
	'

	EXEC msdb.dbo.sp_send_dbmail  
    @profile_name = 'Notifications',  
    @recipients = @TO,  
	@body = @EMAILBODY,  
	@body_format = 'HTML',
    @subject = @SUBJECT,
	@from_address = '<no-reply@company.com>',
	@reply_to = '<no-reply@company.com>',
	@file_attachments = @FILES


	SET @RETVAL = @Counter
	SET @RETTXT = @FILES
	return

END
GO
