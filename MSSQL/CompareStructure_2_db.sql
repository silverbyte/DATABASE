Use Master
IF EXISTS(SELECT * FROM SYSOBJECTS WHERE NAME = 'sp_Compare2DB' and ObjectProperty(ID, 'ISPROCEDURE')=1)
	DROP PROCEDURE sp_Compare2DB
GO

-- sp_Compare2DB  
--
-- Compares the structure of 2 databases of SQL Server
-- parameters to be passed   
-- @DB1  Database 1 (SysName)  
-- @DB2  Databse 2 (SysName)  
-- @ShowDifferentOnly see later (Bit)  
--      
-- Parameters 1, 2 may include server name as  well. 
-- But the server should be either local or linked server.
-- This Procedure is devided into 2 parts  
-- Part I Checks the tables and Views (Column Definition, size, default) etc.  
-- Part II Checks the Code of Views, Stored Procedures and Triggers  
-- If @ShowDifferentOnly is set to 1 it will show only the lines that are different  
-- Otherwise all lines of both objects are shown.  
-- Default for @ShowDifferentOnly is 1  
--
-- Tested in SQLServer 2000 Service Pack 1.  
--
-- Known Issues:
-- 1.	If Server name or the database name is with space, 
-- 		it should be included with single Quote and not with braces.
-- 		This procedure is not checking for the braces in the name.
-- 2.	This procedure is not checking the following:
--		Indexes 
-- 		Primary Keys 
--		Foreign Keys 
--		Contraints
-- 		rules 
--		user deined data types 
--		Formula differents for computed columns
--
-- Note:
-- 		The purpose of this procedure is not to check the data. Only the structure is checked. 
--
--
--------------------------------------------------------------------------------------------
-- 					Written By G.R. Preethiviraj Kulasingham
-- 						Last Modified on 26th March 2002.
--------------------------------------------------------------------------------------------


CREATE  Procedure sp_Compare2DB     
	@DB1 sysname, @DB2 sysname, @ShowDifferentOnly bit =1
AS      

Declare @SQL varchar(8000),       
	 @Text nvarchar(4000),      
	 @BlankSpaceAdded   int,       
	 @BasePos       int,      
	 @CurrentPos    int,      
	 @TextLength    int,      
	 @LineId        int,      
	 @AddOnLen      int,      
	 @LFCR          int, 
	 @DefinedLength int,      
	 @SyscomText nvarchar(4000),      
	 @Line nvarchar(1000),    
	 @ProcID int,      
	 @ObjID int,      
	 @ObjID2 int,      
	 @OldProcID int,        
	 @DBName1 SysName,
	 @SvrName1 SysName,
	 @DBName2 SysName,
	 @SvrName2 SysName
    
Set NoCount on      
      
SET @DefinedLength = 1000
SET @BlankSpaceAdded = 0       
-- This Part Validated the Input parameters
set @DB1 = RTRIM(LTRIM(@DB1))
set @DB2 = RTRIM(LTRIM(@DB2))
set @SvrName1 = @@SERVERNAME
IF CHARINDEX('.',@DB1) > 0
begin
	set @SvrName1 = LEFT(@DB1,CHARINDEX('.',@DB1)-1)
	if not exists (select * from master.dbo.sysservers where srvname = @SvrName1)
	begin
		print 'There is no linked server named '+@SvrName1+' Found. Precedure Terminates.'
		return 
	end
	set @DBName1 = RIGHT(@DB1,LEN(@DB1)-CHARINDEX('.',@DB1))
end
else
	set @DBName1 = @DB1
