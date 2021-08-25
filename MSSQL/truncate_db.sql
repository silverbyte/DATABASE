/**************************************************************************
This script will delete data from every table in the database except
those specified in the @NoDeleteLst.

@NoDeleteLst = 	Comma seperated list of all tables you DO NOT want this 
		script to delete.
		
		Example:
		SET @NoDeleteLst = "Application,App_Parameter,Parameter" 
		
		The above will keep the script from deleting from the
		Application,App_Parameter and Parameter tables.

NOTE:	SCROLL TO MIDDLE OF SCRIPT TO SET @NoDeleteLst.
***************************************************************************/

--Make sure fnSplit exists. If not...create it
if exists (select * from dbo.sysobjects where id = object_id(N"[dbo].[fnSplit]") and xtype in (N"FN", N"IF", N"TF"))
drop function [dbo].[fnSplit]
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

CREATE FUNCTION fnSplit(@sText varchar(8000), @sDelim varchar(20) = " ")
RETURNS @retArray TABLE (idx smallint Primary Key, value varchar(8000))
/*********************************************************************************************************************
This function parses a delimited string and returns it as an ID"d table.

Parameter Definition:
---------------------------------
@sText = Delimited string to be parsed.
@sDelim = Delimitation character used to seperate list ov values.

RETURNS:
---------------------------
Returns the table defined below:

Column 		Description
----------		------------------
idx		ID column for array
value		Value split from list.

*********************************************************************************************************************/
AS
BEGIN
DECLARE @idx smallint,
	@value varchar(8000),
	@bcontinue bit,
	@iStrike smallint,
	@iDelimlength tinyint

IF @sDelim = "Space"
	BEGIN
	SET @sDelim = " "
	END

SET @idx = 1
SET @sText = LTrim(RTrim(@sText))
SET @iDelimlength = DATALENGTH(@sDelim)
SET @bcontinue = 1

IF NOT ((@iDelimlength = 0) or (@sDelim = "Empty"))
	BEGIN
	WHILE @bcontinue = 1
		BEGIN

--If you can find the delimiter in the text, retrieve the first element and
--insert it with its index into the return table.
 
		IF CHARINDEX(@sDelim, @sText)>0
			BEGIN
			SET @value = SUBSTRING(@sText,1, CHARINDEX(@sDelim,@sText)-1)
				BEGIN
				INSERT @retArray (idx, value)
				VALUES (@idx, @value)
				END
			
--Trim the element and its delimiter from the front of the string.
			--Increment the index and loop.
SET @iStrike = DATALENGTH(@value) + @iDelimlength
			SET @idx = @idx + 1
			SET @sText = LTrim(Right(@sText,DATALENGTH(@sText) - @iStrike))
		
			END
		ELSE
			BEGIN
--If you can’t find the delimiter in the text, @sText is the last value in
--@retArray.
 SET @value = @sText
				BEGIN
				INSERT @retArray (idx, value)
				VALUES (@idx, @value)
				END
			--Exit the WHILE loop.
SET @bcontinue = 0
			END
		END
	END
ELSE
	BEGIN
	WHILE @bcontinue=1
		BEGIN
		--If the delimiter is an empty string, check for remaining text
		--instead of a delimiter. Insert the first character into the
		--retArray table. Trim the character from the front of the string.
--Increment the index and loop.
		IF DATALENGTH(@sText)>1
			BEGIN
			SET @value = SUBSTRING(@sText,1,1)
				BEGIN
				INSERT @retArray (idx, value)
				VALUES (@idx, @value)
				END
			SET @idx = @idx+1
			SET @sText = SUBSTRING(@sText,2,DATALENGTH(@sText)-1)
			
			END
		ELSE
			BEGIN
			--One character remains.
			--Insert the character, and exit the WHILE loop.
			INSERT @retArray (idx, value)
			VALUES (@idx, @sText)
			SET @bcontinue = 0	
			END
	END

END

RETURN
END

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
SET NOCOUNT ON
DECLARE @NoDeleteLst varchar(8000)

-------------------------------------------------------------------------------------------------------
--SET NO-DELETE LIST HERE (tbls you dont want to delete from) - Comma seperated list. "tbl1,tbl2,tbl3"
-------------------------------------------------------------------------------------------------------

SET @NoDeleteLst = "" 

-------------------------------------------------------------------------------------------------------


DECLARE @tbls TABLE(IDX int IDENTITY(1,1), Tbl varchar(255))
DECLARE @Tbl varchar(255)

INSERT INTO @tbls(Tbl)
SELECT DISTINCT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = "BASE TABLE"
AND LEFT(TABLE_NAME,2) <> "dt"
AND TABLE_NAME NOT IN(SELECT VALUE FROM fnSplit(@NoDeleteLst,","))

--Disable Constraints
PRINT "-----------------------------------------------" + CHAR(13) + CHAR(13)
DECLARE curDeleteDB CURSOR FOR 
SELECT DISTINCT Tbl
FROM @tbls

OPEN curDeleteDB

FETCH NEXT FROM curDeleteDB
INTO @tbl

WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN 
		PRINT "Disabling constraints/triggers for - " + @tbl 
		EXEC("ALTER TABLE [" + @tbl + "] NOCHECK CONSTRAINT ALL")
		EXEC("ALTER TABLE [" + @tbl + "] DISABLE TRIGGER ALL")
	END
	FETCH NEXT FROM curDeleteDB
	INTO @tbl
END
CLOSE curDeleteDB
DEALLOCATE curDeleteDB

--Delete Data
PRINT "-----------------------------------------------" + CHAR(13) + CHAR(13)
DECLARE curDeleteDB CURSOR FOR 
SELECT DISTINCT Tbl
FROM @tbls

OPEN curDeleteDB

FETCH NEXT FROM curDeleteDB
INTO @tbl

WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN 
		PRINT "Deleting from - " + @tbl 
		EXEC("DELETE FROM [" + @tbl + "]")

		--If table has IDENTITY column reset the seed
		IF EXISTS
		(
			SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
			WHERE COLUMNPROPERTY(OBJECT_ID("dbo." + @tbl) ,COLUMN_NAME,"IsIdentity") = 1
			AND TABLE_NAME = @tbl
		)
		BEGIN
			EXEC("DBCC CHECKIDENT (""" + @tbl + """, RESEED, 0)")
		END
	END
	FETCH NEXT FROM curDeleteDB
	INTO @tbl
END
CLOSE curDeleteDB
DEALLOCATE curDeleteDB

--Re-Enable Constraints
PRINT "-----------------------------------------------" + CHAR(13) + CHAR(13)
DECLARE curDeleteDB CURSOR FOR 
SELECT DISTINCT Tbl
FROM @tbls

OPEN curDeleteDB

FETCH NEXT FROM curDeleteDB
INTO @tbl

WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN 
		PRINT "Enabling constraints/triggers for - " + @tbl 
		EXEC("ALTER TABLE [" + @tbl + "] CHECK CONSTRAINT ALL")
		EXEC("ALTER TABLE [" + @tbl + "] ENABLE TRIGGER ALL")
	END
	FETCH NEXT FROM curDeleteDB
	INTO @tbl
END
CLOSE curDeleteDB
DEALLOCATE curDeleteDB


SET NOCOUNT OFF


 
