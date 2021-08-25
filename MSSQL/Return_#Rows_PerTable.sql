
----- Return # rows for each table  -----------------------------
select "TABLE NAME"= convert (varchar (50), o.name), ROWS=i.rows
from sysobjects o, sysindexes i
where o.type = 'U'
and o.id = i.id
and i.indid in (0,1)
order by o.name
