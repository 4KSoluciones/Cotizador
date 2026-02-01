*----------------------------------------------------------------------*
***INCLUDE ZCOTIZADOR_PBO.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_9000  OUTPUT
*&---------------------------------------------------------------------*
MODULE status_9000 OUTPUT.

*  PERFORM f_user_habilitado_ver_pauta.

  SET PF-STATUS 'STATUS_9000'.
  SET TITLEBAR 'TIT_9000'.

  DATA: lv_vkgrp TYPE a544-vkgrp,
        lv_datbi TYPE a544-datbi VALUE '99991231'.
*  CONCATENATE 'S' wa_screen1-lugar(2) INTO lv_vkgrp.

  SELECT datab, eqart, matnr
    FROM a544
    INTO TABLE @DATA(lt_a544) "wa_a544
   WHERE kappl = 'V'
     AND kschl = 'ZPSV'
     AND vkbur = @wa_screen1-sucursal
     AND ( vkgrp = 'STA' OR vkgrp = 'STE' )"lv_vkgrp
     AND eqart = @wa_screen1-equipo
     AND datbi = @lv_datbi
     AND ( matnr = 'CS03' OR "Maquinaria Construccion
           matnr = 'CS19' OR "Maquinaria Construccion
           matnr = 'CS35' OR "Camion
           matnr = 'CS84' ). "Agricola
  IF sy-subrc = 0.
    SORT lt_a544 BY datab DESCENDING.
    READ TABLE lt_a544 INTO DATA(lw_a544) INDEX 1.
    IF sy-subrc = 0.
      MOVE-CORRESPONDING lw_a544 TO wa_a544.
    ENDIF.
  ENDIF.

  LOOP AT SCREEN.

    CASE screen-name.
      WHEN 'WA_SCREEN1-TXT_MEDIDA'   OR
           'WA_SCREEN1-USO'          OR
           'WA_SCREEN1-TXT_USO_INIC' OR
           'WA_SCREEN1-USO_INICIAL'  OR
           'WA_SCREEN1-TXT_LUGAR'    OR
           'WA_SCREEN1-LUGAR'        OR
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

        IF wa_a544-matnr EQ 'CS03' OR   "wa_screen1-equipo EQ c_maquinaria OR
           wa_a544-matnr EQ 'CS19' OR   "wa_screen1-equipo EQ c_maquinaria OR
           wa_a544-matnr EQ 'CS84'.     "wa_screen1-equipo EQ c_agricola.
          IF v_active9000 = 'X'.
            screen-active = 0.
          ELSE.
            screen-active = 1.
          ENDIF.
        ENDIF.


      WHEN 'WA_SCREEN1-EQUIPO'     OR
           'WA_SCREEN1-EQUIPO_TXT' OR
           'WA_SCREEN1-MARCA'      OR
           'WA_SCREEN1-MODELO'     OR
           'WA_SCREEN1-MODALIDAD'.
        IF v_grisa9000 = 'X'.
          screen-input = 0.
        ELSE.
          screen-input = 1.
        ENDIF.

      WHEN 'BOTON_PAUTA'.

*        IF sy-uname IN r_user.
*          screen-active = 1.
*        ELSE.
        screen-active = 0.
        screen-invisible = 1.
*        ENDIF.

    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  TEXTOS_9000  OUTPUT
*&---------------------------------------------------------------------*
MODULE textos_9000 OUTPUT.

  IF wa_screen1-modalidad(3) = 'KIL'.
    wa_screen1-txt_medida   = 'KILÓMETROS ANUAL'.
    wa_screen1-txt_uso_inic = 'KILÓMETROS INICIALES'.
  ELSE.
    wa_screen1-txt_medida   = 'HORAS ANUAL'.
    wa_screen1-txt_uso_inic = 'HORAS INICIALES'.
  ENDIF.

  SELECT SINGLE descripcion
    FROM zatributo1
    INTO @DATA(lv_atributo1).

  wa_screen1-txt_lugar       = 'LUGAR'.
  wa_screen1-txt_caja        = 'CAJA'.
  wa_screen1-txt_diferencial = 'DIFERENCIAL'.
  wa_screen1-chk_prepago     = 'X'.

  REFRESH gt_sucu.
  SELECT vkbur bezei
    FROM tvkbt
    INTO TABLE gt_sucu
   WHERE spras = 'S'.
  IF sy-subrc = 0.
    SORT gt_sucu BY vkbur ASCENDING.
  ENDIF.

  REFRESH gt_equipo.
  SELECT eqart eartx
    FROM t370k_t
    INTO TABLE gt_equipo
   WHERE spras = 'S'.
  IF sy-subrc = 0.
    SORT gt_equipo BY eqart ASCENDING.
  ENDIF.


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
  BREAK-POINT.
*  PERFORM f_mostrar_alv CHANGING gt_cotizacion
*                                 v_o_alvgrid
*                                 v_o_contenedor_alv.

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

        IF wa_a544-matnr = 'CS84' . "wa_screen1-equipo = 'AGRICOLA'.
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

  IF wa_cotizacion-auart IS NOT INITIAL.
    CASE wa_cotizacion-auart.
      WHEN 'ZPPC'.
        v_rb_cuota = 'X'.
      WHEN 'ZPPE'.
        v_rb_leasing = 'X'.
      WHEN 'ZPP2'.
        v_rb_prepago = 'X'.
    ENDCASE.
    v_vkbur    = wa_cotizacion-vkbur.
    v_duracion = wa_cotizacion-duracion_elegida.
    v_nrofact  = wa_cotizacion-factura.
    v_vin      = wa_cotizacion-vin.
  ELSE.
    CLEAR: v_auart, v_vkbur, v_duracion, v_nrofact, v_vin.
  ENDIF.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  STATUS_0500  OUTPUT
*&---------------------------------------------------------------------*
MODULE status_0500 OUTPUT.

  SET PF-STATUS 'STATUS_0500'.
  SET TITLEBAR 'TIT_0500'.

  CLEAR: v_nrocotiz, v_version, v_werksoc.

ENDMODULE.
