SELECT
	TOP 100 PERCENT obj.name AS table_name, 
	cols.name AS field_name, 
	type.name AS field_type, 
	cols.length AS field_size, 
	props.[value] AS field_description, 
	cols.isnullable AS field_nullable, 
	type.tdefault AS field_default

FROM
      dbo.sysobjects obj 
      INNER JOIN
         dbo.syscolumns cols ON obj.id = cols.id 
      LEFT OUTER JOIN
         dbo.sysproperties props ON cols.id = props.id 
         AND cols.colid = props.smallid 
      LEFT OUTER JOIN
         dbo.systypes type ON cols.xtype = type.xusertype

WHERE
	(obj.type = 'U')

ORDER BY
	table_name

