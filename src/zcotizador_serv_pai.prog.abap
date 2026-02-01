*----------------------------------------------------------------------*
***INCLUDE ZCOTIZADOR_PAI.
*----------------------------------------------------------------------*


*&---------------------------------------------------------------------*
*&      Module  EXIT_COMMAND_9000  INPUT
*&---------------------------------------------------------------------*
MODULE exit_command_9000 INPUT.

  CASE sy-ucomm.
    WHEN 'EXIT' OR 'BACK'.
      LEAVE PROGRAM.
  ENDCASE.

ENDMODULE.      "EXIT_COMMAND_9000


*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_9000  INPUT
*&---------------------------------------------------------------------*
MODULE user_command_9000 INPUT.

  v_saveok9000 = v_ok_code_9000.
  CLEAR: v_ok_code_9000, v_active9000.

  CASE v_saveok9000.
    WHEN 'BACK'.
      LEAVE SCREEN.

    WHEN 'EXIT'.
      LEAVE PROGRAM.

    WHEN 'CF_ATR1'.
      v_active9000 = 'X'.
      v_grisa9000  = 'X'.
      READ TABLE gt_sucu INTO DATA(lw_sucu)
        WITH KEY vkbur = wa_screen1-sucursal.
      IF sy-subrc = 0.
        wa_screen1-sucu_txt = lw_sucu-bezei.
      ENDIF.

      READ TABLE gt_equipo INTO DATA(lw_equipo)
        WITH KEY eqart = wa_screen1-equipo.
      IF sy-subrc = 0.
        wa_screen1-equipo_txt = lw_equipo-eartx.
      ENDIF.

    WHEN 'CF_LIMP'.
      CLEAR: v_grisa9000, v_active9000.
      REFRESH gt_pauta_serv.
      CLEAR wa_screen1.
**    WHEN 'CF_PVIEJA'.
**      PERFORM f_cargar_pauta_vieja.
    WHEN 'CF_COTIV'.
      CALL SCREEN 0300 STARTING AT 10 3.

    WHEN 'CF_OC'.
      CALL SCREEN 0500 STARTING AT 10 3.
**    WHEN 'CF_PAUTA'.
**      PERFORM f_pauta_variables_importes.
**      PERFORM f_carga_fieldcat.
**      PERFORM f_grisa_campos_alv.
**      PERFORM f_llama_alv.

    WHEN 'CF_COT'.
      PERFORM f_valida_inicio.

      IF v_valida_inicio IS INITIAL.
        CLEAR gt_pauta_serv.
        PERFORM f_pauta_variables_importes.
        PERFORM f_obtener_formula.
        PERFORM f_imprimir_formulario.
        PERFORM f_graba_cotizacion.
      ENDIF.

    WHEN 'CF_ATRFIN'. "Atributos Adicionales
      v_activefin = 'X'.
      v_grisa9000 = 'X'.
      CALL SCREEN 0200 STARTING AT 60 5
                       ENDING   AT 124 15.

  ENDCASE.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  F4_EQUIPO  INPUT
*&---------------------------------------------------------------------*
MODULE f4_equipo INPUT.

  DATA: lt_return TYPE STANDARD TABLE OF ddshretval,
        lt_field  TYPE STANDARD TABLE OF dfies,
        lw_field  TYPE dfies,
        lt_dynp   TYPE STANDARD TABLE OF dselc.

  IF sy-subrc = 0.
    SORT gt_equipo BY eqart eartx ASCENDING.

    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        retfield         = 'EQART'
        window_title     = 'Seleccion de Datos'
        dynpprog         = sy-cprog
        dynpnr           = '9000'
        dynprofield      = 'WA_SCREEN1-EQUIPO'
        callback_program = sy-cprog
        callback_form    = 'CALLBACK_F4EQUIPO'
        value_org        = 'S'
      TABLES
        value_tab        = gt_equipo
        field_tab        = lt_field
        return_tab       = lt_return
        dynpfld_mapping  = lt_dynp
      EXCEPTIONS
        parameter_error  = 1
        no_values_found  = 2
        OTHERS           = 3.

    IF lt_return IS NOT INITIAL.
      LOOP AT lt_return INTO DATA(lw_return).
        IF lw_return-fieldname = 'F0001'.
          wa_screen1-equipo     = lw_return-fieldval.
        ELSE.
          wa_screen1-equipo_txt = lw_return-fieldval.
        ENDIF.
      ENDLOOP.
    ENDIF.

  ENDIF.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  CALLBACK_F4EQUIPO
