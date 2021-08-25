-------------------------------------------------------------------
SET SERVEROUTPUT ON SIZE 100000;

DECLARE
  match_count INTEGER;
-- Type the owner of the tables you are looking at
  v_owner VARCHAR2(255) :='DELFOUR';

-- Type the data type you are look at (in CAPITAL)
-- VARCHAR2, NUMBER, etc.
  v_data_type VARCHAR2(255) :='VARCHAR2';

-- Type the string you are looking at
  v_search_string VARCHAR2(4000) :='ZZJOE';

BEGIN
  FOR t IN (SELECT table_name, column_name,data_type  FROM all_tab_cols where owner=v_owner and data_type = v_data_type ) LOOP
    --dbms_output.put_line( t.table_name ||' '||t.column_name||' '||match_count );
    
    EXECUTE IMMEDIATE 
    'SELECT COUNT(*) FROM '||t.table_name||' WHERE lower('||t.column_name||') like :1'
    INTO match_count
    USING v_search_string;

    IF match_count > 0 THEN
      dbms_output.put_line( t.table_name ||' '||t.column_name||' '||match_count );
    END IF;
    
  END LOOP;
END;

/*
----------------------------------------------------
select * from M_QTY_BKD_PROF_H --QTY_BKD_PROF_CODE 2
select * from M_QTY_BKD_PROF_D where qty_bkd_prof_code = 'PCE' and comp_code = 'M1' --QTY_BKD_PROF_CODE 6
select * from M_ITEM_H where qty_bkd_prof_code = 'PCE' and comp_code = 'M1' --QTY_BKD_PROF_CODE 138
select * from M_ITEM_D1 where cust_code = 'CATELLI' 
----------------------------------------------------
select ID,CUST_CODE,INVT_LEV1,INVT_LEV2,INVT_ORG_RECD_DATE,INVT_LEV3,SKU_CODE_FACT,QTY_BKD_PROF_CODE,ON_ORD_QTY,ON_HAND_QTY from C_INVT
where 
  cust_code = 'CATELLI'
;
-----------------------------------------------------------
*/