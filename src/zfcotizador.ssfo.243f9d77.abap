
REFRESH lt_textos.

IF wa_cotizacion-ipc = 'X'.
  SELECT *
    FROM ztextos_fijos
    INTO TABLE lt_textos
   WHERE pos NE space.
ELSE.
  SELECT *
    FROM ztextos_fijos
    INTO TABLE lt_textos
   WHERE tipo NE 'IPC'.
ENDIF.

IF sy-subrc = 0.
*  SORT lt_textos.
ENDIF.




















