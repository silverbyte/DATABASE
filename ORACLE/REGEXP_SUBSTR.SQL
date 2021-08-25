select  REGEXP_SUBSTR ('plt hlpt ea cs', '[^ ]+', 1, 1)   AS word_3 from dual;
select  REGEXP_SUBSTR ('plt hlpt ea cs', '[^ ]+', 1, 2)   AS word_3 from dual;
select  REGEXP_SUBSTR ('plt hlpt ea cs', '[^ ]+', 1, 3)   AS word_3 from dual;
select  REGEXP_SUBSTR ('plt hlpt ea cs', '[^ ]+', 1, 4)   AS word_3 from dual;


SELECT 
  '720' as QTY,
  '000120000002000006' as QTY_3LEVEL_6DIGIT,
  'PLT CS EA' QTY_LEVEL_DESC,
  
  '[' || TRUNC(SUM(720) / TO_NUMBER(SUBSTR('000120000006000001',1 * 6 - 5,6)),2) || REGEXP_SUBSTR (TRIM(TRAILING ' ' FROM REPLACE('PLT CS EA','  ',' ')), '[^ ]+', 1, 1) ||'] ' 
  as QTY_IN_PALLETS,  
  
  '[' || SUM(720) / TO_NUMBER(SUBSTR('000120000006000001',2 * 6 - 5,6))  || REGEXP_SUBSTR (TRIM(TRAILING ' ' FROM REPLACE('PLT CS EA','  ',' ')), '[^ ]+', 1, 2) || '] '
  as QTY_IN_CASES,
  
  '[' || SUM(720) / TO_NUMBER(SUBSTR('000120000006000001',3 * 6 - 5,6))  || REGEXP_SUBSTR (TRIM(TRAILING ' ' FROM REPLACE('PLT CS EA','  ',' ')), '[^ ]+', 1, 3) ||'] '
  as QTY_IN_EACHES,
  
  '[' || TRUNC(SUM(720) / TO_NUMBER(SUBSTR('000120000006000001',1 * 6 - 5,6)),2) || REGEXP_SUBSTR (TRIM(TRAILING ' ' FROM REPLACE('PLT CS EA','  ',' ')), '[^ ]+', 1, 1) ||'] ' || 
  '[' || SUM(720) / TO_NUMBER(SUBSTR('000120000006000001',2 * 6 - 5,6))  || REGEXP_SUBSTR (TRIM(TRAILING ' ' FROM REPLACE('PLT CS EA','  ',' ')), '[^ ]+', 1, 2) || '] ' || 
  '[' || SUM(720) / TO_NUMBER(SUBSTR('000120000006000001',3 * 6 - 5,6))  || REGEXP_SUBSTR (TRIM(TRAILING ' ' FROM REPLACE('PLT CS EA','  ',' ')), '[^ ]+', 1, 3) ||'] '
  as QTY_IN_ALL_DESC   
  
FROM DUAL
