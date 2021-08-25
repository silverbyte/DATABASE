/*
The difference is dba_source will have the text of all stored objects. 
All_source will have the text of all stored objects accessible by the user performing the query. Oracle Database Reference 11g Release 2 (11.2)
*/

SELECT * FROM ALL_source WHERE UPPER(text) LIKE '%205%'

SELECT * FROM DBA_source WHERE UPPER(text) LIKE '%205%'

----------------------------------------------------------------

SELECT DISTINCT NAME FROM DBA_source 
WHERE 
  UPPER(text) LIKE '%C_CART_D%'
  AND 
  UPPER(text) LIKE '%INSERT%'