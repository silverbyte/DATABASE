set nocount on

declare @Rows int,
  @LevelID int
declare @Tables TABLE (
TableName varchar(200),
LevelID int)

insert into @Tables (TableName, LevelID)
select name, 1
from sysobjects
where xtype= 'U'

select @Rows = @@RowCount, @LevelID = 1

while @Rows > 1 begin
update @Tables 
set LevelID = LevelID + 1
where TableName in (select distinct master.name
from
sysobjects master,

sysobjects ref,

sysreferences refkey
where
refkey.fkeyid = ref.id
  and
refkey.rkeyid = master.id
  and
ref.Name in (select distinct TableName from @Tables where LevelID =
@LevelID)
)
select @Rows = @@RowCount
select @LevelID = @LevelID + 1
end

select * 
from @Tables 
order by 2 desc,1