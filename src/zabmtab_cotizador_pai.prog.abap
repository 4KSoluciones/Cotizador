*&---------------------------------------------------------------------*
*&  Include           ZABMTAB_COTIZADOR_PAI
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CONSTANTS: lc_back     TYPE sy-ucomm  VALUE 'BACK',
             lc_cancel   TYPE sy-ucomm  VALUE 'CANCEL',
             lc_exit     TYPE sy-ucomm  VALUE 'EXIT'.

  CASE sy-ucomm.
    WHEN lc_back.
      LEAVE TO SCREEN 0.
    WHEN lc_exit.
      LEAVE TO SCREEN 0.
    WHEN lc_cancel.
      LEAVE TO SCREEN 0.
  ENDCASE.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  EXIT_COMMAND_9000  INPUT
*&---------------------------------------------------------------------*
MODULE exit_command_9000 INPUT.

  CASE sy-ucomm.
    WHEN lc_back.
      LEAVE TO SCREEN 0.
    WHEN lc_exit.
      LEAVE TO SCREEN 0.
    WHEN lc_cancel.
      LEAVE TO SCREEN 0.
  ENDCASE.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_9000  INPUT
*&---------------------------------------------------------------------*
MODULE user_command_9000 INPUT.

  IF v_ok_code EQ 'P_F8'.

**    Se valida que se seleccione solo un metodo de carga
    IF p_excel IS INITIAL AND p_manual IS INITIAL.
      MESSAGE i001(zfi) WITH TEXT-te4.

    ELSEIF NOT p_excel IS INITIAL AND
           NOT p_manual IS INITIAL.
      MESSAGE i001(zfi) WITH TEXT-te5.

    ELSEIF NOT p_excel IS INITIAL.
**    Solo si esta seleccionado metodo de carga ARCHIVO
      IF p_pauta IS NOT INITIAL.
        v_tabname = c_tab_pauta.
        v_estname = c_est_pauta.
      ELSEIF p_temp IS NOT INITIAL.
        v_tabname = c_tab_tempa.
        v_estname = c_est_tempa.
      ELSEIF p_param IS NOT INITIAL.
        v_tabname = c_tab_param.
        v_estname = c_est_param.
      ELSEIF p_textos IS NOT INITIAL.
        v_tabname = c_tab_textos.
        v_estname = c_est_textos.
      ENDIF.

      IF p_ruta IS INITIAL.

        MESSAGE s001(zfi)  WITH TEXT-te1 DISPLAY LIKE 'S'.

      ELSE.

        CREATE DATA gr_itab TYPE STANDARD TABLE OF (v_estname)
          WITH NON-UNIQUE DEFAULT KEY.

        PERFORM f_carga_de_archivo USING v_estname
                                         p_ruta
                                         v_error.

        PERFORM f_procesa_archivo USING v_tabname
                                  CHANGING it_fieldcat.
      ENDIF.

    ELSEIF NOT p_manual IS INITIAL.
**      Solo si esta seleccionado metodo de carga TABLA
      IF p_pauta IS NOT INITIAL.

        CALL TRANSACTION 'ZTPAUTA_SERV'.

      ELSEIF p_temp IS NOT INITIAL.

        CALL TRANSACTION 'ZTTEMPARIO_SERV'.

      ELSEIF p_param IS NOT INITIAL.

        CALL TRANSACTION 'ZTPARAM_COTSERV'.

      ELSEIF p_textos IS NOT INITIAL.

        CALL TRANSACTION 'ZTTEXTOS_SERV'.

      ENDIF.

    ENDIF.

    CLEAR:  v_ok_code.

  ENDIF.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  F4_RUTA  INPUT
*&---------------------------------------------------------------------*
MODULE f4_ruta INPUT.

  PERFORM f_ruta_de_archivo CHANGING p_ruta
                                     v_error.

  PERFORM f_check_selection_screen USING    p_ruta
                                   CHANGING v_error.

ENDMODULE.