*&---------------------------------------------------------------------*
FORM callback_f4equipo TABLES record_tab  STRUCTURE seahlpres
                     CHANGING shlp        TYPE shlp_descr
                              callcontrol LIKE ddshf4ctrl.
  DATA:
    ls_intf LIKE LINE OF shlp-interface,
    ls_prop LIKE LINE OF shlp-fieldprop.

  CLEAR: ls_prop-shlpselpos,
         ls_prop-shlplispos.

*  " Overwrite selectable fields on search help
  REFRESH: shlp-interface.
  ls_intf-shlpfield = 'F0001'.
  ls_intf-valfield  = 'WA_SCREEN1-EQUIPO'.
  ls_intf-f4field   = 'X'.
  APPEND ls_intf TO shlp-interface.
  ls_intf-shlpfield = 'F0002'.
  ls_intf-valfield  = 'WA_SCREEN1-EQUIPO_TXT'.
  ls_intf-f4field   = 'X'.
  APPEND ls_intf TO shlp-interface.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Module  F4_MARCA  INPUT
*&---------------------------------------------------------------------*
MODULE f4_marca INPUT.

  PERFORM f_leer_valor_de_pantalla USING 'WA_SCREEN1-EQUIPO'
                                CHANGING v_fieldvalue.

  IF v_fieldvalue IS NOT INITIAL.
    SELECT equipo, marca
      FROM ztpauta_serv
      INTO TABLE @DATA(lt_marca)
      WHERE equipo = @v_fieldvalue.
  ELSE.
    SELECT equipo, marca
      FROM ztpauta_serv
      INTO TABLE @lt_marca.
  ENDIF.


  IF sy-subrc = 0.
    SORT lt_marca BY equipo marca ASCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_marca
      COMPARING marca.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'MARCA'
      window_title    = 'Seleccion de Datos'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'WA_SCREEN1-EQUIPO'
      value_org       = 'S'
    TABLES
      value_tab       = lt_marca
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  F4_MODELO  INPUT
*&---------------------------------------------------------------------*
MODULE f4_modelo INPUT.

  PERFORM f_leer_valor_de_pantalla USING 'WA_SCREEN1-MARCA'
                                CHANGING v_fieldvalue.

  IF v_fieldvalue IS NOT INITIAL.
    SELECT marca, modelo
      FROM ztpauta_serv
      INTO TABLE @DATA(lt_modelo)
     WHERE marca = @v_fieldvalue.
  ELSE.
    SELECT marca, modelo
      FROM ztpauta_serv
      INTO TABLE @lt_modelo.
  ENDIF.

  IF sy-subrc = 0.
    SORT lt_modelo BY marca modelo ASCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_modelo
      COMPARING modelo.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'MODELO'
      window_title    = 'Seleccion de Datos'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'WA_SCREEN1-MARCA'
      value_org       = 'S'
    TABLES
      value_tab       = lt_modelo
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  F4_MODALIDAD  INPUT
*&---------------------------------------------------------------------*
MODULE f4_modalidad INPUT.

  PERFORM f_leer_valor_de_pantalla USING 'WA_SCREEN1-MODELO'
                                CHANGING v_fieldvalue.

  IF v_fieldvalue IS NOT INITIAL.
    SELECT modalidad
      FROM ztpauta_serv
      INTO TABLE @DATA(lt_modalidad)
     WHERE modelo    = @v_fieldvalue.
  ELSE.
    SELECT modalidad
      FROM ztpauta_serv
      INTO TABLE @lt_modalidad.
  ENDIF.

  IF sy-subrc = 0.
    SORT lt_modalidad BY modalidad ASCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_modalidad
      COMPARING ALL FIELDS.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'MODALIDAD'
      window_title    = 'Seleccion de Datos'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'WA_SCREEN1-ATR1'
      value_org       = 'S'
    TABLES
      value_tab       = lt_modalidad
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  F4_sucursal INPUT
*&---------------------------------------------------------------------*
MODULE f4_sucursal INPUT.

  REFRESH: lt_return,
           lt_field,
           lt_dynp.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield         = 'VKBUR'
      window_title     = 'Seleccion de Datos'
      dynpprog         = sy-cprog
      dynpnr           = '9000'
      dynprofield      = 'WA_SCREEN1-VKBUR'
      callback_program = sy-cprog
      callback_form    = 'CALLBACK_F4SUCU'
      value_org        = 'S'
    TABLES
      value_tab        = gt_sucu
      field_tab        = lt_field
      return_tab       = lt_return
      dynpfld_mapping  = lt_dynp
    EXCEPTIONS
      parameter_error  = 1
      no_values_found  = 2
      OTHERS           = 3.

  IF lt_return IS NOT INITIAL.
    LOOP AT lt_return INTO lw_return.
      IF lw_return-fieldname = 'F0001'.
        wa_screen1-sucursal = lw_return-fieldval.
      ELSE.
        wa_screen1-sucu_txt = lw_return-fieldval.
      ENDIF.
    ENDLOOP.
  ENDIF.


ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  CALLBACK_F4SUCU
*&---------------------------------------------------------------------*
FORM callback_f4sucu TABLES record_tab STRUCTURE seahlpres
               CHANGING shlp TYPE shlp_descr
                     callcontrol LIKE ddshf4ctrl.
  DATA:
    ls_intf LIKE LINE OF shlp-interface,
    ls_prop LIKE LINE OF shlp-fieldprop.

  CLEAR: ls_prop-shlpselpos,
         ls_prop-shlplispos.

