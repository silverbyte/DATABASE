CREATE PROCEDURE LM_GenMetaXML
@TableName varchar(255)

/*******************************************************************************************************************************************************************************************************************************
* Stored Procedure: LM_GenMetaXML 'Tablename'									
* Creation Date:  3/12/2002							
* Copyright: Luke Malyurek										
* Written by: Luke Malyurek							
*													
* Purpose: Stored Procedure builds an XML document containing metadata for a given TableName / Parameter.  I have placed 
*	this in an asp file along with a style sheet to format the output in our environment.  A little tweaking 
*	with vbScript for a pull down list of tablenames, and it works well.  Now all of our developers can see
*	our column names, types, nullablility, etc. through their web browsers.  I have placed this in a Stored Procedure
*	just for posting the code.  I suppose you could easily call the proc from a page too.  Please note that the
*	exlusions of objects with a name like 'meta%' is specific to my current schemas so you will be able to remove
*	these.
*
*
* Input Parameters: 
*		@TableName varchar(255)
*
* Local Variables: 
*
* Updates:	
*
*******************************************************************************************************************************************************************************************************************************/
AS

	      SET NOCOUNT ON  
	      SELECT distinct 1 as tag, 
	             NULL  as parent, 
	             syso.name as [Table!1!TableName], 
	             NULL as [Column!2!ColumnName!element], 
	             NULL as [DataType!4!DataType!element], 
	             NULL as [Column!2!Length!element], 
	             NULL as [Column!2!IsNullable!element], 
	             NULL as [Column!2!Columnid], 
	             NULL as [Property!3!Description!element]
	        FROM sysobjects syso 
	       WHERE syso.name != 'dtproperties' 
	         AND syso.name != 'meta' and syso.xtype = 'u' 
	         AND syso.name = @TableName

	   UNION ALL SELECT 2 as tag, 
	             1 as parent, 
	             syso.name, 
	             syscol.name, 
	             NULL, syscol.length, 
	             syscol.isnullable,
	             syscol.colid, 
	             NULL
	        FROM sysobjects syso 
	   LEFT JOIN syscolumns syscol 
	          ON syso.id = syscol.id 
	       WHERE syso.name != 'dtproperties' 
	         AND syso.name != 'meta' and syso.xtype = 'u' 
	         AND syso.name = @TableName

	   UNION ALL SELECT 3 as tag, 
	             2  as parent, 
	             syso.name, 
	             syscol.name, 
	             null, 
	             null, 
	             null, 
	             syscol.colid,
	             isnull(sysp.value, '') 
	        FROM sysobjects syso 
	   LEFT JOIN syscolumns syscol 
	          ON syso.id = syscol.id 
	   LEFT JOIN sysproperties sysp 
	          ON syscol.id = sysp.id 
	         AND syscol.colid = sysp.smallid 
	       WHERE syso.name != 'dtproperties' 
	         AND syso.name != 'meta' and syso.xtype = 'u' 
	         AND syso.name = @TableName

	   UNION ALL SELECT 4 as tag, 
	             2 as parent, 
	             syso.name, 
	             syscol.name, 
	             syst.name, 
	             null, 
	             null, 
	             syscol.colid, 
	             null
	        FROM sysobjects syso 
	   LEFT JOIN syscolumns syscol on syso.id = syscol.id 
	   LEFT JOIN systypes syst on syscol.xtype = syst.xtype
	       WHERE syso.name = @TableName
	         AND syst.name != 'sysname'

	    ORDER BY [Table!1!TableName],
	             [Column!2!Columnid],
	             [DataType!4!DataType!element],
	             [Column!2!ColumnName!element],
	             [Property!3!Description!element] 
	             for xml explicit

