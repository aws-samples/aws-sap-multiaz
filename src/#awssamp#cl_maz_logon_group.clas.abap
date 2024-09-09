class /AWSSAMP/CL_MAZ_LOGON_GROUP definition
  public
  final
  create public .

public section.

  methods CONSTRUCTOR
    importing
      !I_GROUPTYPE type /AWSSAMP/DE_MAZ_LOGONTYPE
      !I_DBHOST type /AWSSAMP/DE_MAZ_HOSTNAME .
  methods LOAD_GROUP
    exporting
      !P_JOBSTATUS type ABAP_BOOL .
  methods DELETE_GROUP_SERVERS .
  methods ADD_GROUP_SERVERS .
protected section.
private section.

  data GV_GROUPTYPE type /AWSSAMP/DE_MAZ_LOGONTYPE .
  data GV_DBHOST type /AWSSAMP/DE_MAZ_HOSTNAME .
  data:
    gt_group TYPE TABLE OF /AWSSAMP/ST_MAZ_LOGON_INFO,
    gt_add_server TYPE TABLE OF /AWSSAMP/MAZ_CO.
ENDCLASS.



CLASS /AWSSAMP/CL_MAZ_LOGON_GROUP IMPLEMENTATION.


  METHOD: add_group_servers.
* 3. Add application servers in the group

    DATA: lt_modi TYPE TABLE OF RZLLIMODIF,
          ls_modi TYPE RZLLIMODIF,
          lt_modi_erfc TYPE TABLE OF RZLLIMODGP,
          ls_modi_erfc TYPE RZLLIMODGP,
          ls_group TYPE /AWSSAMP/ST_MAZ_LOGON_INFO,
          ls_add_server TYPE /AWSSAMP/MAZ_CO.

* 3.1 Create a modification to update application servers.

    LOOP AT gt_group INTO ls_group.
      ls_modi-CLASSNAME = ls_group-group_name.
      ls_modi-GROUPTYPE = ls_group-group_type.
      ls_modi-MODIFICATN = 'I'.

      ls_modi_erfc-CLASSNAME = ls_group-group_name.
      ls_modi_erfc-GROUPTYPE = ls_group-group_type.
      ls_modi_erfc-MODIFICATN = 'U'.
      INSERT ls_modi_erfc INTO TABLE lt_modi_erfc.

      LOOP AT gt_add_server INTO ls_add_server.
        IF ls_add_server-GROUPTYPE = ls_group-group_type and ls_add_server-GROUPNAME = ls_group-group_name.
           ls_modi-APPLSERVER = ls_add_server-APHOSTS.
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

    IF sy-subrc <> 0.
      WRITE: / 'Please verify Logon/RFC Group'.
    ENDIF.

  ENDMETHOD.


  METHOD: constructor.
    gv_grouptype = i_grouptype.
    gv_dbhost = i_dbhost.
  ENDMETHOD.


  METHOD: delete_group_servers.
* 2. Delete application servers in the group.

    DATA: lt_modi TYPE TABLE OF RZLLIMODIF,
          ls_modi TYPE RZLLIMODIF,
          lt_modi_erfc TYPE TABLE OF RZLLIMODGP,
          ls_modi_erfc TYPE RZLLIMODGP,
          ls_group TYPE /AWSSAMP/ST_MAZ_LOGON_INFO,
          lt_del_server TYPE TABLE OF RZLLIAPSRV,
          ls_del_server TYPE RZLLIAPSRV.

* 2.1 Create a modification to delete application servers.

    LOOP AT gt_group INTO ls_group.
      ls_modi-CLASSNAME = ls_group-group_name.
      ls_modi-GROUPTYPE = ls_group-group_type.
      ls_modi-MODIFICATN = 'D'.

      ls_modi_erfc-CLASSNAME = ls_group-group_name.
      ls_modi_erfc-GROUPTYPE = ls_group-group_type.
      ls_modi_erfc-MODIFICATN = 'U'.
      INSERT ls_modi_erfc INTO TABLE lt_modi_erfc.

      CALL FUNCTION 'SMLG_GET_DEFINED_SERVERS'
        EXPORTING
          GROUPTYPE = ls_group-group_type
          GROUPNAME = ls_group-group_name
        TABLES
          INSTANCES = lt_del_server
        EXCEPTIONS
          no_group_found = 1
          OTHERS         = 2.
        IF sy-subrc <> 0.
          WRITE: / 'Error occurred while retrieving logon group servers.'.
          EXIT.
        ENDIF.

      LOOP AT lt_del_server INTO ls_del_server.
        ls_modi-APPLSERVER = ls_del_server-applserver.
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

    IF sy-subrc <> 0.
      WRITE: / 'Please monitor the Server Group.'.
    ENDIF.

  ENDMETHOD.


  METHOD: load_group.
* 1. Execute a query to get groups information.

    DATA: ls_where(20),
          lt_where LIKE TABLE OF ls_where.

* 1.1 To get the group list.
    TRY.
      ls_where = |GROUPTYPE = '{ gv_grouptype }'|.
      APPEND  ls_where to lt_where.

      SELECT  DISTINCT GROUPNAME, GROUPTYPE INTO TABLE @gt_group FROM /AWSSAMP/MAZ_CO WHERE (lt_where).

* 1.2 To get the new application server list.
      CLEAR lt_where.

      ls_where = |GROUPTYPE = '{ gv_grouptype }'|.
      APPEND ls_where to lt_where.
      ls_where = 'AND'.
      APPEND ls_where to lt_where.
      ls_where = |DBHOST = '{ gv_dbhost }'|.
      APPEND  ls_where to lt_where.

      SELECT * INTO TABLE gt_add_server FROM /AWSSAMP/MAZ_CO WHERE (lt_where).

      IF sy-subrc EQ 0.
         p_jobstatus = abap_true.
      ELSE.
         WRITE: / 'Error occurred while retrieving the operation table(/AWSSAMP/MAZ_CO)'.
         p_jobstatus = abap_false.
ENDIF.

      CATCH CX_SY_DYNAMIC_OSQL_ERROR INTO DATA(err).
        MESSAGE err->get_text( ) TYPE 'E'.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
