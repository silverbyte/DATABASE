SELECT 
'SELECT * FROM ' ||  replace(TABSCHEMA,' ','') || '.' || replace(TABNAME,' ','') || ' WHERE ' || COLNAME || ' = ''343709'';'
--select *
FROM SYSCAT.columns
WHERE tabschema IN ('TMWIN')
order by TABNAME


select * from SYSCAT.columns order by TABNAME



