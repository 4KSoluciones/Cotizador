*----------------------------------------------------------------------*
***INCLUDE ZCOTIZADOR_PBO.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_9000  OUTPUT
*&---------------------------------------------------------------------*
MODULE status_9000 OUTPUT.

  PERFORM f_user_habilitado_ver_pauta.

  SET PF-STATUS 'STATUS_9000'.
  SET TITLEBAR 'TIT_9000'.

  LOOP AT SCREEN.

    CASE screen-name.
      WHEN 'WA_SCREEN1-TXT_MEDIDA'   OR
           'WA_SCREEN1-USO'          OR
           'WA_SCREEN1-TXT_USO_INIC' OR
           'WA_SCREEN1-USO_INICIAL'  OR
*           'WA_SCREEN1-TXT_LUGAR'    OR
*           'WA_SCREEN1-LUGAR'        OR
           'TXT_COTIZAR'.
        IF v_active9000 = 'X' OR v_modifica_coti = 'X'.
          screen-active = 1.
        ELSE.
          screen-active = 0.
        ENDIF.

      WHEN 'WA_SCREEN1-TXT_CAJA'        OR
           'WA_SCREEN1-CAJA'            OR
           'WA_SCREEN1-TXT_DIFERENCIAL' OR
           'WA_SCREEN1-DIFERENCIAL'.

        IF v_active9000 = 'X' OR v_modifica_coti = 'X'.
          screen-active = 1.
        ELSE.
          screen-active = 0.
        ENDIF.

        IF wa_screen1-equipo NE c_camiones AND wa_screen1-equipo IS NOT INITIAL.
          IF v_active9000 = 'X'.
            screen-active = 0.
          ELSE.
            screen-active = 1.
          ENDIF.
        ENDIF.


      WHEN 'WA_SCREEN1-EQUIPO' OR
           'WA_SCREEN1-MARCA'  OR
           'WA_SCREEN1-MODELO' OR
           'WA_SCREEN1-MODALIDAD'.
        IF v_grisa9000 = 'X'.
          screen-input = 0.
        ELSE.
          screen-input = 1.
        ENDIF.

      WHEN 'BOTON_PAUTA'.

        IF sy-uname IN r_user.
          screen-active = 1.
        ELSE.
          screen-active = 0.
        ENDIF.

    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.



  LOOP AT SCREEN.
    CASE screen-name.
      WHEN 'BOTON_ATR_FIN'        OR
           'WA_SCREEN1-TXT_LUGAR' OR
           'WA_SCREEN1-LUGAR'.
        screen-active = 0.
        MODIFY SCREEN.
    ENDCASE.
  ENDLOOP.

  wa_screen1-lugar = 'TALLER'.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  TEXTOS_9000  OUTPUT
*&---------------------------------------------------------------------*
MODULE textos_9000 OUTPUT.

  IF wa_screen1-modalidad = 'KILÓMETROS' OR
     wa_screen1-modalidad = 'KILOMETROS'.
    wa_screen1-txt_medida   = 'KILÓMETROS ANUAL'.
    wa_screen1-txt_uso_inic = 'KILÓMETROS INICIALES'.
  ELSE.
    wa_screen1-txt_medida   = 'HORAS ANUAL'.
    wa_screen1-txt_uso_inic = 'HORAS INICIALES'.
  ENDIF.

  wa_screen1-txt_lugar       = 'LUGAR'.
  wa_screen1-txt_caja        = 'CAJA'.
  wa_screen1-txt_diferencial = 'DIFERENCIAL'.

  wa_screen1-chk_prepago = 'X'.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.

  SET PF-STATUS 'STATUS_0100'.
  SET TITLEBAR 'TIT_0100'.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  MOSTRAR_ALV  OUTPUT
*&---------------------------------------------------------------------*
MODULE mostrar_alv OUTPUT.

  " Mostrar ALV.
  PERFORM f_mostrar_alv CHANGING gt_cotizacion
                                 v_o_alvgrid
                                 v_o_contenedor_alv.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.

  SET PF-STATUS 'STATUS_0200'.
  SET TITLEBAR 'TIT_0200'.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  SETEA_ICONOS  OUTPUT
