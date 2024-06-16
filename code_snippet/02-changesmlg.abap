ls_modi-CLASSNAME = gs_group-group_name.
ls_modi-GROUPTYPE = gs_group-group_type.

* Function Modification Type
* I. insertion of an item
* D. deletion of an item
* U. update of an item
ls_modi-MODIFICATN = 'D'. 
ls_modi_erfc-CLASSNAME = gs_group-group_name.
ls_modi_erfc-GROUPTYPE = gs_group-group_type.
ls_modi_erfc-MODIFICATN = 'U'.
INSERT ls_modi_erfc INTO TABLE lt_modi_erfc.

* Get exisiting application servers in Logon/RFC server group
* Sever Group Type
* '' Logon Server Group
* 'S' RFC Server Group
CALL FUNCTION 'SMLG_GET_DEFINED_SERVERS'
  EXPORTING
    GROUPTYPE = gs_group-group_type
    GROUPNAME = gs_group-group_name
  TABLES
    INSTANCES = gt_del_server
  EXCEPTIONS
    no_group_found = 1
    OTHERS         = 2.
        
* Change application servers in Logon/RFC server group.
CALL FUNCTION 'SMLG_MODIFY'
  EXPORTING
    GROUPTYPE = gv_grouptype
  TABLES
    MODIFICATIONS = lt_modi
    ERFC_MODIFICATIONS = lt_modi_erfc
  EXCEPTIONS
    no_group_found = 1
    OTHERS         = 2.