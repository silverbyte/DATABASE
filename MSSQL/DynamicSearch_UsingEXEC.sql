/*
=======================================================
Example: sp00_QueryColumn 'jump the gator','GatorColumn','GatorTable'

would search the column 'GatorColumn' in the 'GatorTable' and
return the following records :

=======================
the jumping gator
Jump the magic alligator
the humping jumping gator
the crazy alligator jump
Them dummy alligator jumpers
.....

====
*/

/* example: sp00_QueryColumn 'World wide Pants','ColumnName','TableName'
This will bring all records with the words world wide pants in the column 'ColumnName'
want some VB and SQL snips? visit www.brainclone.com */


Create Proc sp00_QueryColumn

	@query varchar(255),
	@column varchar(255),
	@Table	varchar(255)
as

declare 
	@wordspace 	int,
	@Word		varchar(50),
	@SQLWhere	varchar(255)

/*set @query = 'world wide'
set @column = 'CustomerName'
set @table = 'Major' */
set @SQLWhere = ''

WHILE (SELECT CHARINDEX ( ' ' , @query )) > 0
BEGIN
   set @wordspace = CHARINDEX ( ' ' , @query )
   set @word = char(39) + '%' + rtrim(ltrim(substring(@query,1,@wordspace-1))) + '%' + char(39)

	set @SQLWhere = @SQLWhere + ' and '+ @column +' like '+ @word 

   SET @query = substring(@query,@wordspace+1,len(@query))

   IF (SELECT CHARINDEX ( ' ' , @query )) = 0
      	BREAK
   ELSE
      CONTINUE
END
	set @wordspace = len(@query)
   	set @word = char(39) + '%' + rtrim(ltrim(substring(@query,1,@wordspace)))+ '%'+ char(39)
	set @SQLWhere = @column +' like '+ @word + @SQLWhere

exec('Select '+ @column + ' from ' + @table +' where '+ @SQLWhere )




