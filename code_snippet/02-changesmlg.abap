DATA: BEGIN OF ls_group,
        group_name TYPE char20,
        group_type TYPE char1,
      END OF ls_group.
      
DATA: lt_group LIKE TABLE OF ls_group,
      lv_grouptype TYPE char1.

DATA: lt_modi TYPE TABLE OF RZLLIMODIF,
      ls_modi TYPE RZLLIMODIF,
      lt_del_server TYPE TABLE OF RZLLIAPSRV.

ls_modi-CLASSNAME = ls_group-group_name.
ls_modi-GROUPTYPE = ls_group-group_type.

* Function Modification Type
* I. insertion of an item
* D. deletion of an item
* U. update of an item
ls_modi-MODIFICATN = 'D'. 
ls_modi_erfc-CLASSNAME = ls_group-group_name.
ls_modi_erfc-GROUPTYPE = ls_group-group_type.
ls_modi_erfc-MODIFICATN = 'U'.
INSERT ls_modi_erfc INTO TABLE lt_modi_erfc.

* Get exisiting application servers in Logon/RFC server group
* Sever Group Type
* '' Logon Server Group
* 'S' RFC Server Group
CALL FUNCTION 'SMLG_GET_DEFINED_SERVERS'
  EXPORTING
    GROUPTYPE = ls_group-group_type
    GROUPNAME = ls_group-group_name
  TABLES
    INSTANCES = lt_del_server
  EXCEPTIONS
    no_group_found = 1
    OTHERS         = 2.
        
* Change application servers in Logon/RFC server group.
CALL FUNCTION 'SMLG_MODIFY'
  EXPORTING
    GROUPTYPE = lv_grouptype
  TABLES
    MODIFICATIONS = lt_modi
    ERFC_MODIFICATIONS = lt_modi_erfc
  EXCEPTIONS
    no_group_found = 1
    OTHERS         = 2.