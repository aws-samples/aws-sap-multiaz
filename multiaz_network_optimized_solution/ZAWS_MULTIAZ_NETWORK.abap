*&---------------------------------------------------------------------*
*& Report ZAWS_MULTIAZ_NETWORK
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZAWS_MULTIAZ_NETWORK.

* Please change your sdk profile and sns topic arn.
DATA: gv_sdkprofile TYPE /AWS1/RT_PROFILE_ID,
      gv_snsarn TYPE string.

gv_sdkprofile = '<change your SDK profile>'.
gv_snsarn = '<change your sns topic arn>'.

* CLASS - LOGON GROUP Update/Delete/Modify

CLASS ZCL_LOGON_GROUP DEFINITION.
  PUBLIC SECTION.

    METHODS: constructor IMPORTING i_grouptype TYPE char1
                                   i_dbhost TYPE char20.

    METHODS: load_group,
             delete_group_servers,
             add_group_servers.

  PRIVATE SECTION.
    DATA: gv_grouptype TYPE char1,
          gv_dbhost TYPE char20.

    DATA: BEGIN OF gs_group,
            group_name TYPE char20,
            group_type TYPE char1,
          END OF gs_group.
    DATA  gt_group LIKE TABLE OF gs_group.

    DATA: gt_del_server TYPE TABLE OF RZLLIAPSRV,
          gs_del_server TYPE RZLLIAPSRV,
          gt_add_server TYPE TABLE OF ZTAWSMULTIAZ,
          gs_add_server TYPE ZTAWSMULTIAZ.

    DATA: ls_where(20),
          lt_where LIKE TABLE OF ls_where.

ENDCLASS.

CLASS ZCL_LOGON_GROUP IMPLEMENTATION.

  METHOD: constructor.
    gv_grouptype = i_grouptype.
    gv_dbhost = i_dbhost.
  ENDMETHOD.

* 1. Execute a query to get groups information.

  METHOD: load_group.
    DATA: ls_where(20),
          lt_where LIKE TABLE OF ls_where.

* 1.1 To get the group list.
    TRY.
      ls_where = |GROUPTYPE = '{ gv_grouptype }'|.
      APPEND  ls_where to lt_where.

      SELECT  DISTINCT GROUPNAME, GROUPTYPE INTO TABLE @gt_group FROM ZTAWSMULTIAZ WHERE (lt_where).

* 1.2 To get the new application server list.
      CLEAR lt_where.

      ls_where = |GROUPTYPE = '{ gv_grouptype }'|.
      APPEND ls_where to lt_where.
      ls_where = 'AND'.
      APPEND ls_where to lt_where.
      ls_where = |DBHOST = '{ gv_dbhost }'|.
      APPEND  ls_where to lt_where.

      SELECT * INTO TABLE gt_add_server FROM ZTAWSMULTIAZ WHERE (lt_where).

      CATCH CX_SY_DYNAMIC_OSQL_ERROR INTO DATA(err).
        MESSAGE err->get_text( ) TYPE 'E'.
    ENDTRY.
  ENDMETHOD.

* 2. Delete application servers in the group.

  METHOD: delete_group_servers.
    DATA: lt_modi TYPE TABLE OF RZLLIMODIF,
          ls_modi TYPE RZLLIMODIF,
          lt_modi_erfc TYPE TABLE OF RZLLIMODGP,
          ls_modi_erfc TYPE RZLLIMODGP.

* 2.1 Create a modification to delete application servers.

    LOOP AT gt_group INTO gs_group.
      ls_modi-CLASSNAME = gs_group-group_name.
      ls_modi-GROUPTYPE = gs_group-group_type.
      ls_modi-MODIFICATN = 'D'.

      ls_modi_erfc-CLASSNAME = gs_group-group_name.
      ls_modi_erfc-GROUPTYPE = gs_group-group_type.
      ls_modi_erfc-MODIFICATN = 'U'.
      INSERT ls_modi_erfc INTO TABLE lt_modi_erfc.

      CALL FUNCTION 'SMLG_GET_DEFINED_SERVERS'
        EXPORTING
          GROUPTYPE = gs_group-group_type
          GROUPNAME = gs_group-group_name
        TABLES
          INSTANCES = gt_del_server
        EXCEPTIONS
          no_group_found = 1
          OTHERS         = 2.
        IF sy-subrc <> 0.
          WRITE: / 'Error occurred while retrieving logon group servers.'.
          EXIT.
        ENDIF.

      LOOP AT gt_del_server INTO gs_del_server.
        ls_modi-APPLSERVER = gs_del_server-applserver.
        INSERT ls_modi INTO TABLE lt_modi.
      ENDLOOP.

    ENDLOOP.

