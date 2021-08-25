create function dbo.date(@date datetime)
returns varchar(20)
As


--Script Language and Platform:MS SQL 2000
--Objecttive: New way of displaying date.This function can 
--give you the most legible way to present a date
--Usage Ex: select dbo.date(DOB) from customers
--Author:Claire Hsu  
--Date  :2003/4/30
--Email:messageclaire@yahoo.com



begin
declare @string varchar(20)
set @string = 
(select left(datename(month,@date),3)+" 
     "+convert(varchar(2),day(@date))+(case 
when right(day(@date),1)=1 and day(@date)<>11 then 'st'
when right(day(@date),1)=2 and day(@date)<>12 then 'nd'
when right(day(@date),1)=3 and day(@date)<>13 then 'rd'
else 'th' end)+"'"+datename(year,@date))

return (@string)
end



--Usage
--select dbo.date(datetime_filed_column) from table_name
--select dbo.date('2/24/2001') as DATE


/*This is the result display

Jan 1st'2001

Mar 3rd'2003

Mar 15th'2002
*/
