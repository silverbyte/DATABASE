
--------------------- FINDING THE Min -----------------------------
-- This create sql string that gets the SECOND smallest employeeid 
-- example employeeid = 1,2,3,4,5,6,7,8,9,10
-- result = 2
declare @column 	varchar(50)
declare @tableName	varchar(50)
declare @n		int
declare @sqlStatment 	varchar(200) 

set @tableName = 'employees'
set @column = 'employeeid'
set @n = 2
set @sqlStatment = 'select a.' + @column + ' from ' + @tableName + ' as a ' + 
                   'where ' + convert (varchar(10),@n) + 
                   '=(select count(distinct ' + @column + ')' + 
                   ' from ' + @tableName + ' as b ' + 
                   ' where ' + 'a.'+ @column + ' >= ' + 'b.' + @column + ')' 

exec (@sqlStatment)

--------------------- FINDING THE MAX ------------------------------
-- This create sql string that gets the FORTH smallest employeeid 
-- example employeeid = 1,2,3,4,5,6,7,8,9,10
-- result = 6
declare @column 	varchar(50)
declare @tableName	varchar(50)
declare @n		int
declare @sqlStatment 	varchar(200) 

set @tableName = 'employees'
set @column = 'employeeid'
set @n = 4
set @sqlStatment = 'select a.' + @column + ' from ' + @tableName + ' as a ' + 
                   'where ' + convert (varchar(10),@n) + 
                   '=(select count(distinct ' + @column + ')' + 
                   ' from ' + @tableName + ' as b ' + 
                   ' where ' + 'a.'+ @column + ' <= ' + 'b.' + @column + ')' 

exec (@sqlStatment)

