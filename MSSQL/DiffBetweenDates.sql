/*
select dbo.DiffBetweenDates('5/10/01 9:45:00 ', '5/12/01 14:00:00') 

output 
2Days, 4Hours, 15Minutes 

(1 row(s) affected) 

*/


CREATE FUNCTION dbo.DiffBetweenDates(
	@StartDT DATETIME,
	@EndDT	DATETIME)
RETURNS VARCHAR(30)
AS
BEGIN

	DECLARE	@intMin Int,
				@intHrs Int,
				@intDys Int,
				@TotalMin Int,
				@strOUTPUT Varchar(30)

	SET @TotalMin = ABS(DATEDIFF(mi, @StartDT, @EndDT))
	SET @intDys = @TotalMin / (24*60)
	SET @intHrs = (@TotalMin-(@intDys*24*60)) / 60
	SET @intMin = @TotalMin-((@intDys*24*60)+(@intHrs*60))

	If @StartDT <= @EndDT
		Begin
			SET @strOUTPUT = CAST(@intDys as varchar(5)) + 'Days, ' + CAST(@intHrs as varchar(2)) + 'Hours, ' +  cast( @intMin as varchar(2)) + 'Minutes'
		End
	Else
		Begin
			SET @strOUTPUT = '-(' + cast( @intDys as varchar(5)) + 'Days, ' + cast( @intHrs as varchar(2)) + 'Hours, ' +  cast( @intMin as varchar(2)) + 'Minutes' + ')'
		End

	RETURN @strOUTPUT

END