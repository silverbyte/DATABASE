set serveroutput on size 100000

declare
    v_match_count integer;
    v_counter integer;

    -- The owner of the tables to search through (case-sensitive)
    v_owner varchar2(255) := 'DELFOUR';
    -- A string that is part of the data type(s) of the columns to search through (case-insensitive)
    v_data_type varchar2(255) := 'VARCHAR2';
    -- The string to be searched for (case-insensitive)
    v_search_string varchar2(4000) := '1020.W06.01';

    -- Store the SQL to execute for each table in a CLOB to get around the 32767 byte max size for a VARCHAR2 in PL/SQL
    v_sql clob := '';
begin
    for cur_tables in (select owner, table_name from all_tables where owner = v_owner and table_name in 
                       (select table_name from all_tab_columns where owner = all_tables.owner and data_type like '%' ||  upper(v_data_type) || '%')
                       order by table_name) loop
        v_counter := 0;
        v_sql := '';

        for cur_columns in (select column_name from all_tab_columns where 
                            owner = v_owner and table_name = cur_tables.table_name and data_type like '%' || upper(v_data_type) || '%') loop
            if v_counter > 0 then
                v_sql := v_sql || ' or ';
            end if;
            --v_sql := v_sql || 'upper(' || cur_columns.column_name || ') like ''%' || upper(v_search_string) || '%''';
            v_sql := v_sql || 'upper(' || cur_columns.column_name || ') = ''' || upper(v_search_string) || '''';
            v_counter := v_counter + 1;
        end loop;

        v_sql := 'select count(*) from ' || cur_tables.table_name || ' where ' || v_sql;

        execute immediate v_sql
        into v_match_count;

        if v_match_count > 0 then
            dbms_output.put_line('Match in ' || cur_tables.owner || ': ' || cur_tables.table_name || ' - ' || v_match_count || ' records');
        --else            
           --dbms_output.put_line('NOTTA!');
        end if;
    end loop;

    exception
        when others then
            dbms_output.put_line('Error when executing the following: ' || dbms_lob.substr(v_sql, 32600));
end;
/