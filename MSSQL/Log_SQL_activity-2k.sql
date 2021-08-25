use master
GO
if exists (select * from sysobjects where id = object_id('dbo.sp_activity') and sysstat & 0xf = 4)
drop procedure dbo.sp_activity
GO

CREATE PROCEDURE sp_activity AS

/* SP_ACTIVITY 				*/
/* Author: Mitch van Huuksloot		*/
/* Date: April 30, 2001			*/

set nocount on

select 'Activity on' = convert(char(19), getdate(), 20), Server = @@SERVERNAME

/* temp tables to hold more-or-less consistent sysprocesses/syslockinfo snapshots */

create table #info
(
	spid smallint,
	cmd char(16),
	status char(10),
	blocked smallint,
	waittype binary(2),
	waittime int,
	lastwaittype char(20),
	waitresource char(25),
	dbname char(30),
	loginname char(25),
	hostname char(15),
	cpu int,
	physical_io int,
	[memusage] int,
	login_time char(19),
	last_batch char(19),
	open_tran smallint,
	net_address char(12),
	net_library char(12),	
)

create table #locks
(
	spid int,
	resource char(32),
	dbname char(30),
	indid smallint,
	indname char(30),
	objid integer,
	objectname char(30),
	typeid tinyint,
	type char(3),
	mode char(12),
	status char(10),
	refcnt smallint,
	ownertype char(12),
	transid bigint
)

/* capture sysprocesses */
insert into #info
	select	p.spid,
		convert(char(16), p.cmd), 
		convert(char(10), p.status),
		p.blocked,
		p.waittype,
		p.waittime,
		convert(char(20), p.lastwaittype),
		convert(char(25), p.waitresource),
		convert(char(30), d.name), 
		convert(char(25), p.loginame), 
		convert(char(15), p.hostname), 
		p.cpu,
		p.physical_io,
		p.memusage, 
		convert(char(19), p.login_time, 20),
		convert(char(19), p.last_batch, 20),
		p.open_tran,
		convert(char(12), p.net_address),
		convert(char(12), p.net_library)
	from  master.dbo.sysprocesses p (nolock), master.dbo.sysdatabases d (nolock)
	where p.dbid = d.dbid

/* capture syslockinfo */
insert into #locks
	select
		L.req_spid,
		convert(char(32), L.rsc_text),
		convert(char(30), d.name),
		L.rsc_indid,
		SPACE(30),
		L.rsc_objid,
		SPACE(30),
		L.rsc_type,
		convert(char(3), v.name),
		convert(char(12), v2.name),
		convert(CHAR(10), v3.name),
		L.req_refcnt smallint,
		case L.req_ownertype when 1 then 'Transaction' when 2 then 'Cursor' when 3 then 'Session' when 4 then 'ExSession' else cast(L.req_ownertype as char(12)) end,
		req_transactionID 
	from master..syslockinfo L (nolock), master..sysdatabases d (nolock), 
	     master..spt_values v (nolock),  master..spt_values v2 (nolock), master..spt_values v3 (nolock)
	where 	L.rsc_dbid = d.dbid and 
		l.rsc_type=v.number and v.type='LR' and 
		(l.req_mode+1)=v2.number and v2.type='L' and
		l.req_status=v3.number and v3.type='LS'

/* Show active processes from sysprocesses capture */

print ''
print 'Active SQL Server Processes'
print ''
select * from #info order by spid

/* Dump out block chain, if there is one */

declare @blkd int
select @blkd=count(spid) from #info where blocked = 0 and spid in (select distinct blocked from #info where blocked != 0)
if @blkd > 0
  begin
	print ''
	select 'SPIDs at the head of blocking chains'=spid from #info where blocked = 0 and spid in (select distinct blocked from #info where blocked != 0)
	print ''
  end

/* Dump inputbuffers for each blocking process */

declare @spid smallint, @spidch char(5), @msg varchar(100)

declare c1 cursor for select distinct blocked from #info where blocked > 0 FOR READ ONLY
open c1
fetch c1 into  @spid
while @@fetch_status >= 0
   begin
	select @spidch = convert(char(5), @spid)
	print ''
	select @msg = 'Blocking SPID ' + @spidch + ' input buffer capture'
	print ''
	print @msg
	select @msg = 'dbcc inputbuffer(' + @spidch + ')'
	execute(@msg)
	fetch c1 into  @spid
   end
deallocate c1

/* Dump inputbuffers for each blocked process */

declare c1 cursor for select spid from #info where blocked > 0 FOR READ ONLY
open c1
fetch c1 into  @spid
while @@fetch_status >= 0
   begin
	select @spidch = convert(char(5), @spid)
	print ''
	select @msg = 'Blocked SPID ' + @spidch + ' input buffer capture'
	print ''
	print @msg
	select @msg = 'dbcc inputbuffer(' + @spidch + ')'
	execute(@msg)
	fetch c1 into  @spid
   end
deallocate c1

drop table #info	-- we are finished with the sysprocesses capture

/* Update locks table with tablename, objectname, indexname from the appropriate database */

declare @dbname varchar(30),
	@objid int,
	@indid int,
	@idch varchar(20),
	@indch varchar(20),
	@objname varchar(30),
	@indexname varchar(30),
	@stmt varchar(500)

declare c2 cursor for select distinct dbname, objid, indid from #locks where typeid between 4 and 9 for read only
open c2
fetch c2 into  @dbname, @objid, @indid
while @@fetch_status >= 0
   begin
	select @idch=cast(@objid as varchar(20))
	select @indch=cast(@indid as varchar(20))
	if @indid <> 0
		select @stmt = 'update #locks set objectname = cast(o.name as char(30)), indname=cast(i.name as char(30)) from #locks l, ' +
       			@dbname + '..sysobjects o (nolock), ' + @dbname + '..sysindexes i (nolock) where l.dbname = ' + '''' + @dbname + '''' + 
			' and l.objid = ' + @idch + ' and l.indid = ' + @indch + ' and o.id = ' + @idch + ' and i.id = ' + @idch + ' and i.indid = ' + @indch
	else
		select @stmt = 'update #locks set objectname = cast(o.name as char(30)) from #locks l, ' +
       			@dbname + '..sysobjects o (nolock) where l.dbname = ' + '''' + @dbname + '''' + 
			' and l.objid = ' + @idch + ' and l.indid = ' + @indch + ' and o.id = ' + @idch
	execute(@stmt)
	fetch c2 into  @dbname, @objid, @indid
   end
deallocate c2

/* Show lock information from syslocks capture */

print ''
print 'Locks'
print ''

select spid, type, mode, status, [database]=dbname, [index]=indname, [object]=objectname, resource, ownertype, "trans #"=transid, refcnt
from #locks order by spid, dbname, object, indname, resource, type, mode, status

drop table #locks	-- drop syslockinfo capture
GO

exec sp_activity