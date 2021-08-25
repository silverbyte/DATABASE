/*
   *	Script Language and Platform:MS SQL 7/2000
   *	Objecttive: Add 'n' working days to the given date 
   *	Usage:Which date it is?Add 16 workdays to '1/1/2003'?
   *	select dbo.getwork('1/1/2003','16')
   *	Author:Claire Hsu  
   *	Date  :2003/7/17
   *	Email:messageclaire@yahoo.com
   *	Description:This script contains both funciton and procedure.
   *	You could apply accordingly
*/

--Here is the code for Function
-------------------------------------------------------------------------------
Create function dbo.getwork (@date datetime,@nd int)
returns datetime
as
begin

declare @wk int
select @wk = datepart(dw,@date)
declare @work datetime

	if @nd > (6-@wk)
	begin
	if (@nd-(6-@wk))%5 = 0
	set @work = @date+(6-@wk)+7*((@nd-(6-@wk))/5)+(@nd-(6-@wk))%5
	else 
	set @work = @date+(6-@wk)+7*((@nd-(6-@wk))/5)+(@nd-(6-@wk))%5+2
	end	
	if @nd <= (6-@wk)
	begin
	set @work = @date+@nd
	end

if @wk = 7 
begin
	if @nd%5 = 0
	set @work = @date+7*((@nd)/5)-1
	if @nd%5<>0 
	set @work = @date+7*((@nd)/5)+1+@nd%5	
end

if @wk = 1
begin
	if @nd%5 = 0
	set @work = @date+7*((@nd)/5)-2
	if @nd%5<>0 
	set @work = @date+7*((@nd)/5)+@nd%5	
end
return (@work)
end

--Usage
--select dbo.getwork('1/1/2003','16')
--SELECT dbo.getwork(col_name, 9) from tablename

----------------------------------------------------------------------------
----------------------------------------------------------------------------

--Here is the code for Stored Procedure
Create proc getwork @date datetime,@nd int
as
declare @wk int
select @wk = datepart(dw,@date)
declare @work datetime

	if @nd > (6-@wk)
	begin
	if (@nd-(6-@wk))%5 = 0
	set @work = @date+(6-@wk)+7*((@nd-(6-@wk))/5)+(@nd-(6-@wk))%5
	else 
	set @work = @date+(6-@wk)+7*((@nd-(6-@wk))/5)+(@nd-(6-@wk))%5+2
	end	
	if @nd <= (6-@wk)
	begin
	set @work = @date+@nd
	end

if @wk = 7 
begin
	if @nd%5 = 0
	set @work = @date+7*((@nd)/5)-1
	if @nd%5<>0 
	set @work = @date+7*((@nd)/5)+1+@nd%5	
end

if @wk = 1
begin
	if @nd%5 = 0
	set @work = @date+7*((@nd)/5)-2
	if @nd%5<>0 
	set @work = @date+7*((@nd)/5)+@nd%5	
end
select @work

--Usage
--exec getwork '1/2/2003','17'
