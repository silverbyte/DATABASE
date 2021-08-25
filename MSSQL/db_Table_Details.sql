------- Database Table Details -------------------------

-- example 1
declare @tablename varchar(50)
set @tablename = 'mvt'

select * from dbo.sysobjects 
where id = object_id(N'[dbo].['+@tableName+']') 
and OBJECTPROPERTY(id, N'IsUserTable') =1

select left(a.name,30) Name,left(b.name,15) 
Type,a.length,a.prec,a.scale,allownulls,* from syscolumns a join systypes b on 
a.xusertype=b.xusertype where id=object_id(@tableName) order by name

-- example 2 --------------
declare @tblName varchar(50)
set @tblName = 'call_center'

select * from Information_Schema.CONSTRAINT_COLUMN_USAGE 
where table_name = @tblName

SELECT  so.name AS TableName, sc.name AS ColumnName, st.name AS DataType, sc.length, sc.isnullable
FROM         dbo.sysobjects so INNER JOIN
                      dbo.syscolumns sc ON so.id = sc.id INNER JOIN
                      dbo.systypes st ON sc.xtype = st.xtype
WHERE     (so.type = 'u')
and 	so.name =@tblName
ORDER BY so.name,sc.colid

-- example 3 ---------------
declare @tblName varchar(50)
set @tblName = 'mvt'

-- select * from Information_Schema.columns 
-- where table_name = @tblName
-- ORDER BY table_name,ordinal_position

select Table_name,ordinal_position,Column_name,data_type,character_maximum_length,character_octet_length,numeric_precision,is_nullable,Column_default from Information_Schema.columns 
where table_name = @tblName
ORDER BY table_name,ordinal_position






