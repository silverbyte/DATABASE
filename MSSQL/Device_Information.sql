/* Purpose	: The following script display detail SQLServer device information */

DECLARE @dbname varchar(50)
DECLARE @command varchar(255)
DECLARE dbname_cursor CURSOR FOR SELECT name from master..sysdatabases 
	where name not in ('northwind', 'pubs')
OPEN dbname_cursor
FETCH next FROM dbname_cursor into @dbname
WHILE @@fetch_status = 0
BEGIN
SELECT @command = 'USE ' + @dbname + ' select ' + 
    'convert(varchar(25),f.name) ''Device Name'','+ 
    'convert(varchar(10),size/128) + '' MB'' ''Device Size'','+ 
    'convert(varchar(100),f.filename) Path,'+ 
    'convert(varchar(15),filegroup_name(groupid)) Filegroup from sysfiles f' 
EXEC (@command)
FETCH NEXT FROM dbname_cursor INTO @dbname
END
CLOSE dbname_cursor
DEALLOCATE dbname_cursor
GO
