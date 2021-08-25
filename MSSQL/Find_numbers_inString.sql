---------------------- Example. ---------------------------
-- --example 1: 
-- select dbo.udf_findallnumbers ('assd123jdh556jdfd4j56j78')
-- --results
-- 12355645678
--
-- --example 2:
-- select dbo.udf_findallnumbers ('sadasd')
-- --results
-- 0
--
-- --example 3:
-- create table test (name varchar(100))
-- insert into test select 'A2b4b2b5bb6bb8bb9'
-- insert into test select 'MAK9974'
-- insert into test select 'Eiko36DKoike'
-- 
-- select dbo.udf_findallnumbers (name) from test
-- --results
-- 2425689
-- 9974
-- 36
--------------------------------------------------------------


Create function dbo.udf_findallnumbers (@inputstring varchar(100))
returns bigint
as
begin
--Author : MAK
--Contact: mak_999@yahoo.com
--Date: Feb 2, 2004
--declare variables
declare @count1 smallint
declare @len1 smallint
declare @word varchar(100)
declare @char1 char
--Assignment
set @word=''
set @count1=1
set @len1 = datalength(@inputstring)

	While @count1 <=@len1
	begin
	set @char1 =substring(@inputstring,@count1,1)
	if ascii(@char1) between 48 and 57 
	begin
	set @word=@word+substring(@inputstring,@count1,1)
	end
	set @count1=@count1+1
	end
return convert(bigint,@word)

end