* 2.2 Execute the SMLG_MODIFY Fuction.

    CALL FUNCTION 'SMLG_MODIFY'
      EXPORTING
        GROUPTYPE = gv_grouptype
      TABLES
        MODIFICATIONS = lt_modi
        ERFC_MODIFICATIONS = lt_modi_erfc
      EXCEPTIONS
        no_group_found = 1
        OTHERS         = 2.

    IF sy-subrc = 0.
      WRITE: / 'Server Delete Successful'.
    ELSE.
      WRITE: / sy-subrc.
    ENDIF.

  ENDMETHOD.

* 3. Add application servers in the group

  METHOD: add_group_servers.
    DATA: lt_modi TYPE TABLE OF RZLLIMODIF,
          ls_modi TYPE RZLLIMODIF,
          lt_modi_erfc TYPE TABLE OF RZLLIMODGP,
          ls_modi_erfc TYPE RZLLIMODGP.

* 3.1 Create a modification to update application servers.

    LOOP AT gt_group INTO gs_group.
      ls_modi-CLASSNAME = gs_group-group_name.
      ls_modi-GROUPTYPE = gs_group-group_type.
      ls_modi-MODIFICATN = 'I'.

      ls_modi_erfc-CLASSNAME = gs_group-group_name.
      ls_modi_erfc-GROUPTYPE = gs_group-group_type.
      ls_modi_erfc-MODIFICATN = 'U'.
      INSERT ls_modi_erfc INTO TABLE lt_modi_erfc.

      LOOP AT gt_add_server INTO gs_add_server.
        IF gs_add_server-GROUPTYPE = gs_group-group_type and gs_add_server-GROUPNAME = gs_group-group_name.
           ls_modi-APPLSERVER = gs_add_server-APHOSTS.
           INSERT ls_modi INTO TABLE lt_modi.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    CALL FUNCTION 'SMLG_MODIFY'
      EXPORTING
        GROUPTYPE = gv_grouptype
      TABLES
        MODIFICATIONS = lt_modi
        ERFC_MODIFICATIONS = lt_modi_erfc
      EXCEPTIONS
        no_group_found = 1
        OTHERS         = 2.

    IF sy-subrc = 0.
      WRITE: / 'Server Add Successful'.
    ELSE.
      WRITE: / sy-subrc.
    ENDIF.

  ENDMETHOD.

ENDCLASS.

* CLASS - Background Process(Batch) GROUP Update/Delete/Modify

CLASS ZCL_BP_SERVER_GROUP DEFINITION INHERITING FROM CL_BP_SERVER_GROUP.
  PUBLIC SECTION.
    METHODS : LOAD_SRV_LIST IMPORTING p_groupname TYPE char20,
              GET_SRV_LIST EXPORTING p_list TYPE BPSRVENTRY,
              DEL_FROM_SRV_LIST IMPORTING p_srv TYPE BPSRVLINE,
              ADD_TO_SRV_LIST IMPORTING p_srv TYPE BPSRVLINE,
              SAVE_SRV_LIST_DB.
ENDCLASS.

CLASS ZCL_BP_SERVER_GROUP IMPLEMENTATION.
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

  METHOD GET_SRV_LIST.
    CALL METHOD GET_LIST
      RECEIVING o_list = p_list.
  ENDMETHOD.

  METHOD DEL_FROM_SRV_LIST.
    CALL METHOD DEL_FROM_LIST
      EXPORTING I_SRV_ENTRY = p_srv.
  ENDMETHOD.

  METHOD ADD_TO_SRV_LIST.
    CALL METHOD ADD_TO_LIST
      EXPORTING I_SRV_ENTRY = p_srv.
  ENDMETHOD.

  METHOD SAVE_SRV_LIST_DB.
    TRY.
      CALL METHOD SAVE_DB.
    CATCH CX_BP_DATABASE.
      MESSAGE 'An Error Occurred While Attempting to Write to DB.' TYPE 'E'.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

* CLASS - Send alert messages using AWS SDK for SAP ABAP with Amazon SNS.

