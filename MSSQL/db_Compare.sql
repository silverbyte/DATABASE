/* 	Database comparison script
	Created by Dan Wunder
	02/27/2001 */

SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
DECLARE @srcsrv   		varchar(30)
DECLARE @Targetsrv  	varchar(30)
DECLARE @srcDb 		varchar(30)
DECLARE @TargetDb 		varchar(30)
DECLARE @srcSApwd 		varchar(30)
DECLARE @TargetSApwd 	varchar(30)
DECLARE @TargetConn 	varchar(50)
DECLARE @cmd1 			varchar (512)
DECLARE @cmd2 			varchar (512)
DECLARE @targetsqlver 	int
DECLARE @skipregister	int
DECLARE @remaccset		int


set @srcsrv='sourceserver'		/*Change these variables */
set @targetsrv='targetserver'	/*Change these variables */
set @srcdb='sourcedb'		/*Change these variables */
set @targetdb='comparetodb'		/*Change these variables */
set @srcsapwd=null		/*Change these variables */
set @targetsapwd=''		/*Change these variables */
set @cmd1='''c:\sf'''
set @targetsqlver=70
set @skipregister=0
set @remaccset=0
if  @targetsapwd is not null
	set @targetconn='''isql -S'+@targetsrv+' -Usa'+' -P'+@targetsapwd+' -d'+@targetdb+' -q '
else 
	set @targetconn='''isql -S'+@targetsrv+' -Usa'+' -P'+' -d'+@targetdb+' -q '

/* Check version of source server */

set @cmd1=@@version
set @cmd2='%6.50%'
if  @cmd2 like @cmd1 
	Begin
		if @targetsrv=@srcsrv goto Get65Local
		else
		Begin
			select 'The source server must be SQL 7.0 or higher'
			goto veryend
		End
	End
else
	if @targetsrv=@srcsrv goto Get70or2kLocal

/* Check if current session is connected to the source server/database */

if (@@servername not like @srcsrv) or ((db_name() not like @srcdb))
	begin
		Select ('This procedure must be run from a session connected to the source server and database')
		goto veryend
	end

/*Skip server registration step if source/target servers are the same */

if ((select srvname from master..sysservers where srvname=@targetsrv) is not null) set @skipregister=1

/* This section establishes a relationship between the two servers */

/* Register source server on target server if necessary */

set @cmd1='''echo if ((select srvname from master..sysservers where srvname="'+@srcsrv+'") is null) exec("sp_addserver '+@srcsrv+'") > c:\sf'''
exec ('master..xp_cmdshell '+@cmd1+',no_output')
exec ('master..xp_cmdshell '+@targetconn+'-ic:\sf'''+',no_output')

/* Add a temporary login/alias to target server/database */

if @targetsapwd is null
	Begin  
		Set @cmd1='''isql -S'+@targetsrv+' -Usa'+' -P'+' -d'+@targetdb+' -q '+'"sp_addlogin ''''scratchlogin'''','''''+'xyz123'+''''','+''''''+@targetdb+''''+'''"'''
		set @cmd2='''isql -S'+@targetsrv+' -Usa'+' -P'+' -d'+@targetdb+' -q '+'"sp_addalias ''scratchlogin'',dbo"'''
	end
else
	begin
		set @cmd1=@targetconn+'"sp_addlogin ''''scratchlogin'''','''''+'xyz123'+''''','+''''''+@targetdb+'''''"'''
		set @cmd2=@targetconn+'"sp_addalias ''''scratchlogin'''',dbo"'''
	end

exec ('master..xp_cmdshell '+@cmd1+',no_output')
exec ('master..xp_cmdshell '+@cmd2+',no_output') 

