*&---------------------------------------------------------------------*
*&  Include           ZABMTAB_COTIZADOR_PBO
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.
  SET TITLEBAR 'TIT_100' WITH v_tabname.
ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  MOSTRAR_ALV  OUTPUT
*&---------------------------------------------------------------------*
MODULE mostrar_alv OUTPUT.

  PERFORM f_mostrar_alv CHANGING vo_alvgrid
                               vo_contenedor_alv.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
  SET PF-STATUS 'STATUS_0200'.
  SET TITLEBAR 'TIT_200'.
ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  STATUS_9000  OUTPUT
*&---------------------------------------------------------------------*
MODULE status_9000 OUTPUT.

  SET PF-STATUS 'STATUS_9000'.
  SET TITLEBAR 'TIT_9000'.

  LOOP AT SCREEN.
    CASE screen-name.
      WHEN 'P_RUTA'.
        IF p_excel = 'X'.
          screen-active = 0.
        ELSE.
          screen-active = 1.
        ENDIF.
    ENDCASE.
    MODIFY SCREEN.
  ENDLOOP.

ENDMODULE.
