/*
//////////////////////////////////////////////////////////////////////////////////
Author: Rusty Hansen 8-21-2001
Description: Formats a date to a specific format.
Parameters:
     @dDate = A value or field of datatype datetime or a value or field that can be explicitly converted to 
              a datetime datatype.
     @sFormat varchar(40) = Format codes using the characters described below
       
     MMMM or DDDD = the full name for the day or month
     MMM or DDD = the first 3 letters of the month or day
     MM or DD = the two digit code signifying the month or day
     M1 or D1 = the month or day value without a preceding zero
     YYYY = a four digit year
     YY = a two digit year
     
     All other characters will not be replaced such as / - . * # a b z x % and will show
     up in the date in the same relative position that they appear in the format
     parameter.
     
     Examples
     select dbo.FormatDate('9/21/2001','dddd, mmmm d1, yyyy') --> Friday, September 21, 2001
     select dbo.FormatDate('9/21/2001','mm/dd/yyyy') --> 09/21/2001
     select dbo.FormatDate('9/21/2001','mm-dd-yyyy') --> 09/21/2001
     select dbo.FormatDate('9/21/2001','yyyymmdd') --> 20010921
     select dbo.FormatDate('9/5/2001','m1/d1/yy') --> 9/5/01
     select dbo.FormatDate('9/21/2001','mmm-yyyy') --> Sep-2001

//////////////////////////////////////////////////////////////////////////////////
*/

create function [dbo].[FormatDate]
     (
     @dDate datetime          --Date value to be formatted
     ,@sFormat varchar(40)    --Format for date value
     )
returns varchar(40)
as
begin

     -- Insert the Month
     -- ~~~~~~~~~~~~~~~~
     set @sFormat = replace(@sFormat,'MMMM',datename(month,@dDate))
     set @sFormat = replace(@sFormat,'MMM',convert(char(3),datename(month,@dDate)))
     set @sFormat = replace(@sFormat,'MM',right(convert(char(4),@dDate,12),2))
     set @sFormat = replace(@sFormat,'M1',convert(varchar(2),convert(int,right(convert(char(4),@dDate,12),2))))

     -- Insert the Day
     -- ~~~~~~~~~~~~~~
     set @sFormat = replace(@sFormat,'DDDD',datename(weekday,@dDate))
     set @sFormat = replace(@sFormat,'DDD',convert(char(3),datename(weekday,@dDate)))
     set @sFormat = replace(@sFormat,'DD',right(convert(char(6),@dDate,12),2))
     set @sFormat = replace(@sFormat,'D1',convert(varchar(2),convert(int,right(convert(char(6),@dDate,12),2))))

     -- Insert the Year
     -- ~~~~~~~~~~~~~~~
     set @sFormat = replace(@sFormat,'YYYY',convert(char(4),@dDate,112))
     set @sFormat = replace(@sFormat,'YY',convert(char(2),@dDate,12))

     -- Return the function's value
     -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~  
     return @sFormat
end