CLASS ZCL_SDK_SNS DEFINITION.
  PUBLIC SECTION.
    METHODS: constructor IMPORTING i_profile TYPE /AWS1/RT_PROFILE_ID
                                   i_snsarn TYPE string.

    METHODS: send_message IMPORTING p_text TYPE string.
  PRIVATE SECTION.
   DATA: gv_profile TYPE /AWS1/RT_PROFILE_ID,
         gv_snsarn TYPE string.

ENDCLASS.

CLASS ZCL_SDK_SNS IMPLEMENTATION.
  METHOD: constructor.
    gv_profile = i_profile.
    gv_snsarn = i_snsarn.
  ENDMETHOD.

  METHOD: SEND_MESSAGE.
     TRY.
        "Create a ABAP SDK session for SNS"
        DATA(lo_session) = /aws1/cl_rt_session_aws=>create( gv_profile ).
        DATA(lo_sns) = /aws1/cl_sns_factory=>create( lo_session ).

        "publish a message to SNS topic"
        DATA(lo_result) = lo_sns->publish(
          iv_topicarn = gv_snsarn
          iv_message = p_text

        ).
        WRITE:/ 'Message published to SNS topic.'.

     CATCH /aws1/cx_snsnotfoundexception.
        WRITE:/ 'Topic does not exist.'.
     CATCH /aws1/cx_rt_service_generic.
        WRITE:/ 'Generic Service call error'.
     CATCH /aws1/cx_rt_no_auth_generic.
        WRITE:/ 'Generic lack of authorization'.
     CATCH /aws1/cx_rt_technical_generic.
        WRITE:/ 'Technical errors'.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.

* CLASS - Get a hostname of the Active HANA Database Server using ABAP ADBC.

CLASS ZCL_GET_DBHOST DEFINITION.

  PUBLIC SECTION.
    METHODS: constructor,
             get_hostname EXPORTING p_hostname TYPE char20.

  PRIVATE SECTION.
    DATA:  gv_hostname TYPE char20.

ENDCLASS.

CLASS ZCL_GET_DBHOST IMPLEMENTATION.

  METHOD constructor.
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

  METHOD get_hostname.
      p_hostname = gv_hostname.
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.


*  1.Compare a current actvie db host with a previous active db hosts

WRITE:/ '1.Checking the status of an active db'.
WRITE:/ '-------------------------------------------------'.

DATA: lt_dbhost TYPE TABLE OF ZTAWSMULTIDB,
      ls_dbhost TYPE ZTAWSMULTIDB,
      ls_current_dbhost TYPE ZTAWSMULTIDB,
      lo_get_dbhost TYPE REF TO ZCL_GET_DBHOST,
      lv_hostname TYPE char20,
      lo_sns TYPE REF TO ZCL_SDK_SNS.


CREATE OBJECT lo_get_dbhost.

CALL METHOD: lo_get_dbhost->get_hostname
             IMPORTING p_hostname = lv_hostname.

CREATE OBJECT lo_sns
  EXPORTING
    i_profile = gv_sdkprofile
    i_snsarn = gv_snsarn.


SELECT * INTO TABLE lt_dbhost FROM ZTAWSMULTIDB.

LOOP AT lt_dbhost INTO ls_dbhost.
  IF lv_hostname NE ls_dbhost-dbhost.
    CALL METHOD lo_sns->SEND_MESSAGE
       EXPORTING p_text = |HANA DB server takeover to { lv_hostname }|.

    ls_current_dbhost-mandt = '000'.
    ls_current_dbhost-dbhost = lv_hostname.
    UPDATE ZTAWSMULTIDB FROM ls_current_dbhost.

    WRITE:/ 'Need to chage application servers in the group.'.
  ELSE.
    WRITE:/ 'S/4HANA system is operating normally.'.
    RETURN.
  ENDIF.
ENDLOOP.

* 2. Change Logon Group

WRITE: / '-------------------------------------------------'.
WRITE:/ '2.Change Logon Group'.
WRITE: / '-------------------------------------------------'.

DATA:  lo_logon_group TYPE REF TO ZCL_LOGON_GROUP.
CREATE OBJECT lo_logon_group
  EXPORTING
    i_grouptype = ''
    i_dbhost = lv_hostname.

* 2.1 Get groups information.

CALL METHOD lo_logon_group->load_group.