exec ('declare @Name sysname select @Name=name from ['+@SvrName1+'].master.dbo.sysdatabases where name = '''+@DBName1+'''')
if @@rowcount = 0
begin
	print 'There is no database named '+@DB1+' Found. Precedure Terminates.'
	return 
end
set @SvrName2 = @@SERVERNAME
if CHARINDEX('.',@DB2) > 0
begin
	set @SvrName2 = LEFT(@DB2,CHARINDEX('.',@DB2)-1)
	if not exists (select * from master.dbo.sysservers where srvname = @SvrName2)
	begin
		print 'There is no linked server named '+@SvrName2+' Found. Precedure Terminates.'
		return 
	end
	set @DBName2 = RIGHT(@DB2,LEN(@DB2)-CHARINDEX('.',@DB2))
end
else
	set @DBName2 = @DB2
exec ('declare @Name sysname select @Name=name from ['+@SvrName2+'].master.dbo.sysdatabases where name = '''+@DBName2+'''')
if @@rowcount = 0
begin
	print 'There is no database named '+@DB2+' Found. Precedure Terminates.'
	return 
end

IF @DB1=@DB2
BEGIN
	PRINT 'Both databases should be different. Precedure Terminates.'
   	RETURN
END  

--End of validation
  
create Table #Procedures 
(      
	 DBName sysname NOT NULL,       
	 UserName sysname not null,       
	 ProcName sysname NOT NULL,       
	 Type varchar(2) NOT NULL,
	 ObjID  int NOT NULL,   
	 ObjID2 int NULL,        
	 ProcID int Identity(1,1) NOT NULL      
)


Create Table  #ProcText 
(      
	 ProcID int NOT NULL,      
	 ColID int NOT NULL,      
	 PText nvarchar(4000) NULL      
)      
      
Create Table #ProcLineText 
(      
	 ProcID int NOT NULL,  
	 LineID int NOT NULL,       
	 LineText nvarchar(1000) NULL      
)      
    
Create Table #TableColumns 
(    
	TABLE_CATALOG sysname NOT NULL,    
	TABLE_SCHEMA sysname NOT NULL,    
	TABLE_NAME sysname NOT NULL,    
	COLUMN_NAME sysname NOT NULL,    
	ORDINAL_POSITION smallint NOT NULL,    
	COLUMN_DEFAULT nvarchar(2000) NULL,    
	IS_NULLABLE bit NOT NULL,    
	DATA_TYPE sysname NOT NULL,    
	CHARACTER_MAXIMUM_LENGTH int NULL,    
	CHARACTER_OCTET_LENGTH int NULL,    
	NUMERIC_PRECISION tinyint NULL,    
	NUMERIC_PRECISION_RADIX smallint NULL,    
	NUMERIC_SCALE int NULL,     
	DATETIME_PRECISION smallint NULL,
	IS_COMPUTED bit NOT NULL,
	IS_IDENTITY bit NOT NULL,
	IDENTITY_SEED int NULL,
	IDENTITY_INCR int NULL,
	IS_FORREPL bit NOT NULL,
	IS_ROWGUID bit NOT NULL, 
	IS_DEFAULT bit NOT NULL,
	IS_MAXIMUM bit NOT NULL,
	IS_OCTET bit NOT NULL,    
	IS_PRECISION bit NOT NULL,    
	IS_RADIX bit NOT NULL,    
	IS_SCALE bit NOT NULL,     
	IS_DATETIME bit NOT NULL
	
)    
    
----------------------------------------------------------------------------------------    
--      Part I    
----------------------------------------------------------------------------------------  

-- Get the tables with column data       
set @SQL = 'Insert into  #TableColumns 
SELECT '''+@DB1 +''',    
	usr.name, obj.name,    
	Col.name,    
	col.colid,    
	com.text,    
	col.isnullable,    
	spt_dtp.LOCAL_TYPE_NAME,    
	convert(int, OdbcPrec(col.xtype, col.length, col.xprec)  + spt_dtp.charbin),    
	convert(int, spt_dtp.charbin + 
		   case when spt_dtp.LOCAL_TYPE_NAME in (''nchar'', ''nvarchar'', ''ntext'')
			 then  2*OdbcPrec(col.xtype, col.length, col.xprec) 
			 else  OdbcPrec(col.xtype, col.length, col.xprec) 
		   end),    
	nullif(col.xprec, 0),    
	spt_dtp.RADIX,    
	col.scale,    
	spt_dtp.SQL_DATETIME_SUB,
	col.iscomputed,
	col.colstat,
	NULL,
	NULL,
	0, 
	0,
	0, 
	0,
	0, 
	0,
	0, 
	0,
	0
from ['+@SvrName1+'].['+@DBName1+'].dbo.sysobjects obj,
	['+@SvrName1+'].master.dbo.spt_datatype_info spt_dtp,
	['+@SvrName1+'].['+@DBName1 +'].dbo.systypes typ,
	['+@SvrName1+'].['+@DBName1 +'].dbo.sysusers usr,
	['+@SvrName1+'].['+@DBName1 +'].dbo.syscolumns col     
	LEFT OUTER JOIN 
     ['+@SvrName1+'].['+@DBName1 +'].dbo.syscomments com on col.cdefault = com.id
		AND com.colid = 1
WHERE
	obj.id = col.id
     AND obj.uid=usr.uid 
	AND typ.xtype = spt_dtp.ss_dtype
	AND (spt_dtp.ODBCVer is null or spt_dtp.ODBCVer = 2)
	AND obj.xtype in (''U'', ''V'')
	AND col.xusertype = typ.xusertype
	AND (spt_dtp.AUTO_INCREMENT is null or spt_dtp.AUTO_INCREMENT = 0)'
Execute (@SQL)    

set @SQL = 'Insert into  #TableColumns 
SELECT '''+@DB2 +''',    
	usr.name, obj.name,    
	Col.name,    
	col.colid,    
	com.text,    
	col.isnullable,    
	spt_dtp.LOCAL_TYPE_NAME,    
	convert(int, OdbcPrec(col.xtype, col.length, col.xprec)  + spt_dtp.charbin),    
	convert(int, spt_dtp.charbin + 
		   case when spt_dtp.LOCAL_TYPE_NAME in (''nchar'', ''nvarchar'', ''ntext'')
			 then  2*OdbcPrec(col.xtype, col.length, col.xprec) 
			 else  OdbcPrec(col.xtype, col.length, col.xprec) 
		   end),    
	nullif(col.xprec, 0),    
	spt_dtp.RADIX,    
	col.scale,    
	spt_dtp.SQL_DATETIME_SUB,
	col.iscomputed,
	col.colstat,
	NULL,
	NULL,
	0, 
	0,
	0, 
	0,
	0, 
	0,
	0, 
	0,
	0
from ['+@SvrName2+'].['+@DBName2 +'].dbo.sysobjects obj,
	['+@SvrName2+'].master.dbo.spt_datatype_info spt_dtp,
	['+@SvrName2+'].['+@DBName2 +'].dbo.systypes typ,
	['+@SvrName2+'].['+@DBName2 +'].dbo.sysusers usr,
	['+@SvrName2+'].['+@DBName2 +'].dbo.syscolumns col     
	LEFT OUTER JOIN 
     ['+@SvrName2+'].['+@DBName2 +'].dbo.syscomments com on col.cdefault = com.id
		AND com.colid = 1
WHERE
	obj.id = col.id
     AND obj.uid=usr.uid 
	AND typ.xtype = spt_dtp.ss_dtype
	AND (spt_dtp.ODBCVer is null or spt_dtp.ODBCVer = 2)
	AND obj.xtype in (''U'', ''V'')
	AND col.xusertype = typ.xusertype
	AND (spt_dtp.AUTO_INCREMENT is null or spt_dtp.AUTO_INCREMENT = 0)' 

Execute (@SQL)    
SET @sql ='UPDATE #TableColumns SET IDENTITY_SEED =A.seed, IDENTITY_INCR = Incr 
From
	(Select usr.name as table_Schema, obj.name as table_name, 
		Seed =ident_seed(''['+@DBName2+'].''+usr.Name+''.''+obj.name),
		Incr =ident_incr(''['+@DBName2+'].''+usr.name+''.''+obj.name) 
	From [' + @SvrName2 + '].['+@DBName2+'].dbo.sysobjects obj,
		[' + @SvrName2 + '].['+@DBName2+'].dbo.sysusers usr
	WHERE obj.uid = usr.uid and 
		ident_seed(''['+@DBName2+'].''+usr.Name+''.''+obj.name) is not NULL) A 
WHERE A.table_Schema=#TableColumns.Table_Schema and 
	A.table_name = #TableColumns.Table_Name and 
	#TableColumns.IS_IDENTITY & 1 = 1 and
	#TableColumns.Table_catalog ='''+@DB2+''''  

Execute (@SQL)

SET @sql ='UPDATE #TableColumns SET IDENTITY_SEED =A.seed, IDENTITY_INCR = A.Incr 
From
	(Select table_Schema=usr.name, table_name=obj.name, 
		Seed =ident_seed(''['+@DBName1+'].''+usr.Name+''.''+obj.name),
		Incr =ident_incr(''['+@DBName1+'].''+usr.name+''.''+obj.name) 
	From [' + @SvrName1 + '].['+@DBName1+'].dbo.sysobjects obj,
		[' + @SvrName1 + '].['+@DBName1+'].dbo.sysusers usr
	WHERE obj.uid = usr.uid and 
		ident_seed(''['+@DBName1+'].''+usr.Name+''.''+obj.name) is NOT NULL) A 
WHERE A.table_Schema= #TableColumns.Table_Schema and 
	 A.table_name  = #TableColumns.Table_Name and 
	 #TableColumns.IS_IDENTITY & 1 = 1 and
	 #TableColumns.Table_Catalog ='''+@DB1+''''  
Execute (@SQL)

Update #TableColumns SET IS_DEFAULT =1 Where COLUMN_DEFAULT IS NOT NULL
Update #TableColumns SET IS_OCTET = 1 Where CHARACTER_OCTET_LENGTH IS NOT NULL
Update #TableColumns SET IS_RADIX = 1 Where NUMERIC_PRECISION_RADIX IS NOT NULL
Update #TableColumns SET IS_MAXIMUM = 1 Where CHARACTER_MAXIMUM_LENGTH IS NOT NULL
Update #TableColumns SET IS_PRECISION = 1 Where NUMERIC_PRECISION IS NOT NULL
Update #TableColumns SET IS_SCALE = 1 Where NUMERIC_SCALE IS NOT NULL
Update #TableColumns SET IS_DATETIME = 1 Where DATETIME_PRECISION IS NOT NULL

Update #TableColumns SET COLUMN_DEFAULT ='' WHERE COLUMN_DEFAULT IS NULL
Update #TableColumns SET CHARACTER_MAXIMUM_LENGTH=0 WHERE CHARACTER_MAXIMUM_LENGTH is NULL
Update #TableColumns SET CHARACTER_OCTET_LENGTH=0 WHERE CHARACTER_OCTET_LENGTH IS NULL    
Update #TableColumns SET NUMERIC_PRECISION =0 WHERE NUMERIC_PRECISION IS NULL    
Update #TableColumns SET NUMERIC_PRECISION_RADIX = 0 WHERE NUMERIC_PRECISION_RADIX IS NULL
Update #TableColumns SET NUMERIC_SCALE = 0 WHERE NUMERIC_SCALE is NULL     
Update #TableColumns SET DATETIME_PRECISION=0 WHERE DATETIME_PRECISION is NULL


    
PRINT 'Tables & Views that exists only in '+@DB1    
print '-----------------------------------'+Replicate('-', len(@DB1))    
Select Distinct Table_Schema +'.'+Table_Name
From #TableColumns 
Where Table_Catalog=@DB1 and Table_Schema+Table_Name not in (    
    Select Table_Schema+Table_Name from #TableColumns
    Where Table_Catalog =@DB2)    
if @@RowCount =0    
    Print '(none)'    
    
Print ''    
    
Print 'Tables & Views that exists only in '+@DB2    
print '-----------------------------------'+replicate('-', len(@DB2))    
Select Distinct Table_Schema+'.'+Table_Name
From #TableColumns 
Where Table_Catalog=@DB2 and Table_Schema+Table_Name not in (    
    	Select Table_Schema+Table_Name from #TableColumns
    	Where Table_Catalog =@DB1)    
if @@RowCount =0    
	Print '(none)'    
    
Print ''    
    
  
--Now check for additional Columns    
Print 'Columns that are missing on the table/View'    
Print '------------------------------------------'    
     
Select Distinct [Missing in Database] =    
Case A.Table_Catalog    
    	WHEN @DB1 THEN @DB2    
    	ELSE @DB1    
    	END, 
	[Missing Column]=A.Table_Catalog+'.'+     
    	A.Table_Schema+'.'+A.Table_Name+'  -  '+ A.Column_Name,    
 	'Default'= 
	CASE A.IS_DEFAULT
	WHEN 1 THEN A.Column_Default 
	ELSE NULL
	END,    
 	'Allow Null' =
	CASE A.Is_Nullable 
	WHEN 1 THEN 'Yes'
	ELSE 'NO'
	END,    
 	A.Data_Type [Data type],    
	'Maximum Length'=
	CASE A.IS_MAXIMUM
	WHEN 1 THEN A.Character_Maximum_Length    
	ELSE NULL
	END,
 	'Numeric Precision'=
	CASE A.IS_PRECISION
	WHEN 1 THEN A.Numeric_Precision
	ELSE NULL
	END,
 	'Numeric Precision Radix'=
	CASE A.IS_RADIX
	WHEN 1 THEN A.Numeric_Precision_Radix
	ELSE NULL
	END,
	'Numeric Scale'=
	CASE A.IS_SCALE
	WHEN 1 THEN A.Numeric_Scale
	ELSE NULL
	END,
 	'Date Time Precision'=
	case A.IS_DateTime
	WHEN 1 THEN A.Datetime_Precision     
	ELSE NULL
	END,
	'Identity ?'=
	CASE A.IS_IDENTITY
	WHEN 1 THEN 'Yes'
	ELSE 'No'
	END ,
	Seed = 
	Case A.IS_IDENTITY 
	WHEN 1 THEN A.IDENTITY_SEED
	ELSE NULL
	END,
	Increment =
	Case A.IS_IDENTITY 
	WHEN 1 THEN A.IDENTITY_INCR
	ELSE NULL
	END
From (#TableColumns  A     
LEFT OUTER JOIN #TableColumns B On    
	A.Table_Schema= B.Table_Schema and     
	A.Column_Name = B.Column_Name  and     
	A.Table_Name = B.Table_Name and A.Table_Catalog<>B.Table_Catalog)    
	INNER JOIN #TableColumns C On A.Table_Schema= C.Table_Schema and    
 	A.Table_Name = C.Table_Name and    
 	A.Table_Catalog<>C.Table_Catalog    
Where B.Table_Name is NULL      
Order By A.Table_Catalog+'.'+A.Table_Schema+'.'+ A.Table_Name+'  -  '+ A.Column_Name    
IF @@ROWCOUNT =0     
   	Print '(none)'    
--Column is there but length / precision is different    
Print 'Different Columns Definitions'    
Print '-----------------------------'    
    
Select A.Table_Name, A.Column_Name,     
	A.Table_Catalog+'.'+ A.Table_Schema as [Data Base],
	'Default'=
	CASE A.IS_DEFAULT
	WHEN 1 THEN A.Column_Default
	ELSE NULL
	END,
 	'Allow Null' =
	CASE A.Is_Nullable 
	WHEN 1 THEN 'Yes'
	ELSE 'NO'
	END,    
 	A.Data_Type [Data type],  
	'Maximum Length'=
	CASE A.IS_MAXIMUM
	WHEN 1 THEN A.Character_Maximum_Length    
	ELSE NULL
	END,
 	'Numeric Precision'=
	CASE A.IS_PRECISION
	WHEN 1 THEN A.Numeric_Precision
	ELSE NULL
	END,
 	'Numeric Precision Radix'=
	CASE A.IS_RADIX
	WHEN 1 THEN A.Numeric_Precision_Radix
	ELSE NULL
	END,
	'Numeric Scale'=
	CASE A.IS_SCALE
	WHEN 1 THEN A.Numeric_Scale
	ELSE NULL
	END,
 	'Date Time Precision'=
	case A.IS_DateTime
	WHEN 1 THEN A.Datetime_Precision     
	ELSE NULL
	END,
	'Identity ?'=
	CASE A.IS_IDENTITY
	WHEN 1 THEN 'Yes'
	ELSE 'No'
	END ,
	Seed =
	Case A.IS_IDENTITY 
	WHEN 1 THEN A.IDENTITY_SEED
	ELSE NULL
	END,
	increment =
	Case A.IS_IDENTITY 
	WHEN 1 THEN A.IDENTITY_INCR
	ELSE NULL
	END
From #TableColumns A     
INNER JOIN #TableColumns B On    
 	A.Table_Catalog<>B.Table_Catalog and    
 	A.Table_Schema= B.Table_Schema and     
 	A.Table_Name = B.Table_Name and     
 	A.Column_Name = B.Column_Name and    
 	(A.Column_Default<>B.Column_Default or    
  	A.Is_Nullable<>B.Is_Nullable or    
  	A.Data_Type<>B.Data_Type or    
  	A.Character_Maximum_Length<>B.Character_Maximum_Length or    
  	A.Numeric_Precision<>B.Numeric_Precision or    
  	A.Numeric_Scale<>B.Numeric_Scale or    
  	A.Datetime_Precision<>B.Datetime_Precision or
	A.IS_IDENTITY<>B.IS_IDENTITY or
	A.IDENTITY_SEED<>B.IDENTITY_SEED or
	A.IDENTITY_INCR<>B.IDENTITY_INCR or
	A.IS_DEFAULT <>B.IS_DEFAULT  or
	A.IS_MAXIMUM <>B.IS_MAXIMUM or
	A.IS_OCTET <>B.IS_OCTET or
	A.IS_PRECISION <>B.IS_PRECISION or
	A.IS_RADIX <>B.IS_RADIX or
	A.IS_SCALE <>B.IS_SCALE or
	A.IS_DATETIME<>B.IS_DATETIME)    
Order By A.Table_Name, A.Column_Name,     
 	A.Table_Catalog+'.'+A.Table_Schema    
IF @@ROWCOUNT =0     
   	Print '(none)'    
  
Print ''
Print ''
  
----------------------------------------------------------------------------------------    
--      Part II:     
----------------------------------------------------------------------------------------  
-- Get the other objects found only in @DB1    
Set @SQL = 'Insert into #Procedures (DBName, UserName, ProcName, Type, ObjID)  
Select ''' + @DB1 +''', A.Name,  B.Name, B.Type, B.ID 
from ['+@SvrName1+'].['+@DBName1+'].dbo.Sysusers A, 
	['+@SvrName1+'].['+@DBName1+'].dbo.SysObjects B 
Where A.uid = B.uid and 
		B.Category = 0 and B.Type in (''P'', ''V'', ''Tr'', ''FN'')      
	and A.Name+B.Name NOT IN (Select A.Name+B.Name 
	From ['+@SvrName2+'].['+@DBName2+'].dbo.Sysusers A, 
		['++@SvrName2+'].['+@DBName2+'].dbo.SysObjects B Where A.uid = B.uid)'      
      
Execute(@SQL)      
     
-- Get the objects found only in @DB1    
Set @SQL = 'Insert into #Procedures (DBName, UserName, ProcName, Type, ObjID)  
Select ''' + @DB2 +''', A.Name,  B.Name, B.Type, B.ID 
from ['+@SvrName2+'].['+@DBName2+'].dbo.Sysusers A, 
	['+@SvrName2+'].['+@DBName2+'].dbo.SysObjects B 
Where A.uid = B.uid and 
	B.Category = 0 and B.Type in (''P'', ''V'', ''Tr'', ''FN'')      
	and A.Name+B.Name NOT IN (Select A.Name+B.Name 
	From ['+@SvrName1+'].['+@DBName1+'].dbo.Sysusers A, 
		['+@SvrName1+'].['+@DBName1+'].dbo.SysObjects B 
	Where A.uid = B.uid)'      
Execute(@SQL)      
   
-- Get the existing Objects  
Set @SQL = 'Insert into #Procedures (DBName, UserName, ProcName, Type, ObjID, ObjID2)  
Select ''' + @DB1 +''', A.Name,  B.Name, B.type, B.ID, D.ID 
from ['+@SvrName1+'].['+@DBName1 +'].dbo.Sysusers A,
     ['+@SvrName1+'].['+@DBName1 +'].dbo.SysObjects B, 
     ['+@SvrName2+'].['+@DBName2 +'].dbo.SysUsers C, 
     ['+@SvrName2+'].['+@DBName2+'].dbo.SysObjects D   
Where A.uid = B.uid and B.Category = 0 and B.Type in (''P'', ''V'', ''Tr'', ''FN'')  
      and A.Name = C.Name and B.Name=D.Name and C.uid = D.uid'      
Execute(@SQL)      
  
Set @SQL = 'Insert into #Procedures (DBName, UserName, ProcName, Type, ObjID, ObjID2)  
Select ''' + @DB2 +''', A.Name,  B.Name, B.type, B.ID, D.ID 
from ['+@SvrName2+'].['+@DBName2 +'].dbo.Sysusers A, 
     ['+@SvrName2+'].['+@DBName2 +'].dbo.SysObjects B, 
     ['+@SvrName1+'].['+@DBName1 +'].dbo.SysUsers C, 
     ['+@SvrName1+'].['+@DBName1+'].dbo.SysObjects D   
Where A.uid = B.uid and B.Category = 0 and B.Type in (''P'', ''V'', ''Tr'', ''FN'')  
 	and A.Name = C.Name and B.Name=D.Name and C.uid = D.uid'      
Execute(@SQL)     
   
--Get the Text of the objects    
SET @SQL ='Insert into #ProcText 
Select P.ProcID, C.COLID, C.Text 
From #Procedures P, ['+@SvrName1+'].['+@DBName1+'].dbo.SysComments C 
Where P.objID =c.id and P.DBName ='''+@DB1+''''      
Execute(@SQL)      
      
SET @SQL ='Insert into #ProcText       
Select P.ProcID, C.ColID, C.Text       
From #Procedures P, ['+@SvrName2+'].['+@DBName2+'].dbo.SysComments C       
Where P.objID =C.id and P.DBName ='''+@DB2+''''      
Execute(@SQL)      
  
DECLARE ms_crs_syscom  CURSOR LOCAL FORWARD_ONLY  
        FOR Select P.ProcID, D.PText from #Procedures P, #ProcText D  
 WHERE P.ProcID = D.PRocID Order By P.DBName, P.ProcID, D.ColID      
        FOR READ ONLY      
      
SELECT @LFCR = 2      
SELECT @LineId = 1      
          
OPEN ms_crs_syscom      
SET @OldProcID = -1      
FETCH NEXT FROM ms_crs_syscom into  @ProcID, @SyscomText      
      
WHILE @@fetch_status = 0      
BEGIN      
      
    SELECT  @BasePos    = 1      
    SELECT  @CurrentPos = 1      
    SELECT  @TextLength = LEN(@SyscomText)  
  
    IF @ProcID <>@OldProcID       
    BEGIN      
 	SET @LineID = 1       
	SET @OldProcID = @ProcID      
    END      
    WHILE @CurrentPos  != 0      
    BEGIN      
        --Looking for end of line followed by carriage return      
        SELECT @CurrentPos =   CHARINDEX(char(13)+char(10), @SyscomText, @BasePos)      
      
        --If carriage return found      
        IF @CurrentPos != 0      
        BEGIN      
            /*If new value for @Lines length will be > then the      
            **set length then insert current contents of @line      
            **and proceed.      
  */      
            While (isnull(LEN(@Line),0) + @BlankSpaceAdded + @CurrentPos-@BasePos + @LFCR) > @DefinedLength      
            BEGIN      
		  	 SELECT @AddOnLen = @DefinedLength-(isnull(LEN(@Line),0) + @BlankSpaceAdded)      
                INSERT #ProcLineText VALUES      
                ( @ProcID, @LineId,      
                  isnull(@Line, N'') + isnull(SUBSTRING(@SyscomText, @BasePos, @AddOnLen), N''))      
                SELECT @Line = NULL, @LineId = @LineId + 1,      
                       @BasePos = @BasePos + @AddOnLen, @BlankSpaceAdded = 0      
            END      
            SELECT @Line    = isnull(@Line, N'') + isnull(SUBSTRING(@SyscomText, @BasePos, @CurrentPos-@BasePos + @LFCR), N'')      
            SELECT @BasePos = @CurrentPos+2      
            INSERT #ProcLineText VALUES( @ProcID, @LineId, @Line )      
            SELECT @LineId = @LineId + 1      
            SELECT @Line = NULL      
        END      
        ELSE      
        --else carriage return not found      
        BEGIN      
            IF @BasePos <= @TextLength      
            BEGIN      
                /*If new value for @Lines length will be > then the      
                **defined length      
                */      
                While (isnull(LEN(@Line),0) + @BlankSpaceAdded + @TextLength-@BasePos+1 ) > @DefinedLength      
                BEGIN      
                    SELECT @AddOnLen = @DefinedLength - (isnull(LEN(@Line),0) + @BlankSpaceAdded)      
                    INSERT #ProcLineText VALUES      
                    ( @ProcID, @LineId,      
                      isnull(@Line, N'') + isnull(SUBSTRING(@SyscomText, @BasePos, @AddOnLen), N''))      
                    SELECT @Line = NULL, @LineId = @LineId + 1,      
                        @BasePos = @BasePos + @AddOnLen, @BlankSpaceAdded = 0      
                END      
                SELECT @Line = isnull(@Line, N'') + isnull(SUBSTRING(@SyscomText, @BasePos, @TextLength-@BasePos+1 ), N'')      
                if LEN(@Line) < @DefinedLength and charindex(' ', @SyscomText, @TextLength+1 ) > 0      
                BEGIN      
                    SELECT @Line = @Line + ' ', @BlankSpaceAdded = 1      
                END      
            END      
        END      
    END      
      
 FETCH NEXT FROM ms_crs_syscom into @ProcID, @SyscomText      
END      
      
IF @Line is NOT NULL      
    INSERT #ProcLineText VALUES( @ProcId, @LineId, @Line )      
      
      
CLOSE  ms_crs_syscom      
IF (@ShowDifferentOnly=0)  
BEGIN  
	Print 'Procedures/Triggers Found Only in ' +@DB1      
	Print '----------------------------------'+Replicate('-', LEN(@DB1))      
	     
	Select L.LineText as 'Text'      
	From #ProcLineText L, #Procedures P       
	Where P.DBName =@DB1 and P.ObjID2 is NULL and L.ProcID = P.ProcID and
		P.Type<>'V'
	Order By ObjID, LineID      
	IF @@RowCount=0      
	 	Print '(None)'      
	      
	Print ' '      
	      
	Print 'Procedures/Triggers Found Only in ' +@DB2      
	Print '----------------------------------'+Replicate('-', LEN(@DB2))      
	      
	Select L.LineText as 'Text'      
	From #ProcLineText L, #Procedures P  
	Where P.DBName =@DB2 and P.ObjID2 is NULL and P.ProcId = L.PRocID and
		P.Type<>'V'      
	Order By ObjID, LineID      
	IF @@RowCount=0      
	 	Print '(None)'      
	      
	Print ' '      
END  
ELSE
BEGIN  
	Print 'Procedures/Triggers Found Only in ' +@DB1      
	Print '----------------------------------'+Replicate('-', LEN(@DB1))      
	     
	Select UserName+'.'+ ProcName
	From #Procedures        
	Where DBName =@DB1 and ObjID2 is NULL and Type<>'V'
	IF @@RowCount=0      
	 	Print '(None)'      
	      
	Print ' '      
	      
	Print 'Procedures/Triggers  Found Only in ' +@DB2      
	Print '-----------------------------------'+Replicate('-', LEN(@DB2))      
	      
	Select UserName+'.'+ ProcName
	From #Procedures        
	Where DBName =@DB2 and ObjID2 is NULL and Type<>'V'
	IF @@RowCount=0      
	 	Print '(None)'      
	      
	Print ' '      
END  
      
Print ' '      
--This part shows only the different lines     
IF (@ShowDifferentOnly=1)  
BEGIN  

	Print 'Views, Stored Procedures and Triggers with different Code (Lines Only)'      
	Print '---------------------------------------------------------------------'      
	Select P.UserName+'.'+P.ProcName [Procedure Name],  P.DBName [Database Name], 
		A.LineID [Line ID], A.LineText [Text]      
	From #ProcLineText A, #ProcLineText B, #Procedures P, #Procedures Q       
	Where P.ProcName = Q.ProcName and P.UserName = Q.UserName and 
	 	P.ProcID=A.ProcID and Q.ProcID = B.ProcID and P.ProcID<>Q.ProcID and
	 	A.LineID = B.LineID and   
	 	P.ObjID2 =Q.ObjID and Q.ObjID2 =P.ObjID and    
	 	A.LineText <>B.LineText       
	Order By P.UserName+'.'+P.ProcName, A.LineID, P.DBName
	
	IF @@RowCount=0      
	 	Print '(None)'      
END     
ELSE
BEGIN      
	 Print ''      
	 Print ''      
	 --This part shows all lines of the object (both databses) where there is a differnece    
	 Print 'Views, Stored Procedures and Triggers with different Code (Complete SQL Statements)'      
	 Print '-----------------------------------------------------------------------------------'      
	 Print @DB1      
	 Print Replicate('-', Len(@DB1))      
	       
	 Select C.LineText [Text]      
	 from #ProcLineText C,       
	 	(Select P.ProcID 
		From #ProcLineText A, #ProcLineText B, #Procedures P, #Procedures Q       
		Where P.ProcName = Q.ProcName and P.UserName = Q.UserName and 
	 		P.ProcID=A.ProcID and Q.ProcID = B.ProcID and P.ProcID<>Q.ProcID and
	 		A.LineID = B.LineID and P.DBName =@DB1 and Q.DBName = @DB2  and
	 		P.ObjID2 =Q.ObjID and Q.ObjID2 =P.ObjID and    
	 		A.LineText <>B.LineText) D  
	 Where C.ProcID =D.ProcID   
	 Order By C.ProcID, C.LineId
	 
	 IF @@RowCount=0      
	 	Print '(None)'      
	 Print ''
	      
	 Print @DB2      
	 Print Replicate('-', Len(@DB2))      
	       
	 Select C.LineText [Text]      
	 from #ProcLineText C,       
	 	(Select P.ProcID
		From #ProcLineText A, #ProcLineText B, #Procedures P, #Procedures Q       
		Where P.ProcName = Q.ProcName and P.UserName = Q.UserName and 
	 		P.ProcID=A.ProcID and Q.ProcID = B.ProcID and P.ProcID<>Q.ProcID and
	 		A.LineID = B.LineID and P.DBName =@DB2 and Q.DBName = @DB1  and
	 		P.ObjID2 =Q.ObjID and Q.ObjID2 =P.ObjID and    
	 		A.LineText <>B.LineText) D  
	 Where C.ProcID =D.ProcID   
	 Order By C.ProcID, C.LineId      
	       
	 IF @@RowCount=0      
	  	Print '(None)'      
END    
      
Print '-------------------------- End ---------------------------------------'      
      
Deallocate ms_crs_syscom        
Drop Table #ProcLineText      
Drop Table #ProcText      
Drop table #Procedures      
Drop table #TableColumns
Set nocount off      



