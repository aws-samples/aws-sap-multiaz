class /AWSSAMP/CL_MAZ_GET_DBHOST definition
  public
  final
  create public .

public section.

  methods CONSTRUCTOR .
  methods GET_HOSTNAME
    exporting
      !P_HOSTNAME type CHAR20 .
protected section.
private section.

  data GV_HOSTNAME type CHAR20 .
ENDCLASS.



CLASS /AWSSAMP/CL_MAZ_GET_DBHOST IMPLEMENTATION.


  METHOD CONSTRUCTOR.

    DATA: lo_con TYPE REF TO cl_sql_connection,
          lo_stmt TYPE REF TO cl_sql_statement,
          lo_result TYPE REF TO cl_sql_result_set,
          lv_sql TYPE string,
          lt_data TYPE REF TO data.

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


  METHOD GET_HOSTNAME.
      p_hostname = gv_hostname.
  ENDMETHOD.
ENDCLASS.
