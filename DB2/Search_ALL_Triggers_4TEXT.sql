select 
    trigname as trigger_name,
    tabschema concat '.' concat tabname as table_name, 
    case trigtime 
         when 'B' then 'before'
         when 'A' then 'after'
         when 'I' then 'instead of' 
    end as activation,
    rtrim(case when eventupdate ='Y' then  'update ' else '' end 
          concat 
          case when eventdelete ='Y' then  'delete ' else '' end
          concat
          case when eventinsert ='Y' then  'insert ' else '' end)
    as event,   
    case when ENABLED = 'N' then 'disabled'
    else 'active' end as status,
    text as definition
from syscat.triggers t
where tabschema not like 'SYS%' and text like '%13%'
order by trigname