*  " Overwrite selectable fields on search help
  REFRESH: shlp-interface.
  ls_intf-shlpfield = 'F0001'.
  ls_intf-valfield  = 'WA_SCREEN1-SUCURSAL'.
  ls_intf-f4field   = 'X'.
  APPEND ls_intf TO shlp-interface.
  ls_intf-shlpfield = 'F0002'.
  ls_intf-valfield  = 'WA_SCREEN1-SUCU_TXT'.
  ls_intf-f4field   = 'X'.
  APPEND ls_intf TO shlp-interface.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Module  F4_LUGAR  INPUT
*&---------------------------------------------------------------------*
MODULE f4_lugar INPUT.

  PERFORM f_leer_valor_de_pantalla USING 'WA_SCREEN1-MODALIDAD'
                                CHANGING v_fieldvalue.

  IF v_fieldvalue IS NOT INITIAL.
    SELECT lugar
      FROM ztpauta_serv
      INTO TABLE @DATA(lt_lugar)
     WHERE modelo    = @wa_screen1-modelo
       AND modalidad = @v_fieldvalue.
  ELSE.
    SELECT lugar
      FROM ztpauta_serv
      INTO TABLE @lt_lugar.
  ENDIF.

  IF sy-subrc = 0.
    SORT lt_lugar BY lugar ASCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_lugar
      COMPARING ALL FIELDS.
    LOOP AT lt_lugar ASSIGNING FIELD-SYMBOL(<lw_lugar>).
      IF <lw_lugar>-lugar+4(2) = 'TA'.
        <lw_lugar>-lugar = 'TALLER'.
      ELSEIF <lw_lugar>-lugar+4(2) = 'TE'.
        <lw_lugar>-lugar = 'TERRENO'.
      ELSEIF <lw_lugar>-lugar+4(2) = 'CL'.
        <lw_lugar>-lugar = 'CAMION LUBRICADOR'.
      ENDIF.
    ENDLOOP.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'LUGAR'
      window_title    = 'Seleccion de Datos'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'WA_SCREEN1-LUGAR'
      value_org       = 'S'
    TABLES
      value_tab       = lt_lugar
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  F4_CAJA  INPUT
*&---------------------------------------------------------------------*
MODULE f4_caja INPUT.

  SELECT modelo, caja
    FROM ztpauta_serv
    INTO TABLE @DATA(lt_caja)
   WHERE modelo = @wa_screen1-modelo.

  IF sy-subrc = 0.
    SORT lt_caja BY modelo caja ASCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_caja
      COMPARING ALL FIELDS.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'CAJA'
      window_title    = 'Seleccion de Datos'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'WA_SCREEN1-MODELO'
      value_org       = 'S'
    TABLES
      value_tab       = lt_caja
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  F4_DIFERENCIAL  INPUT
*&---------------------------------------------------------------------*
MODULE f4_diferencial INPUT.

  SELECT modelo, diferencial
    FROM ztpauta_serv
    INTO TABLE @DATA(lt_diferencial)
   WHERE modelo = @wa_screen1-modelo.

  IF sy-subrc = 0.
    SORT lt_diferencial BY modelo diferencial ASCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_diferencial
      COMPARING ALL FIELDS.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'DIFERENCIAL'
      window_title    = 'Seleccion de Datos'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'WA_SCREEN1-CAJA'
      value_org       = 'S'
    TABLES
      value_tab       = lt_diferencial
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  F4_nrocotiz INPUT
*&---------------------------------------------------------------------*
MODULE f4_nrocotiz INPUT.

  REFRESH: lt_return, "TYPE STANDARD TABLE OF ddshretval,
           lt_field,  "TYPE STANDARD TABLE OF dfies,
           lt_dynp.   "TYPE STANDARD TABLE OF dselc.

  DATA: lv_cliente TYPE char25,
        lv_fecha   TYPE char25,
        lv_cotiz   TYPE char25,
        lv_version TYPE char25.

  PERFORM f_leer_valor_de_pantalla USING 'V_CLIENTE'
                                CHANGING lv_cliente.

  PERFORM f_leer_valor_de_pantalla USING 'V_FECHA'
                                CHANGING lv_fecha.

  PERFORM f_leer_valor_de_pantalla USING 'V_NROCOTIZ'
                                CHANGING lv_cotiz.

  PERFORM f_leer_valor_de_pantalla USING 'V_VERSION'
                                CHANGING lv_version.

  IF lv_cliente IS NOT INITIAL OR
     lv_fecha   IS NOT INITIAL OR
     lv_cotiz   IS NOT INITIAL OR
     lv_version IS NOT INITIAL.
    SELECT nro_cotiz, version, cliente, fecha
      FROM ztcoti_serv
      INTO TABLE @DATA(lt_cotiz)
      WHERE cliente   = @lv_cliente
        AND fecha     = @lv_fecha
        AND nro_cotiz = @lv_cotiz
        AND version   = @lv_version.
  ELSE.
    SELECT nro_cotiz, version, cliente, fecha
      FROM ztcoti_serv
      INTO TABLE @lt_cotiz.
  ENDIF.


  IF sy-subrc = 0.
    SORT lt_cotiz BY nro_cotiz DESCENDING version ASCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_cotiz
      COMPARING ALL FIELDS.
  ENDIF.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield         = 'NRO_COTIZ'
      window_title     = 'Seleccion de Datos'
      dynpprog         = sy-cprog
      dynpnr           = '0300'
      dynprofield      = 'V_NROCOTIZ'
      callback_program = sy-cprog
      callback_form    = 'CALLBACK_F4'
      value_org        = 'S'
    TABLES
      value_tab        = lt_cotiz
      field_tab        = lt_field
      return_tab       = lt_return
      dynpfld_mapping  = lt_dynp
    EXCEPTIONS
      parameter_error  = 1
      no_values_found  = 2
      OTHERS           = 3.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  CALLBACK_F4
