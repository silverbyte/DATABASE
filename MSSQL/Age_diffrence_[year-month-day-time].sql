----------- Determine Age diffrence ------------------
-- --EXAMPLE :
-- select dbo.age(''11/01/1974'', getdate()) 
-- -- returns 28 year(s) 7 month(s) 10 day(s) 14:40:16
-- -- This is more accurate than using datediff
------------------------------------------------------



CREATE FUNCTION dbo.age(@start datetime, @end datetime)
RETURNS varchar(42) -- select len('999 year(s) 99 month(s) 99 day(s) 99:99:99') -- 42 characters
AS
BEGIN


	-- declare @start datetime, @end datetime select @start = '01/01/1996 07:30:00', @end = getdate()


	declare @year int
	declare @month int
	declare @counter_date datetime
	
	
	select @year = 0
	select @month = 0
	select @counter_date = @start
	
	
	while @counter_date < @end
	begin
	
		select @year = @year + 1
		select @counter_date = dateadd(year, 1, @counter_date)
	
	end
	
	
	if @counter_date > @end
	begin
		select @year = @year - 1
		select @counter_date = dateadd(year, -1, @counter_date)
	end
	
	
	while @counter_date < @end
	begin
	
		select @month = @month + 1
		select @counter_date = dateadd(month, 1, @counter_date)
	
	end
	
	
	if @counter_date > @end
	begin
		select @month = @month - 1
		select @counter_date = dateadd(month, -1, @counter_date)
	end


	-- select @counter_date
	-- select 'Age' = convert(varchar, @year) + ' year(s) ' + convert(varchar, @month) + ' month(s) ' + dbo.ddhhmmss(@counter_date, @end)


	RETURN 	convert(varchar, @year) + ' year(s) ' + 
		convert(varchar, @month) + ' month(s) ' + 
		dbo.ddhhmmss(@counter_date, @end)


END