*&---------------------------------------------------------------------*
MODULE setea_iconos OUTPUT.

  DATA: icon_name(20) TYPE c,
        icon_text(10) TYPE c.


  icon_name = 'ICON_OKAY'.

  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
      name                  = icon_name
      text                  = icon_text
      info                  = 'Status'
      add_stdinf            = 'X'
    IMPORTING
      result                = v_icon_ok
    EXCEPTIONS
      icon_not_found        = 1
      outputfield_too_short = 2
      OTHERS                = 3.

  CLEAR: icon_name, icon_text.
  icon_name = 'ICON_CANCEL'.

  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
      name                  = icon_name
      text                  = icon_text
      info                  = 'Status'
      add_stdinf            = 'X'
    IMPORTING
      result                = v_icon_canc
    EXCEPTIONS
      icon_not_found        = 1
      outputfield_too_short = 2
      OTHERS                = 3.


  LOOP AT SCREEN.

    CASE screen-name.

      WHEN 'TXT_TRASLHS' OR 'V_HS_TERRENO'.

        IF wa_screen1-equipo = 'AGRICOLA'.
          screen-active = 0.
          CLEAR v_hs_terreno.
        ELSE.
          screen-active = 1.
        ENDIF.

        MODIFY SCREEN.

    ENDCASE.

  ENDLOOP.

* Este parametro debe estar siempre Activo
  v_rb_ajust = 'X'.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  STATUS_0300  OUTPUT
*&---------------------------------------------------------------------*
MODULE status_0300 OUTPUT.

  SET PF-STATUS 'STATUS_0300'.
  SET TITLEBAR 'TIT_0300'.

  CLEAR: v_cliente, v_fecha, v_nrocotiz, v_version.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  STATUS_0400  OUTPUT
*&---------------------------------------------------------------------*
MODULE status_0400 OUTPUT.

  SET PF-STATUS 'STATUS_0400'.
  SET TITLEBAR 'TIT_0400'.

*  IF wa_cotizacion-auart IS NOT INITIAL.
*    CASE wa_cotizacion-auart.
*      WHEN 'ZPPC'.
*        v_rb_cuota = 'X'.
*      WHEN 'ZPPE'.
*        v_rb_leasing = 'X'.
*      WHEN 'ZPP2'.
*        v_rb_prepago = 'X'.
*    ENDCASE.
*    v_vkbur    = wa_cotizacion-vkbur.
*    v_duracion = wa_cotizacion-duracion_elegida.
*    v_nrofact  = wa_cotizacion-factura.
*    v_vin      = wa_cotizacion-vin.
*  ELSE.
*    CLEAR: v_auart, v_vkbur, v_duracion, v_nrofact, v_vin.
*  ENDIF.

* PONEMOS POR DEFAULT pero lo pueden cambiar por pantalla
  v_rb_prepago = 'X'.
<<<<<<< HEAD
  v_auart      = 'ZPP3'." ZPP3
=======
  v_auart      = 'ZPP3'.
>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c
  v_vkorg      = '1000'.
  v_vtweg      = 'VS'.
  v_spart      = 'R0'.
  v_vkgrp      = 'STA'.
  v_parvw      = 'AG'.
  v_pstyv      = 'ZPP3'.
  v_kscha      = 'ZFLE'.
  v_duracion   = '12'.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  STATUS_0500  OUTPUT
*&---------------------------------------------------------------------*
MODULE status_0500 OUTPUT.

  SET PF-STATUS 'STATUS_0500'.
  SET TITLEBAR 'TIT_0500'.

  CLEAR: v_nrocotiz500, v_version500.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  STATUS_0600  OUTPUT
*&---------------------------------------------------------------------*
MODULE status_0600 OUTPUT.

  SET PF-STATUS 'STATUS_0600'.
  SET TITLEBAR 'TIT_0600'.

  v_oc_bukrs = '1000'.
  v_oc_esart = 'ZPP3'.
  v_oc_elifn = 'RSA0'.
  v_oc_ekorg = '1000'.
  v_oc_bkgrp = '107'.
  v_oc_waers = 'CLP'.
  v_oc_saknr = '0021110020'.
  v_oc_mwskz = 'C4'.

ENDMODULE.