*&---------------------------------------------------------------------*
FORM callback_f4 TABLES record_tab STRUCTURE seahlpres
               CHANGING shlp TYPE shlp_descr
                     callcontrol LIKE ddshf4ctrl.
  DATA:
    ls_intf LIKE LINE OF shlp-interface,
    ls_prop LIKE LINE OF shlp-fieldprop.

  CLEAR: ls_prop-shlpselpos,
         ls_prop-shlplispos.

*  " Overwrite selectable fields on search help
  REFRESH: shlp-interface.
  ls_intf-shlpfield = 'F0001'.
  ls_intf-valfield  = 'V_NROCOTIZ'.
  ls_intf-f4field   = 'X'.
  APPEND ls_intf TO shlp-interface.
  ls_intf-shlpfield = 'F0002'.
  ls_intf-valfield  = 'V_VERSION'.
  ls_intf-f4field   = 'X'.
  APPEND ls_intf TO shlp-interface.
  ls_intf-shlpfield = 'F0003'.
  ls_intf-valfield  = 'V_CLIENTE'.
  ls_intf-f4field   = 'X'.
  APPEND ls_intf TO shlp-interface.
  ls_intf-shlpfield = 'F0004'.
  ls_intf-valfield  = 'V_FECHA'.
  ls_intf-f4field   = 'X'.
  APPEND ls_intf TO shlp-interface.


ENDFORM.


