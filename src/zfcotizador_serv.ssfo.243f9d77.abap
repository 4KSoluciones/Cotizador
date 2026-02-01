
REFRESH lt_textos.

IF wa_cotizacion-ipc = 'X'.
  SELECT *
    FROM zttextos_serv
    INTO TABLE lt_textos
   WHERE pos NE space.
ELSE.
  SELECT *
    FROM zttextos_serv
    INTO TABLE lt_textos
   WHERE tipo NE 'IPC'.
ENDIF.

IF sy-subrc = 0.
  DESCRIBE TABLE lt_textos LINES v_cant_considera.
ENDIF.

















