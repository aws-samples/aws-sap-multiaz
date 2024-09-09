class /AWSSAMP/CL_MAZ_BP_GROUP definition
  public
  inheriting from CL_BP_SERVER_GROUP
  final
  create public .

public section.

  methods LOAD_SRV_LIST
    importing
      !P_GROUPNAME type CHAR20 .
  methods GET_SRV_LIST
    exporting
      !P_LIST type BPSRVENTRY .
  methods DEL_FROM_SRV_LIST
    importing
      !P_SRV type BPSRVLINE .
  methods ADD_TO_SRV_LIST
    importing
      !P_SRV type BPSRVLINE .
  methods SAVE_SRV_LIST_DB .
protected section.
private section.
ENDCLASS.



CLASS /AWSSAMP/CL_MAZ_BP_GROUP IMPLEMENTATION.


  METHOD ADD_TO_SRV_LIST.
    CALL METHOD ADD_TO_LIST
      EXPORTING I_SRV_ENTRY = p_srv.
  ENDMETHOD.


  METHOD DEL_FROM_SRV_LIST.
    CALL METHOD DEL_FROM_LIST
      EXPORTING I_SRV_ENTRY = p_srv.
  ENDMETHOD.


  METHOD GET_SRV_LIST.
    CALL METHOD GET_LIST
      RECEIVING o_list = p_list.
  ENDMETHOD.


  METHOD LOAD_SRV_LIST.
    TRY.
      CALL METHOD LOAD_DB
        EXPORTING i_name = p_groupname.
    CATCH CX_BP_HEALTH_DATA.
      MESSAGE 'Data Inconsistency Found.' TYPE 'E'.
    CATCH CX_UUID_ERROR.
      MESSAGE 'Error Class for UUID Processing Errors.' TYPE 'E'.
    ENDTRY.
  ENDMETHOD.


  METHOD SAVE_SRV_LIST_DB.
    TRY.
      CALL METHOD SAVE_DB.
    CATCH CX_BP_DATABASE.
      MESSAGE 'An Error Occurred While Attempting to Write to DB.' TYPE 'E'.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
