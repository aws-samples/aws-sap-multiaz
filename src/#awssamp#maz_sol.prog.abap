*&---------------------------------------------------------------------*
*& Report /AWSSAMP/MAZ_SOL
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT /AWSSAMP/MAZ_SOL.

* Please change your sdk profile and sns topic arn.

DATA: gv_sdkprofile TYPE /AWS1/RT_PROFILE_ID,
      gv_snsarn TYPE string.

gv_sdkprofile = '<change your SDK profile>'.
gv_snsarn = '<change your sns topic arn>'.

* Using gv_job_status to continue or skip steps due to job status.

DATA: lv_job_status TYPE abap_bool.
      lv_job_status = abap_true.

*  1.Compare a current actvie db host with a previous active db hosts

WRITE:/ '1.Checking the status of an active db'.
WRITE:/ '-------------------------------------------------'.

DATA: lt_dbhost TYPE TABLE OF /AWSSAMP/MAZ_DB,
      ls_dbhost TYPE /AWSSAMP/MAZ_DB,
      ls_current_dbhost TYPE /AWSSAMP/MAZ_DB,
      lo_get_dbhost TYPE REF TO /AWSSAMP/CL_MAZ_GET_DBHOST,
      lv_hostname TYPE char20,
      lo_sns TYPE REF TO /AWSSAMP/CL_MAZ_SDK_SNS.

CREATE OBJECT lo_get_dbhost.

CALL METHOD: lo_get_dbhost->get_hostname
             IMPORTING p_hostname = lv_hostname.

CREATE OBJECT lo_sns
  EXPORTING
    i_profile = gv_sdkprofile
    i_snsarn = gv_snsarn.


SELECT * INTO TABLE lt_dbhost FROM /AWSSAMP/MAZ_DB.

LOOP AT lt_dbhost INTO ls_dbhost.
  IF lv_hostname NE ls_dbhost-dbhost.
    CALL METHOD lo_sns->SEND_MESSAGE
       EXPORTING i_text = |HANA DB server takeover to { lv_hostname }|.

    ls_current_dbhost-mandt = '000'.
    ls_current_dbhost-dbhost = lv_hostname.
    UPDATE /AWSSAMP/MAZ_DB FROM ls_current_dbhost.

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

DATA:  lo_logon_group TYPE REF TO /AWSSAMP/CL_MAZ_LOGON_GROUP.
CREATE OBJECT lo_logon_group
  EXPORTING
    i_grouptype = ''
    i_dbhost = lv_hostname.

* 2.1 Get groups information.

CALL METHOD lo_logon_group->load_group IMPORTING p_jobstatus = lv_job_status.

* Checking status - retrieve operation table
IF lv_job_status = abap_true.

* 2.2 Delete application servers in the group.
  CALL METHOD lo_logon_group->delete_group_servers.
* 2.3 Add application servers in the group.
  CALL METHOD lo_logon_group->add_group_servers.

ELSE.
  CALL METHOD lo_sns->SEND_MESSAGE
      EXPORTING i_text = 'Please check the opearion table(/AWSSAMP/MAZ_CO)'.

ENDIF.

* 3. Change RFC  Group

WRITE:/ '-------------------------------------------------'.
WRITE:/ '3.Change RFC  Group'.
WRITE:/ '-------------------------------------------------'.

DATA:  lo_rfc_group TYPE REF TO /AWSSAMP/CL_MAZ_LOGON_GROUP.
CREATE OBJECT lo_rfc_group
  EXPORTING
    i_grouptype = 'S'
    i_dbhost = lv_hostname.

* 3.1 Get groups information.

CALL METHOD lo_rfc_group->load_group IMPORTING p_jobstatus = lv_job_status.

* Checking status - retrieve operation table
IF lv_job_status = abap_true.

* 3.2 Delete application servers in the group.
  CALL METHOD lo_rfc_group->delete_group_servers.
* 3.3 Add application servers in the group.
  CALL METHOD lo_rfc_group->add_group_servers.

ELSE.
  CALL METHOD lo_sns->SEND_MESSAGE
      EXPORTING i_text = 'Please check the opearion table(/AWSSAMP/MAZ_CO)'.

ENDIF.

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
      lt_add_server TYPE TABLE OF /AWSSAMP/MAZ_CO,
      ls_add_server TYPE /AWSSAMP/MAZ_CO.

TRY.

  SELECT  DISTINCT GROUPNAME, GROUPTYPE INTO TABLE @lt_group FROM /AWSSAMP/MAZ_CO WHERE GROUPTYPE = 'B'.

  lv_grouptype = 'B'.
  ls_where = |GROUPTYPE = '{ lv_grouptype }'|.
  APPEND ls_where to lt_where.
  ls_where = 'AND'.
  APPEND ls_where to lt_where.
  ls_where = |DBHOST = '{ lv_hostname }'|.
  APPEND  ls_where to lt_where.

  SELECT * INTO TABLE lt_add_server FROM /AWSSAMP/MAZ_CO WHERE (lt_where).

  IF sy-subrc EQ 0.
     lv_job_status = abap_true.
  ELSE.
     WRITE: / 'Error occurred while retrieving the operation table(/AWSSAMP/MAZ_CO)'.
     lv_job_status = abap_false.
  ENDIF.

  CATCH CX_SY_DYNAMIC_OSQL_ERROR INTO DATA(err).
    MESSAGE err->get_text( ) TYPE 'E'.

ENDTRY.

* 4.2 Change the application server lists in groups.

DATA:  lo_bp_server_group TYPE REF TO /AWSSAMP/CL_MAZ_BP_GROUP,
       lt_bp_srv_list TYPE TABLE OF BPSRVLINE,
       ls_bp_srv TYPE BPSRVLINE,
       ls_add_srv_list TYPE BPSRVLINE,
       lv_groupname TYPE BPSRVGRP.


* Checking status - retrieve operation table
IF lv_job_status = abap_true.

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

ELSE.
  CALL METHOD lo_sns->SEND_MESSAGE
      EXPORTING i_text = 'Please check the opearion table(/AWSSAMP/MAZ_CO)'.

ENDIF.

WRITE: / '-------------------------------------------------'.

CALL METHOD lo_sns->SEND_MESSAGE
  EXPORTING i_text = 'Finished Automate and Optimise SAP Network Performance in a Multi-AZ deployment Solution'.

WRITE:/ 'Program End'.
