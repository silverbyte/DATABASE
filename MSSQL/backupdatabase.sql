declare @dbname as varchar(40)
declare @msgdb as varchar(40)
declare @dbbkpname as varchar(40)
declare rs_cursor CURSOR for select name from master.dbo.sysdatabases
open rs_cursor 
Fetch next from rs_cursor into @dbname
IF @@FETCH_STATUS <> 0 
  PRINT "         <<db>>"     
WHILE @@FETCH_STATUS = 0
BEGIN
  select @msgdb= "database backup on progress: " + @dbname
  PRINT @msgdb
  select @dbbkpname='d:\backup testing\' + @dbname + '.dat'
  backup database @dbname to disk=@dbbkpname
  FETCH NEXT FROM rs_cursor INTO @dbname
END
CLOSE rs_cursor
deallocate rs_cursor







