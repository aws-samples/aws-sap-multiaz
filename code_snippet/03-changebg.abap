* /AWSSAMP/CL_MAZ_BP_GROUP Class Definition
CLASS /AWSSAMP/CL_MAZ_BP_GROUP DEFINITION INHERITING FROM CL_BP_SERVER_GROUP.
  PUBLIC SECTION.
    METHODS : LOAD_SRV_LIST IMPORTING p_groupname TYPE char20,
              GET_SRV_LIST EXPORTING p_list TYPE BPSRVENTRY,
              DEL_FROM_SRV_LIST IMPORTING p_srv TYPE BPSRVLINE,
              ADD_TO_SRV_LIST IMPORTING p_srv TYPE BPSRVLINE,
              SAVE_SRV_LIST_DB.
ENDCLASS

* /AWSSAMP/CL_MAZ_BP_GROUP Class Implementation
CLASS /AWSSAMP/CL_MAZ_BP_GROUP IMPLEMENTATION.
  * LOAD_SRV_LIST method to call LOAD_DB. To load a group information from DB.
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

  * GET_SRV_LIST method to call LOAD_DB. To get servers for a list.
  METHOD GET_SRV_LIST.
    CALL METHOD GET_LIST
      RECEIVING o_list = p_list.
  ENDMETHOD.

  * DEL_FROM_SRV_LIST method to call DEL_FROM_LIST. To delete a server in a list.
  METHOD DEL_FROM_SRV_LIST.
    CALL METHOD DEL_FROM_LIST
      EXPORTING I_SRV_ENTRY = p_srv.
  ENDMETHOD.

  * ADD_TO_SRV_LIST method to call ADD_TO_LIST. To add a server in a list.
  METHOD ADD_TO_SRV_LIST.
    CALL METHOD ADD_TO_LIST
      EXPORTING I_SRV_ENTRY = p_srv.
  ENDMETHOD.

  * SAVE_SRV_LIST_DB method to call SAVE_DB. To save a list in a DB.
  METHOD SAVE_SRV_LIST_DB.
    TRY.
      CALL METHOD SAVE_DB.
    CATCH CX_BP_DATABASE.
      MESSAGE 'An Error Occurred While Attempting to Write to DB.' TYPE 'E'.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.