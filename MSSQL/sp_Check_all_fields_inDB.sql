-- --example :
-- sp_check_fields_all_db '4010-S01-62-0101','varchar'
-- check entire database for columnNameField '4010-S01-62-0101', or type 'VarChar'

-----------------------------------------------------
-- uncomment this section to create procedure
--CREATE PROCEDURE [sp_check_fields_all_db] 
--@value varchar(50),@columndatatype varchar(50)
--AS

--comment next 4 line to create procedure
declare @value varchar(50)
declare @columndatatype varchar(50)
set @value = 'lot_number'
set @columndatatype = 'varchar'
------------------------------------------------------

declare @tablename varchar(50)
declare @columnname varchar(50)
declare @columntype varchar(50)
declare @columnvalue varchar(50)
declare @sql varchar(1000)
declare @i int



create table #tt(TableName varchar(50),ColumnName varchar(50),Active int)

set nocount on
DECLARE Validate_Cursor CURSOR FOR


SELECT o.name, c.name,t.name

from sysobjects o inner join  syscolumns c on o.id=c.id
inner join systypes t on t.xtype=c.xtype
--and o.name='t_authorization'
 where o.type='U'
 and t.name=@columndatatype
order by o.name desc
OPEN Validate_Cursor

FETCH NEXT FROM Validate_Cursor into @tablename,@columnname,@columntype




WHILE @@FETCH_STATUS = 0

BEGIN
	---------------------------------------------




set nocount on
set @sql= N'insert #tt select '+ ''' + @tablename + ''' +N' as TableName,'+ 
''' + @columnname+ ''' +N' as ColumnName, count([' + @columnname + N']) as Active from ' + quotename(@tablename) +
N' where [' + @columnname + N'] =' + '''+ @value + ''' +N' GROUP BY [' +@columnname + ']'
--select @sql

exec (@sql)

if @@error<>0
begin
print @sql
end

FETCH NEXT FROM Validate_Cursor into @tablename,@columnname,@columntype


	--------------------------------------------
END

CLOSE Validate_Cursor

DEALLOCATE Validate_Cursor
print('========================================================================================================')
select * from #tt

drop table #tt