if @skipregister=0
	begin
		exec ('sp_addlinkedserver '+@targetsrv) 				/* Adds target server as a linked server */
		create table ##tempt2 (w varchar(35),x varchar(35),y varchar(35),z int)
		set @cmd1='%data access%'							/* Checks if 'data access' option is set */
		insert into ##tempt2 exec('sp_helpserver '+@targetsrv)
		if ((select y from ##tempt2 where y like @cmd1) is null)
			begin
				set @cmd2='sp_serveroption '''+@targetsrv+''',''data access'','+'''true''' 
				set @remaccset=1
				exec (@cmd2)  /* Configures target server for remote data access */
				drop table ##tempt2
			end
		
	end

/* Sets default mapping to created login */

set @cmd2='sp_addlinkedsrvlogin '''+@targetsrv+''',''false'',''sa'',''scratchlogin'',''xyz123'''
exec (@cmd2)

/* Determine version of target server */

create table ##tempt (tempt varchar(255))
set @cmd1='insert into ##tempt SELECT * FROM OPENQUERY('+@targetsrv+', ''select @@version'')'
exec (@cmd1)
if ((select tempt from ##tempt where tempt like '%6.5%') is not null) set @targetsqlver=65
drop table ##tempt
if @targetsqlver='65' goto get65remote else goto Get70or2kLocal

get65remote:

set @cmd1='select so.name as objname,sc.name,so.xtype,st.name as type, 
			Nullable=case 
				when (sc.status & 8)= 0 then (select ''0'') 
			  	when (sc.status & 8)= 8 then (select ''1'') 
			  	else (select ''n/a'') 
		     end 
			into ##srcdata 
			from sysobjects so,syscolumns sc,systypes st 
			where so.id=sc.id and so.xtype not in (''S'',''V'',''D'') and st.usertype=sc.usertype'
set @cmd2='select so.name as objname,sc.name,so.type as xtype,st.name as type,
			Nullable=case 
				when (sc.status & 8)= 0 then (select ''0'') 
			  	when (sc.status & 8)= 8 then (select ''1'') 
			  	else (select ''n/a'') 
		     end  
			into ##tgtdata from '+@targetsrv+'.'+@targetdb+'.dbo.sysobjects so,'+@targetsrv+'.'+@targetdb+'.dbo.syscolumns sc,'+@targetsrv+'.'+@targetdb+'.dbo.systypes st 
			where so.id=sc.id and so.type not in (''S'',''V'',''D'') and st.usertype=sc.usertype'
exec (@cmd1)
exec (@cmd2)
goto selection

Get70or2kRemote:
/* Get object data SQL 7.0 or 2000 */

set @cmd1='select so.name as objname,sc.name,so.xtype,st.name as type,sc.isnullable as nullable 
			into ##srcdata from sysobjects so,syscolumns sc,systypes st 
			where so.id=sc.id and so.xtype not in (''S'',''V'',''D'') and st.usertype=sc.usertype'

set @cmd2='select so.name as objname,sc.name,so.xtype,st.name as type,sc.isnullable as nullable 
			into ##tgtdata from '+@targetsrv+'.'+@targetdb+'..sysobjects so,'+@targetsrv+'.'+@targetdb+'..syscolumns sc,'+@targetsrv+'.'+@targetdb+'..systypes st 
			where so.id=sc.id and so.xtype not in (''S'',''V'',''D'') and st.usertype=sc.usertype'

exec (@cmd1)
exec (@cmd2)
goto selection

/* Get object data, both dbs on same 7.0 or 2000 server */

Get70or2kLocal:

set @cmd1='select so.name as objname,sc.name,so.type as xtype,st.name as type, sc.isnullable as nullable into ##srcdata from sysobjects so,syscolumns sc,systypes st where so.id=sc.id and so.type not in (''S'',''V'',''D'') and st.usertype=sc.usertype'
set @cmd2='select so.name as objname,sc.name,so.type as xtype,st.name as type,sc.isnullable as nullable into ##tgtdata from '+@targetdb+'..sysobjects so,'+@targetdb+'..syscolumns sc,'+@targetdb+'..systypes st where so.id=sc.id and so.type not in (''S'',''V'',''D'') and st.usertype=sc.usertype'
exec (@cmd1)
exec (@cmd2)
goto selection

/* Get object data, both dbs on same 6.5 server */

Get65Local:

set @cmd1='select so.name as objname,sc.name,so.type as xtype,st.name as type, 
			Nullable=case 
				when (sc.status & 8)= 0 then (select ''0'') 
			  	when (sc.status & 8)= 8 then (select ''1'') 
			  	else (select ''n/a'') 
		     end 
			into ##srcdata 
			from sysobjects so,syscolumns sc,systypes st 
			where so.id=sc.id and so.type not in (''S'',''V'',''D'') and st.usertype=sc.usertype'

set @cmd2='select so.name as objname,sc.name,so.type as xtype,st.name as type,
			Nullable=case 
				when (sc.status & 8)= 0 then (select ''0'') 
			  	when (sc.status & 8)= 8 then (select ''1'') 
			  	else (select ''n/a'') 
		     end  
			into ##tgtdata from '+@targetsrv+'.'+@targetdb+'.dbo.sysobjects so,'+@targetsrv+'.'+@targetdb+'.dbo.syscolumns sc,'+@targetsrv+'.'+@targetdb+'.dbo.systypes st 
			where so.id=sc.id and so.type not in (''S'',''V'',''D'') and st.usertype=sc.usertype'

exec (@cmd1)
exec (@cmd2)

Selection:

select sd.* into ##insource from ##srcdata sd left outer join ##tgtdata td 
	on (sd.objname=td.objname and sd.name=td.name) where td.objname is null
select td.* into ##intarget from ##tgtdata td left outer join ##srcdata sd 
	on (td.objname=sd.objname and td.name=sd.name) where sd.objname is null
select td.* into ##diff from ##tgtdata td left outer join ##srcdata sd 
	on (td.objname=sd.objname and td.name=sd.name and td.type=sd.type and td.nullable=sd.nullable) where (sd.nullable is null)

select 'The following objects are in '+@srcsrv+'..'+@srcdb+' but not in '+@targetsrv+'..'+@targetdb
select convert(varchar(35),objname)as Objname,convert(varchar(35),name)as name,xtype,convert(varchar(20),type) as Type,nullable from ##insource where xtype='U' order by objname,name 
select 'The following objects are in '+@targetsrv+'..'+@targetdb+' but not in '+@srcsrv+'..'+@srcdb
select * from ##intarget where xtype='U' order by objname,name 
select 'The following objects exist in both databases but have different nullability or data types'
select dt.objname,dt.name from ##diff dt left outer join ##srcdata sd on (dt.objname=sd.objname and dt.name=sd.name) where (sd.name is not null) and dt.xtype='U'

/* Cleanup */

if @remaccset=1 exec ('sp_serveroption '''+@targetsrv+''',''data access'','+'''false''')
if @skipregister=0 exec ('sp_dropserver '''+@targetsrv+''',droplogins')
set @cmd1=@targetconn+'"sp_droplogin ''''scratchlogin''''"'''
set @cmd2=@targetconn+'"sp_dropalias ''''scratchlogin''''"'''
exec ('master..xp_cmdshell '+@cmd2+',no_output')
exec ('master..xp_cmdshell '+@cmd1+',no_output')
drop table ##tgtdata
drop table ##srcdata
drop table ##insource
drop table ##diff
drop table ##intarget
veryend:
/* the end */