*&---------------------------------------------------------------------*
*&      Module  F4_nrocotiz500 INPUT
*&---------------------------------------------------------------------*
MODULE f4_nrocotiz500 INPUT.

  DATA: lt_return500 TYPE STANDARD TABLE OF ddshretval,
        lt_field500  TYPE STANDARD TABLE OF dfies,
        lt_dynp500   TYPE STANDARD TABLE OF dselc.

  PERFORM f_leer_valor_de_pantalla USING 'V_NROCOTIZ500'
                                CHANGING v_fieldvalue.

  IF v_fieldvalue IS NOT INITIAL.
    SELECT nro_cotiz, version, cliente, fecha
      FROM ztcoti_serv
      INTO TABLE @DATA(lt_cotiz500)
      WHERE nro_cotiz = @v_fieldvalue.
  ELSE.
    SELECT nro_cotiz, version, cliente, fecha
      FROM ztcoti_serv
      INTO TABLE @lt_cotiz500.
  ENDIF.


  IF sy-subrc = 0.
    SORT lt_cotiz500 BY nro_cotiz DESCENDING version ASCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_cotiz500
      COMPARING ALL FIELDS.
  ENDIF.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield         = 'NRO_COTIZ'
      window_title     = 'Seleccion de Datos'
      dynpprog         = sy-cprog
      dynpnr           = '0500'
      dynprofield      = 'V_NROCOTIZ500'
      callback_program = sy-cprog
      callback_form    = 'CALLBACK_F4_500'
      value_org        = 'S'
    TABLES
      value_tab        = lt_cotiz500
      field_tab        = lt_field500
      return_tab       = lt_return500
      dynpfld_mapping  = lt_dynp500
    EXCEPTIONS
      parameter_error  = 1
      no_values_found  = 2
      OTHERS           = 3.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  CALLBACK_F4_500
*&---------------------------------------------------------------------*
FORM callback_f4_500 TABLES record_tab STRUCTURE seahlpres
               CHANGING shlp TYPE shlp_descr
                     callcontrol LIKE ddshf4ctrl.
  DATA:
    ls_intf LIKE LINE OF shlp-interface,
    ls_prop LIKE LINE OF shlp-fieldprop.

  CLEAR: ls_prop-shlpselpos,
         ls_prop-shlplispos.

*  " Overwrite selectable fields on search help
  REFRESH: shlp-interface.
  ls_intf-shlpfield = 'F0001'.
  ls_intf-valfield  = 'V_NROCOTIZ500'.
  ls_intf-f4field   = 'X'.
  APPEND ls_intf TO shlp-interface.
  ls_intf-shlpfield = 'F0002'.
  ls_intf-valfield  = 'V_VERSION500'.
  ls_intf-f4field   = 'X'.
  APPEND ls_intf TO shlp-interface.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  v_active9000 = 'X'.
  CASE v_ok_code_0100.
    WHEN c_back.
      LEAVE TO SCREEN 0.
    WHEN c_exit.
      LEAVE TO SCREEN 0.
    WHEN c_cancel.
      LEAVE TO SCREEN 0.
  ENDCASE.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
MODULE user_command_0200 INPUT.

  v_active9000 = 'X'.
  IF v_ok_code_0200 EQ 'CANCELAP'.
    CLEAR: v_rb_ajust, v_rb_viaticos, v_viaticos.
    LEAVE TO SCREEN 0.
  ELSEIF v_ok_code_0200 EQ 'ACEPTAP'.
    LEAVE TO SCREEN 0.
  ENDIF.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0300  INPUT
*&---------------------------------------------------------------------*
MODULE user_command_0300 INPUT.

  CASE v_ok_code_0300.
    WHEN 'CANCELAP'.
      LEAVE TO SCREEN 0.
    WHEN 'ACEPTAP'.
      PERFORM f_cargar_cotizacion_vieja.
    WHEN OTHERS.
  ENDCASE.

  LEAVE TO SCREEN 0.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0400  INPUT
*&---------------------------------------------------------------------*
MODULE user_command_0400 INPUT.

  CASE v_ok_code_0400.
    WHEN 'CANCELAP'.
      LEAVE TO SCREEN 0.
    WHEN 'ACEPTAP'.
      PERFORM f_crear_pedido.
    WHEN OTHERS.
  ENDCASE.

  LEAVE TO SCREEN 0.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0500  INPUT
*&---------------------------------------------------------------------*
MODULE user_command_0500 INPUT.

  CASE v_ok_code_0500.
    WHEN 'CANCELA5'.
      LEAVE TO SCREEN 0.
    WHEN 'ACEPTA5'.
      PERFORM f_cargar_int.
    WHEN OTHERS.
  ENDCASE.

  LEAVE TO SCREEN 0.

ENDMODULE.
