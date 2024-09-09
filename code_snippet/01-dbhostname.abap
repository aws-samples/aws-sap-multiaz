* Get a hostname of the Active HANA Database Server.

DATA: lv_hostname TYPE char20.
      lo_con TYPE REF TO cl_sql_connection,
      lo_stmt TYPE REF TO cl_sql_statement,
      lo_result TYPE REF TO cl_sql_result_set,
      lv_sql TYPE string,
      lt_data TYPE REF TO data.

TRY.
      lo_con = cl_sql_connection=>get_connection( ).
      lo_stmt = lo_con->create_statement( ).

      lv_sql = |select host from M_DATABASE|.
      lo_result = lo_stmt->execute_query( lv_sql ).

      get REFERENCE OF lv_hostname into lt_data.
      lo_result->set_param( lt_data ).
      lo_result->next( ).

      lo_con->close( ).
      CATCH cx_sql_exception INTO DATA(err).
        MESSAGE err->get_text( ) TYPE 'E'.
ENDTRY.


DATA: lo_get_dbhost TYPE REF TO /AWSSAMP/CL_MAZ_GET_DBHOST. 

* Get a result of previous execution.
SELECT * INTO TABLE lt_dbhost FROM ZTAWSMULTIDB.

* Compare a current SQL execution with the previous execution
LOOP AT lt_dbhost INTO ls_dbhost.
  * If it is different, Updating the current result to a temporary table.
  IF lv_hostname NE ls_dbhost-dbhost.
    ls_current_dbhost-mandt = '100'.
    ls_current_dbhost-dbhost = lv_hostname.
    * Update current Active DB Hostname into /AWSSAMP/MAZ_DB 
    UPDATE /AWSSAMP/MAZ_DB FROM ls_current_dbhost.
  ENDIF.
ENDLOOP.