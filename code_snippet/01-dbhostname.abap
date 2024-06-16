* Get a hostname of the Active HANA Database Server.
EXEC SQL.
  SELECT HOST
    INTO  :lv_hostname
    FROM SYS.M_DATABASE
ENDEXEC.

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