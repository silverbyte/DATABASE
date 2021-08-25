---------- Monday of specified 52weeks in the year -------------
--
-- --example week1 in 2004 
-- select dbo.udf_mondayofaweek(1,2001)
-- --results
-- 2001-01-01 00:00:00.000
--
-- --example week 22 in 2003 
-- select dbo.udf_mondayofaweek(22,2003)
-- --results
-- 2003-05-26 00:00:00.000
---------------------------------------------------------------------


set datefirst 1
go
Create function dbo.udf_Mondayofaweek(
@week int,
@year varchar(4))
returns datetime
as
begin
declare @date varchar(10)
declare @firstdayofweek datetime
set @date='01/01/'+@year
set @date =convert(varchar(10),convert(datetime,@date) 
  - (datepart(dw,@date)-1),101)
set @firstdayofweek =dateadd(ww,@week-1,@date)
return @firstdayofweek 
end
go

