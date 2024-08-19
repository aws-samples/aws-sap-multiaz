* Get a hostname of the Active HANA Database Server.

CLASS ZCL_GET_DBHOST IMPLEMENTATION.

  METHOD constructor.
    DATA: lo_con TYPE REF TO cl_sql_connection,
          lo_stmt TYPE REF TO cl_sql_statement,
          lo_result TYPE REF TO cl_sql_result_set,
          lv_sql TYPE string,
          lt_data TYPE REF TO data,
          lt_dbhost TYPE TABLE OF ZTAWSMULTIDB,
          ls_dbhost TYPE ZTAWSMULTIDB.

    TRY.
      lo_con = cl_sql_connection=>get_connection( ).
      lo_stmt = lo_con->create_statement( ).

      lv_sql = |select host from M_DATABASE|.
      lo_result = lo_stmt->execute_query( lv_sql ).

      get REFERENCE OF gv_hostname into lt_data.
      lo_result->set_param( lt_data ).
      lo_result->next( ).

      lo_con->close( ).
      CATCH cx_sql_exception INTO DATA(err).
        MESSAGE err->get_text( ) TYPE 'E'.
    ENDTRY.
  ENDMETHOD.

  METHOD get_hostname.
      p_hostname = gv_hostname.
  ENDMETHOD.

ENDCLASS.

DATA: lo_get_dbhost TYPE REF TO ZCL_GET_DBHOST. 

CREATE OBJECT lo_get_dbhost.

CALL METHOD: lo_get_dbhost->get_hostname
             IMPORTING p_hostname = lv_hostname.

* Get a result of previous execution.
SELECT * INTO TABLE lt_dbhost FROM ZTAWSMULTIDB.

* Compare a current SQL execution with the previous execution
LOOP AT lt_dbhost INTO ls_dbhost.
  * If it is different, Updating the current result to a temporary table.
  IF lv_hostname NE ls_dbhost-dbhost.
    ls_current_dbhost-mandt = '100'.
    ls_current_dbhost-dbhost = lv_hostname.
    UPDATE ZTAWSMULTIDB FROM ls_current_dbhost.
  ENDIF.
ENDLOOP.