* 2.2 Delete application servers in the group.

CALL METHOD lo_logon_group->delete_group_servers.

* 2.3 Add application servers in the group.

CALL METHOD lo_logon_group->add_group_servers.

* 3. Change RFC  Group

WRITE:/ '-------------------------------------------------'.
WRITE:/ '3.Change RFC  Group'.
WRITE:/ '-------------------------------------------------'.

DATA:  lo_rfc_group TYPE REF TO ZCL_LOGON_GROUP.
CREATE OBJECT lo_rfc_group
  EXPORTING
    i_grouptype = 'S'
    i_dbhost = lv_hostname.

* 3.1 Get groups information.

CALL METHOD lo_rfc_group->load_group.

* 3.2 Delete application servers in the group.

CALL METHOD lo_rfc_group->delete_group_servers.

* 3.3 Add application servers in the group.

CALL METHOD lo_rfc_group->add_group_servers.

* 4. Change Background Group

WRITE:/ '-------------------------------------------------'.
WRITE:/ '4.Change Background Group'.
WRITE:/ '-------------------------------------------------'.


* 4.1 Execute a query to get groups information.

DATA: BEGIN OF ls_group,
        group_name TYPE char20,
        group_type TYPE char1,
      END OF ls_group.
DATA lt_group LIKE TABLE OF ls_group.

DATA: ls_where(20),
      lt_where LIKE TABLE OF ls_where.

DATA: lv_grouptype TYPE char1,
      lt_add_server TYPE TABLE OF ZTAWSMULTIAZ,
      ls_add_server TYPE ZTAWSMULTIAZ.

TRY.

  SELECT  DISTINCT GROUPNAME, GROUPTYPE INTO TABLE @lt_group FROM ZTAWSMULTIAZ WHERE GROUPTYPE = 'B'.

  lv_grouptype = 'B'.
  ls_where = |GROUPTYPE = '{ lv_grouptype }'|.
  APPEND ls_where to lt_where.
  ls_where = 'AND'.
  APPEND ls_where to lt_where.
  ls_where = |DBHOST = '{ lv_hostname }'|.
  APPEND  ls_where to lt_where.

  SELECT * INTO TABLE lt_add_server FROM ZTAWSMULTIAZ WHERE (lt_where).

  CATCH CX_SY_DYNAMIC_OSQL_ERROR INTO DATA(err).
    MESSAGE err->get_text( ) TYPE 'E'.

ENDTRY.

* 4.2 Change the application server lists in groups.

DATA:  lo_bp_server_group TYPE REF TO ZCL_BP_SERVER_GROUP,
       lt_bp_srv_list TYPE TABLE OF BPSRVLINE,
       ls_bp_srv TYPE BPSRVLINE,
       ls_add_srv_list TYPE BPSRVLINE,
       lv_groupname TYPE BPSRVGRP.

LOOP AT lt_group INTO ls_group.

  CREATE OBJECT lo_bp_server_group.

  WRITE:/ ls_group-group_name, 'Change Application Servers'.

  CALL METHOD lo_bp_server_group->LOAD_SRV_LIST
              EXPORTING p_groupname = ls_group-group_name.

  CALL METHOD lo_bp_server_group->GET_SRV_LIST
              IMPORTING p_list = lt_bp_srv_list.

  LOOP AT lt_bp_srv_list INTO ls_bp_srv.
    CALL METHOD lo_bp_server_group->DEL_FROM_SRV_LIST
                EXPORTING p_srv = ls_bp_srv.
  ENDLOOP.

  LOOP AT lt_add_server INTO ls_add_server.
    IF ls_add_server-GROUPTYPE = ls_group-group_type and ls_add_server-GROUPNAME = ls_group-group_name.
      ls_add_srv_list-appsrvname = ls_add_server-APHOSTS.
      CALL METHOD lo_bp_server_group->ADD_TO_SRV_LIST
                  EXPORTING p_srv = ls_add_srv_list.
    ENDIF.
  ENDLOOP.

  CALL METHOD lo_bp_server_group->SAVE_SRV_LIST_DB.

ENDLOOP.

CALL METHOD lo_sns->SEND_MESSAGE
   EXPORTING p_text = 'Successfully changed Logon/RFC/Batchjob Group'.

WRITE: / '-------------------------------------------------'.
WRITE:/ 'Program End'.