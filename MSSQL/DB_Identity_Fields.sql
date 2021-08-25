/* Purpose 	: To find which table's got Identity Colums in a database
                  and there Seed & Increment value
*/

SELECT 
  IDENT_SEED(TABLE_NAME) AS Seed
, IDENT_INCR(TABLE_NAME) AS Increment
, TABLE_NAME
 FROM INFORMATION_SCHEMA.TABLES
 WHERE OBJECTPROPERTY(OBJECT_ID(TABLE_NAME), 'TableHasIdentity') = 1
 AND TABLE_TYPE = 'BASE TABLE'
