------------- spell the numbers -------------------
--
--  SELECT dbo.udf_spellnumbers (70000)
--  --result
--  SEVEN ZERO ZERO ZERO ZERO 
--
--  SELECT dbo.udf_spellnumbers (1234567890)
--  --result
--  ONE TWO THREE FOUR FIVE SIX SEVEN EIGHT NINE ZERO 
---------------------------------------------------

Create function dbo.udf_spellnumbers (@big bigint)
returns varchar(1000)
as
begin
--declare @big bigint
--Created by :MAK
--Date: Jun 1, 2004
--contact: mak_999@yahoo.com

declare @count int
declare @length  int
declare @bigvar varchar(100)
declare @spell varchar(1000)
DECLARE @WORD VARCHAR(10)
set @count =1
set @bigvar = convert(varchar(100),@big)
set @length = len(@bigvar)
SET @SPELL=''
while @count <=@length
begin
SELECT @WORD = case substring(@bigvar,@count,1)  
when '1' then 'ONE ' 
when '2' then 'TWO ' 
when '3' then 'THREE ' 
when '4' then 'FOUR ' 
when '5' then 'FIVE ' 
when '6' then 'SIX ' 
when '7' then 'SEVEN ' 
when '8' then 'EIGHT ' 
when '9' then 'NINE ' 
when '0' then 'ZERO '  
ELSE '' end

set @spell = @spell + @WORD
set @count=@count+1
END
RETURN @SPELL

