*&---------------------------------------------------------------------*
*&  Include           ZCOTIZADOR_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  F_PAUTA_VARIABLES_IMPORTES
*&---------------------------------------------------------------------*
FORM f_pauta_variables_importes.

  DATA: lw_pauta TYPE ty_pauta,
        lv_tabix TYPE sy-tabix.

  IF wa_screen1-lugar(2) EQ 'TE'.
    v_rb_ajust = 'X'.
  ELSE.
    CLEAR v_rb_ajust.
  ENDIF.

  IF gt_pauta IS INITIAL. "Si no es inicial Cargó una pauta vieja

    SELECT *
      FROM ztpauta
      INTO CORRESPONDING FIELDS OF TABLE gt_pauta
     WHERE equipo      = wa_screen1-equipo
       AND marca       = wa_screen1-marca
       AND modelo      = wa_screen1-modelo
       AND modalidad   = wa_screen1-modalidad
       AND lugar       = wa_screen1-lugar
       AND caja        = wa_screen1-caja
       AND diferencial = wa_screen1-diferencial.

  ENDIF.

  SELECT *
    FROM ztparam_coti
    INTO TABLE gt_param.

  IF gt_pauta IS NOT INITIAL.

*    PERFORM f_obtener_variables.
    PERFORM f_importe_repuestos.
    PERFORM f_importe_implubri.

    LOOP AT gt_pauta ASSIGNING FIELD-SYMBOL(<fs_pauta>).
      REPLACE ',' IN <fs_pauta>-cantidad WITH '.'.
    ENDLOOP.

  ENDIF.

ENDFORM.         "F_PAUTA_VARIABLES_IMPORTES


*&---------------------------------------------------------------------*
*&      Form  F_IMPORTE_REPUESTOS
*&---------------------------------------------------------------------*
FORM f_importe_repuestos .

  DATA: lt_materiales   TYPE STANDARD TABLE OF ty_materiales,
        lv_atinn        TYPE ausp-atinn VALUE '0000000011',
        lv_total        TYPE i,
        lv_dto_contrato TYPE p DECIMALS 2,
        lv_descuento    TYPE p DECIMALS 2.

  DATA  BEGIN OF gt_list OCCURS 0.
  INCLUDE STRUCTURE abaplist.
  DATA  END OF gt_list.

  DATA: BEGIN OF gt_list_ascii OCCURS 0,
          line(2048),
        END OF gt_list_ascii.

  DATA: lr_matkl   TYPE RANGE OF mara-matkl,
        lr_matnr   TYPE RANGE OF mara-matnr,
        lr_spart   TYPE RANGE OF mara-spart,
        lw_matkl   LIKE LINE OF lr_matkl,
        lw_matnr   LIKE LINE OF lr_matnr,
        lw_spart   LIKE LINE OF lr_spart,
        lv_index   TYPE sy-tabix,
        lv_dummy_i TYPE string,
        lv_dummy_f TYPE string.

  REFRESH lr_spart.
  lw_spart-sign   = 'I'.
  lw_spart-option = 'BT'.
  lw_spart-low    = '00'.
  lw_spart-high   = 'ZZ'.
  APPEND lw_spart TO lr_spart.

  REFRESH lr_matkl.
  lw_matkl-sign   = 'I'.
  lw_matkl-option = 'BT'.
  lw_matkl-low    = '0000'.
  lw_matkl-high   = '9999'.
  APPEND lw_matkl TO lr_matkl.

  REFRESH lr_matnr.
  LOOP AT gt_pauta INTO DATA(lw_pauta).
    lw_matnr-sign   = 'I'.
    lw_matnr-option = 'EQ'.
    lw_matnr-low    = lw_pauta-matnr.
    APPEND lw_matnr TO lr_matnr.
  ENDLOOP.
  DELETE ADJACENT DUPLICATES FROM lr_matnr COMPARING ALL FIELDS.

  SUBMIT zrmm231_lista_precio_rep USING SELECTION-SCREEN '1000'
        WITH p_bukrs EQ '1000'
        WITH s_matkl IN lr_matkl
        WITH s_matnr IN lr_matnr
        WITH s_spart IN lr_spart
        EXPORTING LIST TO MEMORY AND RETURN.

  CALL FUNCTION 'LIST_FROM_MEMORY'
    TABLES
      listobject = gt_list
    EXCEPTIONS
      not_found  = 1
      OTHERS     = 2.

  IF sy-subrc EQ 0.
    CALL FUNCTION 'LIST_TO_ASCI'
      EXPORTING
        list_index         = -1
      TABLES
        listasci           = gt_list_ascii
        listobject         = gt_list
      EXCEPTIONS
        empty_list         = 1
        list_index_invalid = 2
        OTHERS             = 3.
    IF sy-subrc EQ 0.

      READ TABLE gt_param INTO DATA(lw_param)
        WITH KEY tipo = 'DTO_CONTRATO'.
      IF sy-subrc = 0.
        REPLACE ALL OCCURRENCES OF '%' IN lw_param-valor1 WITH space.
        REPLACE ALL OCCURRENCES OF ',' IN lw_param-valor1 WITH '.'.
      ENDIF.

      "Recorremos lista y traspasamos campos a tabla interna
      CLEAR lv_index.
      LOOP AT gt_list_ascii FROM 4.

        lv_dto_contrato = lw_param-valor1.

        ADD 1 TO lv_index.
        IF gt_list_ascii-line(1) NE '|'.
          "No corresponde a línea de data
          CONTINUE.
        ELSE.
          "Generamos datos para tabla interna
          SPLIT gt_list_ascii-line AT '|' INTO
          lv_dummy_i
          wa_repuestos-matnr
          wa_repuestos-mfrpn
          wa_repuestos-maktx
          wa_repuestos-matkl
          wa_repuestos-spart
          wa_repuestos-labst
          wa_repuestos-precio
          wa_repuestos-descuento
          wa_repuestos-total
          wa_repuestos-reemplazo
          lv_dummy_f.

          CONDENSE:
          wa_repuestos-matnr,
          wa_repuestos-mfrpn,
          wa_repuestos-maktx,
          wa_repuestos-matkl,
          wa_repuestos-spart,
          wa_repuestos-labst,
          wa_repuestos-precio,
          wa_repuestos-descuento,
          wa_repuestos-total,
          wa_repuestos-reemplazo.

          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
            EXPORTING
              input  = wa_repuestos-matnr
            IMPORTING
              output = wa_repuestos-matnr.

          REPLACE ALL OCCURRENCES OF '.' IN wa_repuestos-precio WITH ''.
          REPLACE ALL OCCURRENCES OF ',' IN wa_repuestos-precio WITH ''.
          REPLACE ALL OCCURRENCES OF ',' IN wa_repuestos-descuento WITH '.'.
          lv_descuento = wa_repuestos-descuento.

          IF wa_repuestos-spart = 'R0' OR wa_repuestos-spart = 'R2'.
            ADD lv_descuento TO lv_dto_contrato.
            lv_total = wa_repuestos-precio * ( 1 - ( lv_dto_contrato ) / 100 ).
            wa_repuestos-total = lv_total.
          ELSE.
            REPLACE ALL OCCURRENCES OF '.' IN wa_repuestos-total WITH ''.
            REPLACE ALL OCCURRENCES OF ',' IN wa_repuestos-total WITH ''.
          ENDIF.

          APPEND wa_repuestos TO gt_repuestos.

        ENDIF.
      ENDLOOP.
      DELETE gt_repuestos WHERE matnr = '*'.
    ELSE.
      MESSAGE '' TYPE 'S' DISPLAY LIKE 'E'.
    ENDIF.
  ELSE.
    MESSAGE '' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.    "F_IMPORTE_REPUESTOS


*&---------------------------------------------------------------------*
*&      Form  F_IMPORTE_implubri
*&---------------------------------------------------------------------*
FORM f_importe_implubri.

  DATA: lv_spart     TYPE spart VALUE 'P%',
        lv_dto_lubri TYPE p DECIMALS 2,
        lv_total     TYPE i.

  SELECT *
    FROM mara
    INTO TABLE @DATA(lt_mara)
     FOR ALL ENTRIES IN @gt_pauta
   WHERE matnr = @gt_pauta-matnr
     AND spart LIKE @lv_spart.

  IF sy-subrc = 0.

    SELECT *
      FROM a564
      INTO TABLE @DATA(lt_a564)
       FOR ALL ENTRIES IN @lt_mara
     WHERE kappl = 'V'
       AND kschl = 'ZPSV'
       AND vkorg = '1000'
       AND vtweg = 'SE'
       AND spart = @lt_mara-spart
       AND matnr = @lt_mara-matnr
       AND datab LT @sy-datum
       AND datbi GT @sy-datum.

    IF sy-subrc = 0.

      SELECT *
        FROM konp
        INTO TABLE @DATA(lt_konp)
         FOR ALL ENTRIES IN @lt_a564
       WHERE knumh = @lt_a564-knumh.

      IF sy-subrc = 0.

        READ TABLE gt_param INTO DATA(lw_param)
          WITH KEY tipo = 'DTO_LUBRICANTES'.
        IF sy-subrc = 0.
          REPLACE ALL OCCURRENCES OF '%' IN lw_param-valor1 WITH space.
          REPLACE ALL OCCURRENCES OF ',' IN lw_param-valor1 WITH '.'.
          lv_dto_lubri = lw_param-valor1.
        ENDIF.

        REFRESH gt_implubri[].
        LOOP AT lt_konp INTO DATA(lw_konp).
          READ TABLE lt_a564 INTO DATA(lw_a564)
            WITH KEY knumh = lw_konp-knumh.
          IF sy-subrc = 0.
            CLEAR: wa_implubri, lv_total.
            lv_total = lw_konp-kbetr * ( 1 - ( lv_dto_lubri ) / 100 ) * 100.
            wa_implubri-matnr     = lw_a564-matnr.
            wa_implubri-kbetr     = lv_total.
            wa_implubri-precio    = lw_konp-kbetr.
            wa_implubri-descuento = lv_dto_lubri.
            wa_implubri-total     = lv_total.
            APPEND wa_implubri TO gt_implubri.
          ENDIF.
        ENDLOOP.
      ENDIF.

    ENDIF.

  ENDIF.

* MUESTRAS DE ACEITE
* SERVICIOS
  SELECT *
    FROM ztservicios
    INTO TABLE gt_servicios.

*    SELECT *
*      FROM a519
*      INTO TABLE @DATA(lt_a519)
*       FOR ALL ENTRIES IN @lt_mara
*     WHERE kappl = 'V'
*       AND kschl = 'ZPSV'
*       AND vkorg = '1000'
*       AND matnr = @lt_mara-matnr
*       AND datab LT @sy-datum
*       AND datbi GT @sy-datum.
*
*    IF sy-subrc = 0.
*
*      REFRESH lt_konp.
*      SELECT *
*        FROM konp
*        INTO TABLE lt_konp
*         FOR ALL ENTRIES IN lt_a519
*       WHERE knumh = lt_a519-knumh.
*
*      IF sy-subrc = 0.
*
*        REFRESH gt_servicios[].
*        LOOP AT lt_konp INTO lw_konp.
*          READ TABLE lt_a519 INTO DATA(lw_a519)
*            WITH KEY knumh = lw_konp-knumh.
*          IF sy-subrc = 0.
*            CLEAR: wa_servicios, lv_total.
**            lv_total = lw_konp-kbetr * ( 1 - ( lv_dto_lubri ) / 100 ) * 100.
*            lv_total = lw_konp-kbetr * 100.
*            wa_servicios-matnr     = lw_a564-matnr.
*            wa_servicios-importe   = lv_total.
*            APPEND wa_servicios TO gt_servicios.
*          ENDIF.
*        ENDLOOP.
*
*      ENDIF.
*
*    ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_OBTENER_FORMULA
*&---------------------------------------------------------------------*
FORM f_obtener_formula .

  DATA: lt_aceite     TYPE STANDARD TABLE OF ty_pauta,
        lt_pauta_i    TYPE tyt_pauta_i,
        lt_repuesto   TYPE STANDARD TABLE OF ty_pauta,
        lt_lubricante TYPE STANDARD TABLE OF ty_pauta,

*        lw_tempario   TYPE zttempario,
        lw_aceite     TYPE ty_pauta,
        lw_repuesto   TYPE ty_pauta,
        lw_lubricante TYPE ty_pauta,
        lw_cotizacion TYPE ztcotizacion,
        lw_contrato   TYPE ty_val_contrato,
        lw_pauta_i    TYPE ty_pauta_i,
        lw_comision   TYPE ty_comision,
        lw_intervalos TYPE ztcoti_intervalo.

  DATA: lv_hora_fin       TYPE p DECIMALS 3,
        lv_structure_name TYPE text30,
        lv_ak             TYPE wrbtr,
        lv_dto(4)         TYPE c,
        lv_dto4000(4)     TYPE c,
        lv_dtoultim(4)    TYPE c,
        lv_tasas(4)       TYPE c,
        lv_tasa_rep(4)    TYPE c,
        lv_tasa_lub(4)    TYPE c,
        lv_valor_d(3)     TYPE n,
        lv_valor_t(3)     TYPE n,
        lv_valor_tr(3)    TYPE n,
        lv_valor_lu(3)    TYPE n,
        lv_valor_p(15)    TYPE p DECIMALS 3,
        lv_an             TYPE wrbtr,
        lv_long           TYPE i,
        lv_ao             TYPE wrbtr,
        lv_aux(8)         TYPE p DECIMALS 2,
        lv_cantidad       TYPE p DECIMALS 3,
        lv_y              TYPE wrbtr,
        lv_ac             TYPE wrbtr,
        lv_av             TYPE wrbtr,
        lv_ai             TYPE wrbtr,
        lv_aj             TYPE wrbtr,
        lv_ah             TYPE wrbtr,
        lv_ac_ajust       TYPE i,
        lv_ao_ajust       TYPE i,
        lv_n_ajust        TYPE i,
        lv_r              TYPE wrbtr,
        lv_t              TYPE wrbtr,
        lv_j              TYPE wrbtr,
        lv_w              TYPE wrbtr,
        lv_x              TYPE wrbtr,
        lv_rep_ajust      TYPE wrbtr,
        lv_l              TYPE wrbtr,
        lv_lub_ajust      TYPE wrbtr,
        lv_p              TYPE wrbtr,
        lv_prepago1       TYPE int8,
        lv_prepago2       TYPE int8,
        lv_prepago3       TYPE int8,
        lv_prepago4       TYPE int8,
        lv_prepago1_acum  TYPE int8,
        lv_prepago2_acum  TYPE int8,
        lv_prepago3_acum  TYPE int8,
        lv_prepago4_acum  TYPE int8,
        lv_cant           TYPE i,
        lv_comision1      TYPE i,
        lv_comision2      TYPE i,
        lv_comision3      TYPE i,
        lv_comision4      TYPE i,
        lv_ar             TYPE wrbtr,
        lv_aa             TYPE wrbtr,
        lv_ae             TYPE wrbtr,
        lv_as             TYPE wrbtr,
        lv_ax             TYPE wrbtr,
        lv_rae            TYPE i,
        lv_ras            TYPE i,
        lv_rt             TYPE i,
        lv_perio_mes1     TYPE i,
        lv_perio_mes2     TYPE i,
        lv_perio_mes3     TYPE i,
        lv_perio_mes4     TYPE i,
        lv_tasa_mensu     TYPE char4, "n LENGTH 4,
        lv_precio_km      TYPE i,
        lv_precio_hs      TYPE i,
        lv_intervalo      TYPE ztcoti_intervalo-intervalo,
        lv_intervalo_100  TYPE ztcoti_intervalo-intervalo VALUE '500',
        lv_tasa_m         TYPE p DECIMALS 6,
        lv_cuota_t1       TYPE i,
        lv_cuota_t2       TYPE i,
        lv_cuota_t3       TYPE i,
        lv_cuota_t4       TYPE i,
        lv_valor_hs1      TYPE p DECIMALS 2,
        lv_valor_hs2      TYPE p DECIMALS 2,
        lv_valor_hs3      TYPE p DECIMALS 2,
        lv_valor_hs4      TYPE p DECIMALS 2,
        lv_0coma1         TYPE char3 VALUE '0.1',
        lv_coef_km        TYPE i.

  FIELD-SYMBOLS: <f_field>       TYPE any,
                 <fs_struc>      TYPE any,
                 <fs_intervalos> TYPE ztcoti_intervalo.

  CONSTANTS: lc_dto(20)        TYPE c VALUE 'DESCUENTO MO',
             lc_tasa(20)       TYPE c VALUE 'TASA AJUSTE SERVICIO',
             lc_tasa_rep(20)   TYPE c VALUE 'TASA DE INTERES REP',
             lc_tasa_lub(20)   TYPE c VALUE 'TASA DE INTERES LUB',
             lc_desc_cli(20)   TYPE c VALUE 'DESCUENTO CLIENTE',
             lc_tasa_mensu(20) TYPE c VALUE 'CUOTA TASA MENSUAL'.

  CLEAR: lv_cant, gt_cotizacion, lv_perio_mes1.

  lw_contrato-valor1 = wa_screen1-uso + wa_screen1-uso_inicial.
  lw_contrato-valor2 = ( wa_screen1-uso * 2 ) + wa_screen1-uso_inicial.
  lw_contrato-valor3 = ( wa_screen1-uso * 3 ) + wa_screen1-uso_inicial.
  lw_contrato-valor4 = ( wa_screen1-uso * 4 ) + wa_screen1-uso_inicial.

  MOVE-CORRESPONDING gt_pauta TO lt_pauta_i.
  "Determina variable de análisis valuaciones.
  SORT lt_pauta_i BY intervalo_mine ASCENDING.

  TRY.
      IF wa_screen1-equipo NE c_agricola.
        DATA(lv_interv) = lt_pauta_i[ 1 ]-intervalo_mine.
      ELSE.
        lv_interv = lt_pauta_i[ 2 ]-intervalo_mine.
      ENDIF.
    CATCH cx_sy_itab_line_not_found.
  ENDTRY.

  IF lv_interv NE 0. "Solo si intervalo tiene valor si es 0 no pasa

    REFRESH lt_aceite[].
    lt_aceite[] = gt_pauta[].
    DELETE lt_aceite WHERE material NP 'MUESTRA DE ACEITE*'.

    REFRESH lt_repuesto[].
    lt_repuesto[] = gt_pauta[].
    DELETE lt_repuesto WHERE material NP 'REPUESTO*'.

    REFRESH lt_lubricante[].
    lt_lubricante[] = gt_pauta[].
    DELETE lt_lubricante WHERE material NP 'LUBRICA*'. "'LUBRICACION*'

*    LOOP AT gt_tempario ASSIGNING FIELD-SYMBOL(<fs_tempario>).
*      REPLACE ',' IN <fs_tempario>-cantidad WITH '.'.
*    ENDLOOP.

*    IF wa_screen1-equipo = 'AGRICOLA'.
*      READ TABLE gt_param INTO DATA(lw_param)
*        WITH KEY tipo = 'IMPORTE_KM_AGRICOLA'.
*      IF sy-subrc = 0.
*        lv_precio_km = lw_param-valor1.
*      ENDIF.
*      READ TABLE gt_param INTO lw_param
*        WITH KEY tipo = 'IMPORTE_HS_AGRICOLA'.
*      IF sy-subrc = 0.
*        lv_precio_hs = lw_param-valor1.
*      ENDIF.
*    ELSE.
*      READ TABLE gt_param INTO lw_param
*        WITH KEY tipo = 'IMPORTE_KM_PESADOS'.
*      IF sy-subrc = 0.
*        lv_precio_km = lw_param-valor1.
*      ENDIF.
*      READ TABLE gt_param INTO lw_param
*        WITH KEY tipo = 'IMPORTE_HS_PESADOS'.
*      IF sy-subrc = 0.
*        lv_precio_hs = lw_param-valor1.
*      ENDIF.
*    ENDIF.

    "solo cuando es tarifa variable y camiones debe tomar las tasas inflacionarias en 0
    IF wa_screen1-chk_ipc IS INITIAL.

      READ TABLE gt_param INTO DATA(lw_param)
        WITH KEY tipo = lc_tasa_rep. "'TASA DE INTERES REP'
      IF sy-subrc = 0.
        lv_tasa_rep = lw_param-valor1.
      ELSE.
        lv_tasa_rep = '0%'.
      ENDIF.

      READ TABLE gt_param INTO lw_param
        WITH KEY tipo = lc_tasa_lub. "'TASA DE INTERES LUB'
      IF sy-subrc = 0 AND wa_screen1-equipo NE c_agricola.
        lv_tasa_lub = lw_param-valor1.
      ELSE.
        lv_tasa_lub = '0%'.
      ENDIF.

*      READ TABLE gt_param INTO lw_param
*        WITH KEY tipo = lc_tasa. "'TASA AJUSTE SERVICIO'
*      IF sy-subrc = 0.
*        lv_tasas = lw_param-valor1.
*      ELSE.
*        lv_tasas = '0%'.
*      ENDIF.

      lv_dto     = '0%'.
      lv_dto4000 = '0%'.
      lv_dtoultim = '0%'.

    ELSE.
      lv_tasa_rep = '0%'.
      lv_tasa_lub = '0%'.
      lv_tasas    = '0%'.

      IF wa_screen1-equipo EQ c_agricola.
        lv_dto      = '0%'.
        lv_dto4000  = '0%'.
        lv_dtoultim = '0%'.
      ELSE.
        READ TABLE gt_param INTO lw_param
          WITH KEY tipo = lc_dto. "'DESCUENTO MO'
        IF sy-subrc = 0.
          lv_dto      = lw_param-valor1.
          lv_dto4000  = lw_param-valor3.
          lv_dtoultim = lw_param-valor4.
        ENDIF.
      ENDIF.
    ENDIF.

    READ TABLE gt_param INTO lw_param
      WITH KEY tipo        = 'COMISION'
               opcion      = wa_screen1-equipo
               descripcion = wa_screen1-marca.
    IF sy-subrc EQ 0.
      lw_comision-comision1 = lw_param-valor1.
      lw_comision-comision2 = lw_param-valor2.
      lw_comision-comision3 = lw_param-valor3.
      lw_comision-comision4 = lw_param-valor4.
    ENDIF.

    wa_screen1-uso_iniciali = wa_screen1-uso_inicial.



***************************************
*  COLUMNA 1
***************************************

    DO.
      ADD 1 TO lv_cant.

      lv_intervalo = lv_cant * lv_interv.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = lv_intervalo
        IMPORTING
          output = lv_intervalo.

      IF lw_contrato-valor1 < ( lv_cant * lv_interv ).
        EXIT.
      ENDIF.

      "DURACION EN MES
      IF ( ( lv_interv * lv_cant ) - wa_screen1-uso_inicial <= 0 ).
        lv_perio_mes1 = 1.
      ELSE.
        lv_perio_mes1 = ( ( ( lv_interv * lv_cant ) - wa_screen1-uso_inicial )
                                / wa_screen1-uso ) * 12.
      ENDIF.
      COMPUTE lv_perio_mes1 = trunc( lv_perio_mes1 ).


*      CLEAR: lv_hora_fin, lv_cantidad.
*      IF wa_screen1-equipo EQ c_camiones.
*        LOOP AT gt_tempario INTO lw_tempario.
*          IF ( lv_interv * lv_cant ) MOD lw_tempario-base_mineral = 0.
*            lv_cantidad = lw_tempario-cantidad.
*            ADD lv_cantidad TO lv_hora_fin.
*          ENDIF.
*        ENDLOOP.
*      ELSE.
*        READ TABLE gt_tempario INTO lw_tempario
*          WITH KEY base_mineral = lv_intervalo.
*        IF sy-subrc = 0.
*          lv_hora_fin = lw_tempario-cantidad.
*        ENDIF.
*      ENDIF.
*
*      "AK
*      IF NOT wa_screen1-uso IS INITIAL AND
*          ( lv_interv * lv_cant < wa_screen1-uso_iniciali ).
*        CLEAR: lv_ak.
*      ELSE.
*        CONCATENATE 'IMPORTE_' wa_screen1-lugar INTO DATA(lv_mano_obra).
*        CONDENSE lv_mano_obra NO-GAPS.
*        lv_structure_name = 'WA_MANODEOBRA'.
*        ASSIGN (lv_structure_name) TO <fs_struc>.
*        ASSIGN COMPONENT lv_mano_obra OF STRUCTURE <fs_struc> TO <f_field>.
*        lv_ak = <f_field> * lv_hora_fin.
*      ENDIF.
*
*      CLEAR: lv_valor_d, lv_an, lv_long.
*
*      IF lv_dto IS NOT INITIAL.
*        lv_long = strlen( lv_dto ) - 1.
*        WRITE lv_dto(lv_long) TO lv_valor_d.
*        lv_an = lv_ak * ( 1 - lv_valor_d  / 100 ).
*      ENDIF.
*
      CLEAR: lv_valor_t, lv_valor_p, lv_ao, lv_y.
*
*      "DEFINIR VIATICO PARA TERRENO
*      IF lv_hora_fin IS INITIAL.
*        lv_y = 0.
*      ELSE.
*        IF wa_screen1-modelo EQ '130GLC' .
*          lv_y = '10000'.
*        ELSE.
*          lv_y = lv_an * '0.06'.
*        ENDIF.
*      ENDIF.
*
      IF NOT lv_tasas IS INITIAL.
        lv_long = strlen( lv_tasas ) - 1.

        WRITE lv_tasas(lv_long) TO lv_valor_t.
        "Calcula período
        IF NOT wa_screen1-uso_inicial IS INITIAL.
          lv_aux = ( lv_interv * lv_cant ) - wa_screen1-uso_inicial.
          IF lv_aux <= 0.
            lv_valor_p = 1.
          ELSE.
            lv_valor_p = ( lv_interv * lv_cant - wa_screen1-uso_inicial ) / wa_screen1-uso.
            IF ( lv_interv * lv_cant - wa_screen1-uso_inicial ) MOD wa_screen1-uso NE 0 .
              lv_valor_p = lv_valor_p + 1.
            ENDIF.
          ENDIF.
        ELSE.
          lv_valor_p = ( lv_interv * lv_cant - wa_screen1-uso_inicial ) /
                wa_screen1-uso .
          IF lv_interv * lv_cant MOD wa_screen1-uso NE 0.
            lv_valor_p = lv_valor_p + 1.
          ENDIF.
        ENDIF.
*
        COMPUTE lv_valor_p = trunc( lv_valor_p ).
        REPLACE ',' INTO lv_valor_t WITH '.'.
*        lv_ao = lv_an * ( 1 + lv_valor_t / 100 ) ** ( lv_valor_p - 1 ).
*
      ENDIF.
*
      CLEAR: lv_ac, lv_ac_ajust, lv_av, lv_r, lv_j, lv_t, lv_rt.
*
*      "Si es terreno y se seleccionó el CHECK de MATERIALES AJUST
*      IF wa_screen1-lugar(2) EQ 'TE'.
*        IF NOT v_rb_ajust IS INITIAL.
*          lv_ac       = lv_y * ( 1 + lv_valor_t / 100 ) ** ( lv_valor_p - 1 ).
*          lv_ac_ajust = lv_ac.
*        ENDIF.
*      ELSE.
*        "Si es Taller siempre se toma en cuenta
*        lv_ac       = lv_y * ( 1 + lv_valor_t / 100 ) ** ( lv_valor_p - 1 ).
*        lv_ac_ajust = lv_ac.
*      ENDIF.
*
*      lv_av = lv_ao + lv_ac_ajust.

      "Muestra de Aceite
      IF NOT wa_screen1-uso_inicial IS INITIAL AND
             ( lv_interv * lv_cant ) < wa_screen1-uso_iniciali.
        lv_r = 0.
      ELSE.
        LOOP AT lt_aceite INTO lw_aceite. "MUESTRA DE ACEITE
          IF lw_aceite-intervalo_mine NE 0.
            IF ( lv_interv * lv_cant ) MOD lw_aceite-intervalo_mine = 0.
              READ TABLE gt_servicios INTO DATA(lw_servicios)
                WITH KEY matnr = lw_aceite-matnr.
              IF sy-subrc EQ 0.
                lv_r = lw_aceite-cantidad * lw_servicios-importe + lv_r.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDIF.

      lv_t = lv_r * ( 1 + lv_valor_t  / 100 ) ** ( lv_valor_p - 1 ).

      lv_rt = lv_t.

      "Repuestos
      IF NOT wa_screen1-uso_inicial IS INITIAL AND
               ( lv_interv * lv_cant ) < wa_screen1-uso_iniciali.
        lv_j = 0.
      ELSE.
        LOOP AT lt_repuesto INTO lw_repuesto.
          IF lw_repuesto-intervalo_mine NE 0.
            IF ( lv_interv * lv_cant ) MOD lw_repuesto-intervalo_mine = 0.
              READ TABLE gt_repuestos INTO wa_repuestos
                WITH KEY matnr = lw_repuesto-matnr.
              IF sy-subrc = 0.
                lv_j = lw_repuesto-cantidad * wa_repuestos-total + lv_j.
              ELSE.
                READ TABLE gt_implubri INTO wa_implubri
                  WITH KEY matnr = lw_repuesto-matnr.
                IF sy-subrc = 0.
                  lv_j = lw_repuesto-cantidad * wa_implubri-kbetr + lv_j.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDIF.

      CLEAR: lv_long, lv_valor_tr, lv_rep_ajust, lv_lub_ajust,
             lv_l, lv_p, lv_w, lv_x.

      "lv_tasa_rep tendrá 0% o el porcentaje levantado de la tabla
      IF lv_tasa_rep(1) NE '0'.
        lv_long = strlen( lv_tasa_rep ) - 1.
        WRITE lv_tasa_rep(lv_long) TO lv_valor_tr.
      ENDIF.
      lv_rep_ajust = lv_j * ( 1 + lv_valor_tr  / 100 ) ** ( lv_valor_p - 1 ).

      lv_n_ajust = lv_rep_ajust.


      "Lubricantes
      IF NOT wa_screen1-uso_inicial IS INITIAL AND
         ( lv_interv * lv_cant ) < wa_screen1-uso_iniciali.
        lv_l = 0.
      ELSE.
        LOOP AT lt_lubricante INTO lw_lubricante.
          IF lw_lubricante-intervalo_mine NE 0.
            IF ( lv_interv * lv_cant ) MOD lw_lubricante-intervalo_mine = 0.
              READ TABLE gt_implubri INTO wa_implubri
                WITH KEY matnr = lw_lubricante-matnr.
              IF sy-subrc = 0.
                lv_l = lw_lubricante-cantidad * wa_implubri-kbetr + lv_l.
              ELSE.
                READ TABLE gt_repuestos INTO wa_repuestos
                  WITH KEY matnr = lw_lubricante-matnr.
                IF sy-subrc = 0.
                  lv_l = lw_lubricante-cantidad * wa_repuestos-total + lv_l.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDIF.

      "Nuevo Lubricantes "Ajustados"
      "lv_tasa_lub tendrá 0% o el porcentaje levantado de la tabla
      IF lv_tasa_lub(1) NE '0'.
        lv_long = strlen( lv_tasa_lub ) - 1.
        WRITE lv_tasa_lub(lv_long) TO lv_valor_lu.
      ENDIF.
      lv_lub_ajust = lv_l * ( 1 + lv_valor_lu  / 100 ) ** ( lv_valor_p - 1 ).

      lv_ao_ajust = lv_lub_ajust.

      lv_p = lv_n_ajust + lv_ao_ajust. "Repuestos + Lubricantes

*      CLEAR: lv_ai,  lv_ah, lv_aj.
*      IF v_km_terreno IS NOT INITIAL OR v_hs_terreno IS NOT INITIAL OR v_peajes IS NOT INITIAL.
*        lv_ai = ( lv_precio_km * v_km_terreno * 2 ).
*        lv_ah = ( lv_precio_hs * v_hs_terreno * 2 ).
*        lv_aj = ( lv_ai + lv_ah + v_peajes ) * ( 1 + lv_valor_t  / 100 ) ** ( lv_valor_p - 1 ).
*      ENDIF.
*
*      "Viaticos
*      IF NOT v_rb_viaticos IS INITIAL.
*        DATA(lv_vhs) = lv_hora_fin + v_hs_terreno.
*        IF lv_vhs < 5.
*          lv_w = wa_manodeobra-desayuno + wa_manodeobra-almuerzo.
*        ELSEIF lv_vhs < 10.
*          lv_w = wa_manodeobra-desayuno + wa_manodeobra-almuerzo + wa_manodeobra-cena_comida.
*        ELSE.
*          lv_w = lv_aj + wa_manodeobra-desayuno + wa_manodeobra-almuerzo + wa_manodeobra-cena_comida.
*        ENDIF.
*        lv_x = lv_w * ( 1 + lv_valor_t / 100 ) ** ( lv_valor_p - 1 ).
*      ELSE.
*        CLEAR: lv_w, lv_x.
*      ENDIF.

      IF lv_cant EQ 1.
        lv_comision1 = lw_comision-comision1.
      ELSE.
        CLEAR lv_comision1.
      ENDIF.

      lv_prepago1 = lv_av + lv_rt + lv_p + lv_x + lv_comision1.
      ADD lv_prepago1 TO lv_prepago1_acum.

      IF wa_screen1-uso_inicial IS INITIAL AND wa_screen1-equipo = c_agricola AND lv_cant = 1.
        lv_prepago1_acum = ( lv_prepago1_acum * 2 ) - lv_comision1.
      ENDIF.

*     Guardo Intervalos
      IF lv_cant EQ 1 AND wa_screen1-equipo EQ c_agricola.
        lw_intervalos-intervalo = lv_intervalo_100.
        SHIFT lw_intervalos-intervalo LEFT DELETING LEADING '0'.
        lw_intervalos-prepago1  = lv_prepago1.
        lw_intervalos-prepago2  = lv_prepago1.
        lw_intervalos-prepago3  = lv_prepago1.
        APPEND lw_intervalos TO gt_intervalos.
      ENDIF.

      lw_intervalos-intervalo = lv_intervalo.
      IF wa_screen1-equipo EQ c_agricola.
        lw_intervalos-prepago1  = lv_prepago1 - lv_comision1.
      ELSE.
        lw_intervalos-prepago1  = lv_prepago1.
      ENDIF.
      APPEND lw_intervalos TO gt_intervalos.

    ENDDO.



***************************************
*  COLUMNA 2 y 3
***************************************

    CLEAR: lv_cant, lv_ak, lv_perio_mes2, lv_perio_mes3.

    DO.

      ADD 1 TO lv_cant.

      lv_intervalo = lv_interv * lv_cant.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = lv_intervalo
        IMPORTING
          output = lv_intervalo.

      IF lw_contrato-valor3 < ( lv_cant * lv_interv ).
        EXIT.
      ENDIF.

      "DURACION EN MES
      IF ( ( lv_interv * lv_cant ) - wa_screen1-uso_inicial <= 0 ).
        lv_perio_mes3 = 1.
      ELSE.
        lv_perio_mes3 = ( ( ( lv_interv * lv_cant ) - wa_screen1-uso_inicial )
                                 / wa_screen1-uso ) * 12.
      ENDIF.
      COMPUTE lv_perio_mes3 = trunc( lv_perio_mes3 ).

*      CLEAR: lv_hora_fin, lv_cantidad.
*      IF wa_screen1-equipo EQ c_camiones.
*        LOOP AT gt_tempario INTO lw_tempario.
*          IF ( lv_interv * lv_cant ) MOD lw_tempario-base_mineral = 0.
*            lv_cantidad = lw_tempario-cantidad.
*            ADD lv_cantidad TO lv_hora_fin.
*          ENDIF.
*        ENDLOOP.
*      ELSE.
*        READ TABLE gt_tempario INTO lw_tempario
*          WITH KEY base_mineral = lv_intervalo.
*        IF sy-subrc = 0.
*          lv_hora_fin = lw_tempario-cantidad.
*        ENDIF.
*      ENDIF.
*
*      "AK
*      IF NOT wa_screen1-uso IS INITIAL AND
*         ( lv_interv * lv_cant < wa_screen1-uso_iniciali ).
*        CLEAR: lv_ak.
*      ELSE.
*        CONCATENATE 'IMPORTE_' wa_screen1-lugar INTO lv_mano_obra.
*        lv_structure_name = 'WA_MANODEOBRA'.
*        ASSIGN (lv_structure_name) TO <fs_struc>.
*        ASSIGN COMPONENT lv_mano_obra OF STRUCTURE <fs_struc> TO <f_field>.
*        lv_ak = <f_field> * lv_hora_fin.
*      ENDIF.
*
*      CLEAR: lv_long, lv_valor_d, lv_ar.
*
*      lv_long = strlen( lv_dto4000 ) - 1.
*
*      WRITE lv_dto4000(lv_long) TO lv_valor_d.
*
*      lv_ar = lv_ak * ( 1 - lv_valor_d / 100 ).
*
*      CLEAR lv_aa.
*      IF lv_hora_fin EQ 0.
*        lv_aa = 0.
*      ELSE.
*        IF wa_screen1-diferencial EQ '130GL'.
*          lv_aa = 10000.
*        ELSE.
*          lv_aa = lv_ar * '0.06'.
*        ENDIF.
*      ENDIF.
*
      CLEAR lv_valor_p.
      "Calcula período
      IF NOT wa_screen1-uso_inicial IS INITIAL.
        lv_aux = ( lv_interv * lv_cant ) - wa_screen1-uso_inicial.
        IF lv_aux <= 0.
          lv_valor_p = 1.
        ELSE.
          lv_valor_p = ( lv_interv * lv_cant - wa_screen1-uso_inicial ) /
                       wa_screen1-uso + 1.
          IF ( lv_interv * lv_cant - wa_screen1-uso_inicial ) MOD
                                             wa_screen1-uso EQ 0.
            lv_valor_p = lv_valor_p - 1.
          ENDIF.
        ENDIF.
      ELSE.
        lv_valor_p = ( lv_interv * lv_cant - wa_screen1-uso_inicial ) /
              wa_screen1-uso .
        IF lv_interv * lv_cant MOD wa_screen1-uso NE 0.
          lv_valor_p = lv_valor_p + 1.
        ENDIF.
      ENDIF.

      COMPUTE lv_valor_p = trunc( lv_valor_p ).
*
*      lv_ae  = lv_aa * ( 1 + lv_valor_t / 100 ) ** ( lv_valor_p - 1 ).
*      lv_as  = lv_ar * ( 1 + lv_valor_t / 100 ) ** ( lv_valor_p - 1 ).
*      lv_rae = lv_ae.
*      lv_ras = lv_as.
*      lv_ax  = lv_ras + lv_rae.
*
      CLEAR: lv_r, lv_t, lv_rt.
*
*      "Si es terreno y se seleccionó el CHECK de MATERIALES AJUST
*      IF wa_screen1-lugar(2) EQ 'TE'.
*        IF NOT v_rb_ajust IS INITIAL.
*          lv_ac = lv_aa * ( 1 + lv_valor_t / 100 ) ** ( lv_valor_p - 1 ).
*          lv_ac_ajust = lv_ac.
*        ELSE.
*          CLEAR: lv_ac, lv_ac_ajust.
*        ENDIF.
*      ELSE.
*        "Si es Taller siempre se toma en cuenta
*        lv_ac = lv_aa * ( 1 + lv_valor_t / 100 ) ** ( lv_valor_p - 1 ).
*        lv_ac_ajust = lv_ac.
*      ENDIF.


      "Muestra de Aceite
      IF NOT wa_screen1-uso_inicial IS INITIAL AND
             ( lv_interv * lv_cant ) < wa_screen1-uso_iniciali.
        lv_r = 0.
      ELSE.
        LOOP AT lt_aceite INTO lw_aceite.
          IF lw_aceite-intervalo_mine NE 0.
            IF ( lv_interv * lv_cant ) MOD lw_aceite-intervalo_mine = 0.
              READ TABLE gt_servicios INTO lw_servicios
                WITH KEY matnr = lw_aceite-matnr.
              IF sy-subrc EQ 0.
                lv_r = lw_aceite-cantidad * lw_servicios-importe + lv_r.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDIF.

      lv_t  = lv_r * ( 1 + lv_valor_t  / 100 ) ** ( lv_valor_p - 1 ).
      lv_rt = lv_t.

      "Repuestos
      CLEAR: lv_j, lv_rep_ajust, lv_n_ajust, lv_l,
             lv_lub_ajust, lv_ao_ajust, lv_p.

      IF NOT wa_screen1-uso_inicial IS INITIAL AND
               ( lv_interv * lv_cant ) < wa_screen1-uso_iniciali.
        lv_j = 0.
      ELSE.
        LOOP AT lt_repuesto INTO lw_repuesto.
          IF lw_repuesto-intervalo_mine NE 0.
            IF ( lv_interv * lv_cant ) MOD lw_repuesto-intervalo_mine = 0.
              READ TABLE gt_repuestos INTO wa_repuestos
                WITH KEY matnr = lw_repuesto-matnr.
              IF sy-subrc = 0.
                lv_j = lw_repuesto-cantidad * wa_repuestos-total + lv_j.
              ELSE.
                READ TABLE gt_implubri INTO wa_implubri
                  WITH KEY matnr = lw_repuesto-matnr.
                IF sy-subrc = 0.
                  lv_j = lw_repuesto-cantidad * wa_implubri-kbetr + lv_j.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDIF.

      CLEAR: lv_long, lv_valor_tr, lv_rep_ajust, lv_lub_ajust,
             lv_l, lv_p, lv_w, lv_x.

      "lv_tasa_rep tendrá 0% o el porcentaje levantado de la tabla
      IF lv_tasa_rep(1) NE '0'.
        lv_long = strlen( lv_tasa_rep ) - 1.
        WRITE lv_tasa_rep(lv_long) TO lv_valor_tr.
      ENDIF.
      lv_rep_ajust = lv_j * ( 1 + lv_valor_tr / 100 ) ** ( lv_valor_p - 1 ).

      lv_n_ajust = lv_rep_ajust.

      CLEAR: lv_l.
      "Lubricantes
      IF NOT wa_screen1-uso_inicial IS INITIAL AND
         ( lv_interv * lv_cant ) < wa_screen1-uso_iniciali.
        lv_l = 0.
      ELSE.
        LOOP AT lt_lubricante INTO lw_lubricante.
          IF lw_lubricante-intervalo_mine NE 0.
            IF ( lv_interv * lv_cant ) MOD lw_lubricante-intervalo_mine = 0.
              READ TABLE gt_implubri INTO wa_implubri
                WITH KEY matnr = lw_lubricante-matnr.
              IF sy-subrc = 0.
                lv_l = lw_lubricante-cantidad * wa_implubri-kbetr + lv_l.
              ELSE.
                READ TABLE gt_repuestos INTO wa_repuestos
                  WITH KEY matnr = lw_lubricante-matnr.
                IF sy-subrc = 0.
                  lv_l = lw_lubricante-cantidad * wa_repuestos-total + lv_l.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDIF.

      CLEAR: lv_lub_ajust, lv_ao_ajust.

      "lv_tasa_lub tendrá 0% o el porcentaje levantado de la tabla
      IF lv_tasa_lub(1) NE '0'.
        lv_long = strlen( lv_tasa_lub ) - 1.
        WRITE lv_tasa_lub(lv_long) TO lv_valor_lu.
      ENDIF.
      lv_lub_ajust = lv_l * ( 1 + lv_valor_lu  / 100 ) ** ( lv_valor_p - 1 ).

      lv_ao_ajust = lv_lub_ajust.

      lv_p = lv_n_ajust + lv_ao_ajust. "Repuestos + Lubricantes

*      IF v_km_terreno IS NOT INITIAL OR v_hs_terreno IS NOT INITIAL OR v_peajes IS NOT INITIAL.
*        lv_ai = ( lv_precio_km * v_km_terreno * 2 ).
*        lv_ah = ( lv_precio_hs * v_hs_terreno * 2 ).
*        lv_aj = ( lv_ai + lv_ah + v_peajes ) * ( 1 + lv_valor_t  / 100 ) ** ( lv_valor_p - 1 ).
*      ENDIF.
*
*      "Viaticos
*      IF NOT v_rb_viaticos IS INITIAL.
*        DATA(lv_vhs1) = lv_hora_fin + v_hs_terreno.
*        IF lv_vhs1 < 5.
*          lv_w = wa_manodeobra-desayuno + wa_manodeobra-almuerzo.
*        ELSEIF lv_vhs1 < 10.
*          lv_w = wa_manodeobra-desayuno + wa_manodeobra-almuerzo + wa_manodeobra-cena_comida.
*        ELSE.
*          lv_w = lv_aj + wa_manodeobra-desayuno + wa_manodeobra-almuerzo + wa_manodeobra-cena_comida.
*        ENDIF.
*        "Columna X
*        lv_x = lv_w * ( 1 + lv_valor_t / 100 ) ** ( lv_valor_p - 1 ).
*      ELSE.
*        CLEAR: lv_w, lv_x.
*      ENDIF.

      IF lv_cant EQ 1.
        lv_comision2 = lw_comision-comision2.
        lv_comision3 = lw_comision-comision3.
      ELSE.
        CLEAR: lv_comision2, lv_comision3.
      ENDIF.

      IF ( lv_cant * lv_interv ) <= lw_contrato-valor2.
        lv_prepago2 = lv_ax + lv_rt + lv_p + lv_x + lv_comision2.
        lv_prepago3 = lv_ax + lv_rt + lv_p + lv_x + lv_comision3.

        ADD lv_prepago2 TO lv_prepago2_acum.
        ADD lv_prepago3 TO lv_prepago3_acum.
        lv_perio_mes2 = lv_perio_mes3.
      ELSE.
        lv_prepago3 = lv_ax + lv_rt + lv_p + lv_x.
        ADD lv_prepago3 TO lv_prepago3_acum.
      ENDIF.

      IF wa_screen1-uso_inicial IS INITIAL AND wa_screen1-equipo = c_agricola AND lv_cant = 1.
        lv_prepago2_acum = ( lv_prepago2_acum * 2 ) - lv_comision2.
        lv_prepago3_acum = ( lv_prepago3_acum * 2 ) - lv_comision3.
      ENDIF.


*     Guardo Intervalos
      READ TABLE gt_intervalos ASSIGNING <fs_intervalos>
        WITH KEY intervalo = lv_intervalo.
      IF sy-subrc = 0.
        IF ( lv_cant * lv_interv ) <= lw_contrato-valor2.
          <fs_intervalos>-prepago2  = lv_prepago2.
        ENDIF.
        <fs_intervalos>-prepago3  = lv_prepago3.
      ELSE.
        CLEAR lw_intervalos.
        lw_intervalos-intervalo = lv_intervalo.
        IF ( lv_cant * lv_interv ) <= lw_contrato-valor2.
          lw_intervalos-prepago2  = lv_prepago2.
        ENDIF.
        lw_intervalos-prepago3  = lv_prepago3.
        APPEND lw_intervalos TO gt_intervalos.
      ENDIF.

    ENDDO.




***************************************
*  COLUMNA 4
***************************************
    DATA: lv_at  TYPE wrbtr,
          lv_au  TYPE wrbtr,
          lv_ab  TYPE wrbtr,
          lv_af  TYPE wrbtr,
          lv_ay  TYPE wrbtr,
          lv_rau TYPE i,
          lv_raf TYPE i.

    CLEAR: lv_cant, lv_ak, lv_ab, lv_perio_mes4.

    DO.
      ADD 1 TO lv_cant.

      lv_intervalo = lv_interv * lv_cant.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = lv_intervalo
        IMPORTING
          output = lv_intervalo.

      IF lw_contrato-valor4 < ( lv_cant * lv_interv ).
        EXIT.
      ENDIF.

      "DURACION EN MES
      IF ( ( lv_interv * lv_cant ) - wa_screen1-uso_inicial <= 0 ).
        lv_perio_mes4 = 1.
      ELSE.
        lv_perio_mes4 = ( ( ( lv_interv * lv_cant ) - wa_screen1-uso_inicial )
                                / wa_screen1-uso ) * 12.
      ENDIF.
      COMPUTE lv_perio_mes4 = trunc( lv_perio_mes4 ).

*      CLEAR: lv_hora_fin, lv_cantidad.
*      IF wa_screen1-equipo EQ c_camiones.
*        LOOP AT gt_tempario INTO lw_tempario.
*          IF ( lv_interv * lv_cant ) MOD lw_tempario-base_mineral = 0.
*            lv_cantidad = lw_tempario-cantidad.
*            lv_hora_fin =  lv_cantidad + lv_hora_fin.
*          ENDIF.
*        ENDLOOP.
*      ELSE.
*        READ TABLE gt_tempario INTO lw_tempario
*          WITH KEY base_mineral = lv_intervalo.
*        IF sy-subrc = 0.
*          lv_hora_fin = lw_tempario-cantidad.
*        ENDIF.
*      ENDIF.
*
*      IF NOT wa_screen1-uso IS INITIAL AND ( lv_interv * lv_cant < wa_screen1-uso_iniciali ).
*        CLEAR: lv_ak.
*      ELSE.
*        CONCATENATE 'IMPORTE_' wa_screen1-lugar INTO lv_mano_obra.
*        CONDENSE lv_mano_obra NO-GAPS.
*        lv_structure_name = 'WA_MANODEOBRA'.
*        ASSIGN (lv_structure_name) TO <fs_struc>.
*        ASSIGN COMPONENT lv_mano_obra OF STRUCTURE <fs_struc> TO <f_field>.
*        lv_ak = <f_field> * lv_hora_fin.
*      ENDIF.
*
*      CLEAR: lv_long, lv_valor_d, lv_ar.
*
*      lv_long = strlen( lv_dtoultim ) - 1.
*
*      WRITE lv_dtoultim(lv_long) TO lv_valor_d.
*
*      lv_at = lv_ak * ( 1 - lv_valor_d / 100 ).
*
*      CLEAR lv_ab.
*      IF lv_hora_fin EQ 0.
*        lv_ab = 0.
*      ELSE.
*        IF wa_screen1-diferencial EQ '130GL'.
*          lv_ab = 10000.
*        ELSE.
*          lv_ab = lv_at * '0.06'.
*        ENDIF.
*      ENDIF.
*
      CLEAR lv_valor_p.
      "Calcula período
      IF NOT wa_screen1-uso_inicial IS INITIAL.
        lv_aux = ( lv_interv * lv_cant ) - wa_screen1-uso_inicial.
        IF lv_aux <= 0.
          lv_valor_p = 1.
        ELSE.
          lv_valor_p = ( lv_interv * lv_cant - wa_screen1-uso_inicial ) / wa_screen1-uso + 1.
          IF ( lv_interv * lv_cant - wa_screen1-uso_inicial ) MOD wa_screen1-uso EQ 0.
            lv_valor_p = lv_valor_p - 1.
          ENDIF.
        ENDIF.
      ELSE.
        lv_valor_p = ( lv_interv * lv_cant - wa_screen1-uso_inicial ) / wa_screen1-uso .
        IF lv_interv * lv_cant MOD wa_screen1-uso NE 0.
          lv_valor_p = lv_valor_p + 1.
        ENDIF.
      ENDIF.

      COMPUTE lv_valor_p = trunc( lv_valor_p ).
*
*      lv_au  = lv_at * ( 1 + lv_valor_t / 100 ) ** ( lv_valor_p - 1 ).
*      lv_af  = lv_ab * ( 1 + lv_valor_t / 100 ) ** ( lv_valor_p - 1 ).
*      lv_rau = lv_au.
*      lv_raf = lv_af.
*      lv_ay  = lv_rau + lv_raf.
*
      CLEAR: lv_r, lv_t, lv_rt.
*
*      "Si es terreno y se seleccionó el CHECK de MATERIALES AJUST
*      IF wa_screen1-lugar(2) EQ 'TE'.
*        IF NOT v_rb_ajust IS INITIAL.
*          lv_ac = lv_ab * ( 1 + lv_valor_t / 100 ) ** ( lv_valor_p - 1 ).
*          lv_ac_ajust = lv_ac.
*        ELSE.
*          CLEAR: lv_ac, lv_ac_ajust.
*        ENDIF.
*      ELSE.
*        "Si es Taller siempre se toma en cuenta
*        lv_ac = lv_ab * ( 1 + lv_valor_t / 100 ) ** ( lv_valor_p - 1 ).
*        lv_ac_ajust = lv_ac.
*      ENDIF.

      "Muestra de Aceite
      IF NOT wa_screen1-uso_inicial IS INITIAL AND ( lv_interv * lv_cant ) < wa_screen1-uso_iniciali.
        lv_r = 0.
      ELSE.
        LOOP AT lt_aceite INTO lw_aceite.
          IF lw_aceite-intervalo_mine NE 0.
            IF ( lv_interv * lv_cant ) MOD lw_aceite-intervalo_mine = 0.
              READ TABLE gt_servicios INTO lw_servicios
                WITH KEY matnr = lw_aceite-matnr.
              IF sy-subrc EQ 0.
                lv_r = lw_aceite-cantidad * lw_servicios-importe + lv_r.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDIF.

      lv_t  = lv_r * ( 1 + lv_valor_t  / 100 ) ** ( lv_valor_p - 1 ).
      lv_rt = lv_t.

      "Repuestos
      CLEAR: lv_j, lv_rep_ajust, lv_n_ajust, lv_l,
             lv_lub_ajust, lv_ao_ajust, lv_p.

      IF NOT wa_screen1-uso_inicial IS INITIAL AND ( lv_interv * lv_cant ) < wa_screen1-uso_iniciali.
        lv_j = 0.
      ELSE.
        LOOP AT lt_repuesto INTO lw_repuesto.
          IF lw_repuesto-intervalo_mine NE 0.
            IF ( lv_interv * lv_cant ) MOD lw_repuesto-intervalo_mine = 0.
              READ TABLE gt_repuestos INTO wa_repuestos
                WITH KEY matnr = lw_repuesto-matnr.
              IF sy-subrc = 0.
                lv_j = lw_repuesto-cantidad * wa_repuestos-total + lv_j.
              ELSE.
                READ TABLE gt_implubri INTO wa_implubri
                  WITH KEY matnr = lw_repuesto-matnr.
                IF sy-subrc = 0.
                  lv_j = lw_repuesto-cantidad * wa_implubri-kbetr + lv_j.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDIF.

      CLEAR: lv_long, lv_valor_tr, lv_rep_ajust,
             lv_l, lv_p, lv_w, lv_x.

      "lv_tasa_rep tendrá 0% o el porcentaje levantado de la tabla
      IF lv_tasa_rep(1) NE '0'.
        lv_long = strlen( lv_tasa_rep ) - 1.
        WRITE lv_tasa_rep(lv_long) TO lv_valor_tr.
      ENDIF.
      lv_rep_ajust = lv_j * ( 1 + lv_valor_tr  / 100 ) ** ( lv_valor_p - 1 ).

      lv_n_ajust = lv_rep_ajust.


      "Lubricantes
      CLEAR: lv_l, lv_lub_ajust, lv_ao_ajust, lv_p.

      IF NOT wa_screen1-uso_inicial IS INITIAL AND
         ( lv_interv * lv_cant ) < wa_screen1-uso_iniciali.
        lv_l = 0.
      ELSE.
        LOOP AT lt_lubricante INTO lw_lubricante.
          IF lw_lubricante-intervalo_mine NE 0.
            IF ( lv_interv * lv_cant ) MOD lw_lubricante-intervalo_mine = 0.
              READ TABLE gt_implubri INTO wa_implubri
                WITH KEY matnr = lw_lubricante-matnr.
              IF sy-subrc = 0.
                lv_l = lw_lubricante-cantidad * wa_implubri-kbetr + lv_l.
              ELSE.
                READ TABLE gt_repuestos INTO wa_repuestos
                  WITH KEY matnr = lw_lubricante-matnr.
                IF sy-subrc = 0.
                  lv_l = lw_lubricante-cantidad * wa_repuestos-total + lv_l.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDIF.

      "lv_tasa_lub tendrá 0% o el porcentaje levantado de la tabla
      IF lv_tasa_lub(1) NE '0'.
        lv_long = strlen( lv_tasa_lub ) - 1.
        WRITE lv_tasa_lub(lv_long) TO lv_valor_lu.
      ENDIF.
      lv_lub_ajust = lv_l * ( 1 + lv_valor_lu  / 100 ) ** ( lv_valor_p - 1 ).

      lv_ao_ajust = lv_lub_ajust.

      lv_p = lv_n_ajust + lv_ao_ajust. "Repuestos + Lubricantes

*      IF v_km_terreno IS NOT INITIAL OR v_hs_terreno IS NOT INITIAL OR v_peajes IS NOT INITIAL.
*        lv_ai = ( lv_precio_km * v_km_terreno * 2 ).
*        lv_ah = ( lv_precio_hs * v_hs_terreno * 2 ).
*        lv_aj = ( lv_ai + lv_ah + v_peajes ) * ( 1 + lv_valor_t  / 100 ) ** ( lv_valor_p - 1 ).
*      ENDIF.
*
*      "Viaticos
*      IF NOT v_rb_viaticos IS INITIAL.
*        DATA(lv_vhs2) = lv_hora_fin + v_hs_terreno.
*        IF lv_vhs2 < 5.
*          lv_w = wa_manodeobra-desayuno + wa_manodeobra-almuerzo.
*        ELSEIF lv_vhs2 < 10.
*          lv_w = wa_manodeobra-desayuno + wa_manodeobra-almuerzo + wa_manodeobra-cena_comida.
*        ELSE.
*          lv_w = lv_aj + wa_manodeobra-desayuno + wa_manodeobra-almuerzo + wa_manodeobra-cena_comida.
*        ENDIF.
*        lv_x = lv_w * ( 1 + lv_valor_t / 100 ) ** ( lv_valor_p - 1 ).
*      ELSE.
*        CLEAR: lv_w, lv_x.
*      ENDIF.

      IF lv_cant EQ 1.
        lv_comision4 = lw_comision-comision4.
      ELSE.
        CLEAR lv_comision4.
      ENDIF.

      lv_prepago4 = lv_ay + + lv_rt + lv_p + lv_x + lv_comision4.
      ADD lv_prepago4 TO lv_prepago4_acum.

      IF wa_screen1-uso_inicial IS INITIAL AND wa_screen1-equipo = c_agricola AND lv_cant = 1.
        lv_prepago4_acum = ( lv_prepago4_acum * 2 ) - lv_comision4.
      ENDIF.


*     Guardo Intervalos
      READ TABLE gt_intervalos ASSIGNING <fs_intervalos>
        WITH KEY intervalo = lv_intervalo.
      IF sy-subrc = 0.
        <fs_intervalos>-prepago4  = lv_prepago4.
      ELSE.
        CLEAR lw_intervalos.
        lw_intervalos-intervalo = lv_intervalo.
        lw_intervalos-prepago4  = lv_prepago4.
        APPEND lw_intervalos TO gt_intervalos.
      ENDIF.

    ENDDO.



***************************************
*   PROCESO FINAL
***************************************
    READ TABLE gt_pauta_save  INTO DATA(lw_pauta_s) INDEX 1.

    SELECT SINGLE name1, stras, adrnr
      FROM kna1
      INTO @DATA(lw_kna1)
     WHERE kunnr = @wa_screen1-kunnr.

    IF sy-subrc = 0.
      SELECT SINGLE smtp_addr
        FROM adr6
        INTO @DATA(lv_smtp_addr)
       WHERE addrnumber = @lw_kna1-adrnr.
    ENDIF.

    IF v_modifica_coti = 'X'.
      lw_cotizacion-nro_cotiz = wa_screen1-nro_cotiz.
      SELECT SINGLE MAX( version )
        FROM ztcotizacion
        INTO @DATA(lv_version)
       WHERE nro_cotiz = @wa_screen1-nro_cotiz.
      IF sy-subrc = 0.
        lw_cotizacion-version = lv_version.
      ELSE.
        CLEAR lw_cotizacion-version.
      ENDIF.
    ELSE.
      SELECT SINGLE MAX( nro_cotiz )
        FROM ztcotizacion
        INTO @DATA(lv_nro_cotiz).
      lw_cotizacion-nro_cotiz = lv_nro_cotiz + 1.
    ENDIF.

    ADD 1 TO lw_cotizacion-version.

    READ TABLE gt_param INTO DATA(lw_desc_cli)
      WITH KEY  tipo = lc_desc_cli.

    READ TABLE gt_param INTO DATA(lw_desc_cli2)
      WITH KEY  tipo = lc_tasa_mensu.
    IF sy-subrc EQ 0.
      DATA(lv_valor1) = lw_desc_cli2-valor1.
*     Cuando el check IPC se encuentra seleccionado descuentos y tasas van en 0
      CLEAR lv_valor_tr.
      lv_long = strlen( lv_valor1 ) - 1.
      WRITE lv_valor1(lv_long) TO lv_tasa_mensu.
    ENDIF.


*   CASILLA DE AJUSTE de descuentos
    IF wa_screen1-chk_desc = 'X'.
      IF v_rb_dto$ = 'X'.
        lw_cotizacion-descuento_peso = wa_screen1-descuento_peso.
        lv_prepago1_acum = lv_prepago1_acum - lw_cotizacion-descuento_peso.
        lv_prepago2_acum = lv_prepago2_acum - lw_cotizacion-descuento_peso.
        lv_prepago3_acum = lv_prepago3_acum - lw_cotizacion-descuento_peso.
        lv_prepago4_acum = lv_prepago4_acum - lw_cotizacion-descuento_peso.
      ELSE.
        lw_cotizacion-descuento_porc = wa_screen1-descuento_porc.
        lv_prepago1_acum = lv_prepago1_acum * ( 1 - ( lw_cotizacion-descuento_porc / 100 ) ).
        lv_prepago2_acum = lv_prepago2_acum * ( 1 - ( lw_cotizacion-descuento_porc / 100 ) ).
        lv_prepago3_acum = lv_prepago3_acum * ( 1 - ( lw_cotizacion-descuento_porc / 100 ) ).
        lv_prepago4_acum = lv_prepago4_acum * ( 1 - ( lw_cotizacion-descuento_porc / 100 ) ).
      ENDIF.
    ENDIF.

*   TELEMETRIA
    IF wa_screen1-chk_tel = 'X'.
      DATA: lv_telemetria1 TYPE zed_precio,
            lv_telemetria2 TYPE zed_precio,
            lv_telemetria3 TYPE zed_precio,
            lv_telemetria4 TYPE zed_precio.

      lw_cotizacion-chk_telemetria = wa_screen1-chk_tel.

      CASE wa_screen1-equipo.

        WHEN 'CAMIONES'.

          IF wa_screen1-marca = 'MACK'.
            IF wa_screen1-uso_inicial IS INITIAL.
              READ TABLE gt_param INTO lw_param
                WITH KEY tipo = 'TELEMETRIA_MACK_NEW'.
              IF sy-subrc = 0.
                lv_prepago1_acum = lv_prepago1_acum + lw_param-valor1.
                lv_prepago2_acum = lv_prepago2_acum + lw_param-valor2.
                lv_prepago3_acum = lv_prepago3_acum + lw_param-valor3.
                lv_prepago4_acum = lv_prepago4_acum + lw_param-valor4.
              ENDIF.

            ELSE.
              READ TABLE gt_param INTO lw_param
                WITH KEY tipo = 'TELEMETRIA_MACK_OLD'.
              IF sy-subrc = 0.
                lv_prepago1_acum = lv_prepago1_acum + lw_param-valor1.
                lv_prepago2_acum = lv_prepago2_acum + lw_param-valor2.
                lv_prepago3_acum = lv_prepago3_acum + lw_param-valor3.
                lv_prepago4_acum = lv_prepago4_acum + lw_param-valor4.
              ENDIF.

            ENDIF.

          ELSEIF wa_screen1-marca = 'RENAULT'.
            IF wa_screen1-uso_inicial IS INITIAL.
              READ TABLE gt_param INTO lw_param
                WITH KEY tipo = 'TELEMETRIA_RENAULT_NEW'.
              IF sy-subrc = 0.
                lv_prepago1_acum = lv_prepago1_acum + lw_param-valor1.
                lv_prepago2_acum = lv_prepago2_acum + lw_param-valor2.
                lv_prepago3_acum = lv_prepago3_acum + lw_param-valor3.
                lv_prepago4_acum = lv_prepago4_acum + lw_param-valor4.
              ENDIF.

            ELSE.
              READ TABLE gt_param INTO lw_param
                WITH KEY tipo = 'TELEMETRIA_RENAULT_OLD'.
              IF sy-subrc = 0.
                lv_prepago1_acum = lv_prepago1_acum + lw_param-valor1.
                lv_prepago2_acum = lv_prepago2_acum + lw_param-valor2.
                lv_prepago3_acum = lv_prepago3_acum + lw_param-valor3.
                lv_prepago4_acum = lv_prepago4_acum + lw_param-valor4.
              ENDIF.

            ENDIF.

          ENDIF.
        WHEN 'MAQUINARIA'.
          READ TABLE gt_param INTO lw_param
            WITH KEY tipo = 'TELEMETRIA_MAQUINARIA'.
          IF sy-subrc = 0.
            lv_prepago1_acum = lv_prepago1_acum + lw_param-valor1.
            lv_prepago2_acum = lv_prepago2_acum + lw_param-valor2.
            lv_prepago3_acum = lv_prepago3_acum + lw_param-valor3.
            lv_prepago4_acum = lv_prepago4_acum + lw_param-valor4.
          ENDIF.

        WHEN 'AGRICOLA'.
          READ TABLE gt_param INTO lw_param
            WITH KEY tipo = 'TELEMETRIA_AGRICOLA'.
          IF sy-subrc = 0.
            lv_prepago1_acum = lv_prepago1_acum + lw_param-valor1.
            lv_prepago2_acum = lv_prepago2_acum + lw_param-valor2.
            lv_prepago3_acum = lv_prepago3_acum + lw_param-valor3.
            lv_prepago4_acum = lv_prepago4_acum + lw_param-valor4.
          ENDIF.

      ENDCASE.

      lw_cotizacion-telemetria1 = lw_param-valor1.
      lw_cotizacion-telemetria1 = lw_param-valor2.
      lw_cotizacion-telemetria1 = lw_param-valor3.
      lw_cotizacion-telemetria1 = lw_param-valor4.

    ENDIF.

    IF wa_screen1-modalidad EQ 'HORAS'.
      lv_coef_km = 1.
    ELSE.
      lv_coef_km = 1000.
    ENDIF.

*   CALCULO EN CUOTA Y POR USO (AJUSTADO O NO)

    REPLACE ',' WITH '.' INTO lv_tasa_mensu.
    lv_tasa_m = lv_tasa_mensu / 100.

    IF wa_screen1-chk_ipc IS INITIAL. "CALCULO CUOTA

      lv_cuota_t1 = ( lv_prepago1_acum * lv_tasa_m ) / ( 1 - ( ( 1 + lv_tasa_m ) ** ( - lv_perio_mes1 ) ) ).
*      lv_cuota_t1 = lv_prepago1_acum / lv_perio_mes1.
      WRITE lv_cuota_t1 TO lw_cotizacion-cuota1.

      lv_cuota_t2 = ( lv_prepago2_acum * lv_tasa_m ) / ( 1 - ( ( 1 + lv_tasa_m ) ** ( - lv_perio_mes2 ) ) ).
*      lv_cuota_t2 = lv_prepago2_acum / lv_perio_mes2.
      WRITE lv_cuota_t2 TO lw_cotizacion-cuota2.

      lv_cuota_t3 = ( lv_prepago3_acum * lv_tasa_m ) / ( 1 - ( ( 1 + lv_tasa_m ) ** ( - lv_perio_mes3 ) ) ).
*      lv_cuota_t3 = lv_prepago3_acum / lv_perio_mes3.
      WRITE lv_cuota_t3 TO lw_cotizacion-cuota3.

      lv_cuota_t4 = ( lv_prepago4_acum * lv_tasa_m ) / ( 1 - ( ( 1 + lv_tasa_m ) ** ( - lv_perio_mes4 ) ) ).
*      lv_cuota_t4 = lv_prepago4_acum / lv_perio_mes4.
      WRITE lv_cuota_t4 TO lw_cotizacion-cuota4.

      IF wa_screen1-chk_poruso = 'X'. "CALCULO POR USO KM/HS

        lv_valor_hs1 = lv_cuota_t1 * lv_0coma1 / lv_coef_km.
        WRITE lv_valor_hs1 TO lw_cotizacion-val_kmhs1.

        lv_valor_hs2 = lv_cuota_t2 * lv_0coma1 / lv_coef_km.
        WRITE lv_valor_hs2 TO lw_cotizacion-val_kmhs2.

        lv_valor_hs3 = lv_cuota_t3 * lv_0coma1 / lv_coef_km.
        WRITE lv_valor_hs3 TO lw_cotizacion-val_kmhs3.

        lv_valor_hs4 = lv_cuota_t4 * lv_0coma1 / lv_coef_km.
        WRITE lv_valor_hs4 TO lw_cotizacion-val_kmhs4.

      ENDIF.

    ELSE. "CALCULO AJUSTADO IPC

      lv_cuota_t1 = lv_prepago1_acum *
         ( lv_tasa_m * ( 1  + lv_tasa_m ) ** lv_perio_mes1 )  /
         ( ( 1 + lv_tasa_m ) ** lv_perio_mes1 - 1 ).
      WRITE lv_cuota_t1 TO lw_cotizacion-cuota_ajus1.

      lv_cuota_t2 =  lv_prepago2_acum *
         ( lv_tasa_m * ( 1  + lv_tasa_m ) ** lv_perio_mes2 )  /
         ( ( 1 + lv_tasa_m ) ** lv_perio_mes2 - 1 ).
      WRITE lv_cuota_t2 TO lw_cotizacion-cuota_ajus2.

      lv_cuota_t3 =   lv_prepago3_acum *
         ( lv_tasa_m * ( 1  + lv_tasa_m ) ** lv_perio_mes3 )  /
         ( ( 1 + lv_tasa_m ) ** lv_perio_mes3 - 1 ).
      WRITE lv_cuota_t3 TO lw_cotizacion-cuota_ajus3.

      lv_cuota_t4 = lv_prepago4_acum *
         ( lv_tasa_m * ( 1  + lv_tasa_m ) ** lv_perio_mes4 )  /
         ( ( 1 + lv_tasa_m ) ** lv_perio_mes4 - 1 ).
      WRITE lv_cuota_t4 TO lw_cotizacion-cuota_ajus4.

      IF wa_screen1-chk_poruso = 'X'. "CALCULO POR USO KM/HS AJUSTADO

        lv_valor_hs1 = lv_cuota_t1 * lv_0coma1 / lv_coef_km.
        WRITE lv_valor_hs1 TO lw_cotizacion-val_kmhs_ajus1.

        lv_valor_hs2 = lv_cuota_t2 * lv_0coma1 / lv_coef_km.
        WRITE lv_valor_hs2 TO lw_cotizacion-val_kmhs_ajus2.

        lv_valor_hs3 = lv_cuota_t3 * lv_0coma1 / lv_coef_km.
        WRITE lv_valor_hs3 TO lw_cotizacion-val_kmhs_ajus3.

        lv_valor_hs4 = lv_cuota_t4 * lv_0coma1 / lv_coef_km.
        WRITE lv_valor_hs4 TO lw_cotizacion-val_kmhs_ajus4.

      ENDIF.

    ENDIF.

    IF wa_screen1-chk_poruso = 'X'.
      lw_cotizacion-chk_uso = 'X'.
      IF wa_screen1-chk_ipc = 'X'.
        lw_cotizacion-chk_uso_ajus = 'X'.
      ENDIF.
    ENDIF.
    IF wa_screen1-chk_cuota = 'X'.
      lw_cotizacion-chk_cuota = 'X'.
      IF wa_screen1-chk_ipc = 'X'.
        lw_cotizacion-chk_cuota_ajus = 'X'.
      ENDIF.
    ENDIF.


    lw_cotizacion-cliente      = wa_screen1-kunnr.
    lw_cotizacion-fecha        = sy-datum.
    lw_cotizacion-equipo       = wa_screen1-equipo.
    lw_cotizacion-marca        = wa_screen1-marca.
    lw_cotizacion-modelo       = wa_screen1-modelo.
    lw_cotizacion-modalidad    = wa_screen1-modalidad.
    lw_cotizacion-sucursal     = wa_screen1-sucursal.
    lw_cotizacion-hs_anu       = wa_screen1-uso.
    lw_cotizacion-hs_ini       = wa_screen1-uso_inicial.
    lw_cotizacion-lugar        = wa_screen1-lugar.
    lw_cotizacion-caja         = wa_screen1-caja.
    lw_cotizacion-diferencial  = wa_screen1-diferencial.
    lw_cotizacion-prepago1     = lv_prepago1_acum.
    lw_cotizacion-prepago2     = lv_prepago2_acum.
    lw_cotizacion-prepago3     = lv_prepago3_acum.
    lw_cotizacion-prepago4     = lv_prepago4_acum.
    lw_cotizacion-name1        = lw_kna1-name1.
    lw_cotizacion-direccion    = lw_kna1-stras.
    lw_cotizacion-mail         = lv_smtp_addr.
    lw_cotizacion-desc_client1 = lw_desc_cli-valor1.
    lw_cotizacion-desc_client2 = lw_desc_cli-valor2.
    lw_cotizacion-desc_client3 = lw_desc_cli-valor3.
    lw_cotizacion-desc_client4 = lw_desc_cli-valor4.
    lw_cotizacion-duracion1    = lv_perio_mes1.
    lw_cotizacion-duracion2    = lv_perio_mes2.
    lw_cotizacion-duracion3    = lv_perio_mes3.
    lw_cotizacion-duracion4    = lv_perio_mes4.
    lw_cotizacion-tasa_mensu   = lv_tasa_mensu.

    IF NOT v_trasla IS INITIAL.
      IF NOT v_reparac IS INITIAL.
        lw_cotizacion-traslado_repa = v_trasla.
        lw_cotizacion-reparac_salfa = v_reparac.
      ENDIF.
    ELSE.
      CLEAR: v_trasla,
             v_reparac.
    ENDIF.
    lw_cotizacion-contrato_valor1 = lw_contrato-valor1.
    lw_cotizacion-contrato_valor2 = lw_contrato-valor2.
    lw_cotizacion-contrato_valor3 = lw_contrato-valor3.
    lw_cotizacion-contrato_valor4 = lw_contrato-valor4.
    lw_cotizacion-ipc             = wa_screen1-chk_ipc.

    lw_cotizacion-chk_descuento  = wa_screen1-chk_desc.
    lw_cotizacion-descuento_peso = wa_screen1-descuento_peso.
    lw_cotizacion-descuento_porc = wa_screen1-descuento_porc.

    lw_cotizacion-chk_viaticos  = v_rb_viaticos.
    lw_cotizacion-traslado_km   = v_km_terreno.
    lw_cotizacion-traslado_hs   = v_hs_terreno.
    lw_cotizacion-peajes        = v_peajes.

    lw_cotizacion-comision1     = lw_comision-comision1.
    lw_cotizacion-comision2     = lw_comision-comision2.
    lw_cotizacion-comision3     = lw_comision-comision3.
    lw_cotizacion-comision4     = lw_comision-comision4.

    APPEND lw_cotizacion TO gt_cotizacion.

  ENDIF.  "Solo si intervalo tiene valor

ENDFORM.  "F_OBTENER_FORMULA


*&---------------------------------------------------------------------*
*&      Form  F_LEER_VALOR_DE_PANTALLA
*&---------------------------------------------------------------------*
FORM f_leer_valor_de_pantalla  USING    pv_field
                               CHANGING pv_fieldvalue.

  DATA: lt_fields TYPE TABLE OF dynpread.
  DATA: lw_fields TYPE dynpread.
  DATA: lv_dyname TYPE sy-repid.
  DATA: lv_dynumb TYPE sy-dynnr.

  CLEAR pv_fieldvalue.
  REFRESH lt_fields.
  lw_fields-fieldname = pv_field.
  APPEND lw_fields TO lt_fields.

  lv_dyname = sy-repid.
  lv_dynumb = sy-dynnr.

  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname     = lv_dyname
      dynumb     = lv_dynumb
    TABLES
      dynpfields = lt_fields
    EXCEPTIONS
      OTHERS     = 01.

  IF sy-subrc IS INITIAL.
    READ TABLE lt_fields INDEX 1 INTO lw_fields.
    IF sy-subrc EQ 0.
      pv_fieldvalue = lw_fields-fieldvalue.
    ENDIF.
  ENDIF.

ENDFORM.        "F_LEER_VALOR_DE_PANTALLA


*&---------------------------------------------------------------------*
*&      Form  F_GRISA_CAMPOS_ALV
*&---------------------------------------------------------------------*
FORM f_grisa_campos_alv.

  DATA: lw_pauta TYPE ty_pauta,
        lw_style TYPE lvc_s_styl.

  LOOP AT gt_pauta INTO lw_pauta.
*   CARGAR EN ORDEN ALFABÉTICO, YA QUE ES UNA TABLA SORTED
*   SINO DUMPEA
    REFRESH lw_pauta-field_style[].
    CLEAR lw_style.
    lw_style-fieldname = 'CANTIDAD'.
    lw_style-style     = cl_gui_alv_grid=>mc_style_disabled.
    APPEND lw_style TO lw_pauta-field_style.
    CLEAR lw_style.
    lw_style-fieldname = 'DESCRIPCION_MAT'.
    lw_style-style     = cl_gui_alv_grid=>mc_style_disabled.
    APPEND lw_style TO lw_pauta-field_style.
    CLEAR lw_style.
    lw_style-fieldname = 'INTERVALO_MINE'.
    lw_style-style     = cl_gui_alv_grid=>mc_style_disabled.
    APPEND lw_style TO lw_pauta-field_style.
    CLEAR lw_style.
    lw_style-fieldname = 'MATERIAL'.
    lw_style-style     = cl_gui_alv_grid=>mc_style_disabled.
    APPEND lw_style TO lw_pauta-field_style.
    CLEAR lw_style.
    lw_style-fieldname = 'MATNR'.
    lw_style-style     = cl_gui_alv_grid=>mc_style_disabled.
    APPEND lw_style TO lw_pauta-field_style.

    MODIFY gt_pauta FROM lw_pauta.

  ENDLOOP.

ENDFORM.          "F_GRISA_CAMPOS_ALV


*&---------------------------------------------------------------------*
*&      Form  F_CARGA_FIELDCAT
*&---------------------------------------------------------------------*
FORM f_carga_fieldcat .

  DATA: lw_fieldcat TYPE lvc_s_fcat,
        lv_col      TYPE lvc_colpos.

  CLEAR lv_col.

  REFRESH gt_fieldcat.

  CLEAR lw_fieldcat.
  ADD 1 TO lv_col.
  lw_fieldcat-tabname   = 'GT_PAUTA'.
  lw_fieldcat-fieldname = 'MODELO'.
  lw_fieldcat-scrtext_s = 'Modelo'.
  lw_fieldcat-scrtext_m = 'Modelo'.
  lw_fieldcat-scrtext_l = 'Modelo'.
  lw_fieldcat-col_pos   = lv_col.
  lw_fieldcat-key       = space.
  APPEND lw_fieldcat TO gt_fieldcat.

  CLEAR lw_fieldcat.
  ADD 1 TO lv_col.
  lw_fieldcat-tabname   = 'GT_PAUTA'.
  lw_fieldcat-fieldname = 'MODALIDAD'.
  lw_fieldcat-scrtext_s = 'Modalidad'.
  lw_fieldcat-scrtext_m = 'Modalidad'.
  lw_fieldcat-scrtext_l = 'Modalidad'.
  lw_fieldcat-col_pos   = lv_col.
  lw_fieldcat-key       = space.
  APPEND lw_fieldcat TO gt_fieldcat.

  CLEAR lw_fieldcat.
  ADD 1 TO lv_col.
  lw_fieldcat-tabname   = 'GT_PAUTA'.
  lw_fieldcat-fieldname = 'LUGAR'.
  lw_fieldcat-scrtext_s = 'Lugar'.
  lw_fieldcat-scrtext_m = 'Lugar'.
  lw_fieldcat-scrtext_l = 'Lugar'.
  lw_fieldcat-col_pos   = lv_col.
  lw_fieldcat-key       = space.
  APPEND lw_fieldcat TO gt_fieldcat.

  CLEAR lw_fieldcat.
  ADD 1 TO lv_col.
  lw_fieldcat-tabname   = 'GT_PAUTA'.
  lw_fieldcat-fieldname = 'CAJA'.
  lw_fieldcat-scrtext_s = 'Caja'.
  lw_fieldcat-scrtext_m = 'Caja'.
  lw_fieldcat-scrtext_l = 'Caja'.
  lw_fieldcat-col_pos   = lv_col.
  lw_fieldcat-key       = space.
  APPEND lw_fieldcat TO gt_fieldcat.

  CLEAR lw_fieldcat.
  ADD 1 TO lv_col.
  lw_fieldcat-tabname   = 'GT_PAUTA'.
  lw_fieldcat-fieldname = 'DIFERENCIAL'.
  lw_fieldcat-scrtext_s = 'Diferencial'.
  lw_fieldcat-scrtext_m = 'Diferencial'.
  lw_fieldcat-scrtext_l = 'Diferencial'.
  lw_fieldcat-col_pos   = lv_col.
  lw_fieldcat-key       = space.
  APPEND lw_fieldcat TO gt_fieldcat.

  CLEAR lw_fieldcat.
  ADD 1 TO lv_col.
  lw_fieldcat-tabname   = 'GT_PAUTA'.
  lw_fieldcat-fieldname = 'MATERIAL'.
  lw_fieldcat-scrtext_s = 'Clasif.'.
  lw_fieldcat-scrtext_m = 'Clasificación'.
  lw_fieldcat-scrtext_l = 'Clasificación'.
  lw_fieldcat-col_pos   = lv_col.
  lw_fieldcat-key       = space.
  APPEND lw_fieldcat TO gt_fieldcat.

  CLEAR lw_fieldcat.
  ADD 1 TO lv_col.
  lw_fieldcat-tabname   = 'GT_PAUTA'.
  lw_fieldcat-fieldname = 'NRO_PARTE'.
  lw_fieldcat-scrtext_s = 'Nro. Parte'.
  lw_fieldcat-scrtext_m = 'Nro. Parte'.
  lw_fieldcat-scrtext_l = 'Nro. Parte'.
  lw_fieldcat-col_pos   = lv_col.
  lw_fieldcat-key       = space.
  lw_fieldcat-no_out    = 'X'.
  APPEND lw_fieldcat TO gt_fieldcat.

  CLEAR lw_fieldcat.
  ADD 1 TO lv_col.
  lw_fieldcat-tabname   = 'GT_PAUTA'.
  lw_fieldcat-fieldname = 'MATNR'.
  lw_fieldcat-scrtext_s = 'Nro.SAP'.
  lw_fieldcat-scrtext_m = 'Nro.SAP'.
  lw_fieldcat-scrtext_l = 'Nro.SAP'.
  lw_fieldcat-col_pos   = lv_col.
  lw_fieldcat-key       = space.
  APPEND lw_fieldcat TO gt_fieldcat.

  CLEAR lw_fieldcat.
  ADD 1 TO lv_col.
  lw_fieldcat-tabname   = 'GT_PAUTA'.
  lw_fieldcat-fieldname = 'DESCRIPCION_MAT'.
  lw_fieldcat-scrtext_s = 'Descripción'.
  lw_fieldcat-scrtext_m = 'Descripción'.
  lw_fieldcat-scrtext_l = 'Descripción'.
  lw_fieldcat-col_pos   = lv_col.
  lw_fieldcat-key       = space.
  APPEND lw_fieldcat TO gt_fieldcat.

  CLEAR lw_fieldcat.
  ADD 1 TO lv_col.
  lw_fieldcat-tabname   = 'GT_PAUTA'.
  lw_fieldcat-fieldname = 'INTERVALO_SINT'.
  lw_fieldcat-scrtext_s = 'Sintet.'.
  lw_fieldcat-scrtext_m = 'Sintético'.
  lw_fieldcat-scrtext_l = 'Sintético'.
  lw_fieldcat-col_pos   = lv_col.
  lw_fieldcat-no_out    = 'X'.
  APPEND lw_fieldcat TO gt_fieldcat.

  CLEAR lw_fieldcat.
  ADD 1 TO lv_col.
  lw_fieldcat-tabname   = 'GT_PAUTA'.
  lw_fieldcat-fieldname = 'INTERVALO_MINE'.
  lw_fieldcat-scrtext_s = 'Mine.'.
  lw_fieldcat-scrtext_m = 'Mineral'.
  lw_fieldcat-scrtext_l = 'Mineral'.
  lw_fieldcat-col_pos   = lv_col.
  lw_fieldcat-edit      = 'X'.
  APPEND lw_fieldcat TO gt_fieldcat.

  CLEAR lw_fieldcat.
  ADD 1 TO lv_col.
  lw_fieldcat-tabname   = 'GT_PAUTA'.
  lw_fieldcat-fieldname = 'CANTIDAD'.
  lw_fieldcat-scrtext_s = 'Cant.'.
  lw_fieldcat-scrtext_m = 'Cantidad'.
  lw_fieldcat-scrtext_l = 'Cantidad'.
  lw_fieldcat-col_pos   = lv_col.
  lw_fieldcat-edit      = 'X'.
  APPEND lw_fieldcat TO gt_fieldcat.

ENDFORM.       "F_CARGA_FIELDCAT


*&---------------------------------------------------------------------*
*&      Form  F_LLAMA_ALV
*&---------------------------------------------------------------------*
FORM f_llama_alv .

  DATA: lw_layout      TYPE lvc_s_layo.

  lw_layout-cwidth_opt = 'X'.
  lw_layout-edit_mode  = 'X'.
  lw_layout-stylefname = 'FIELD_STYLE'.

  DATA : li_grid_setting TYPE lvc_s_glay.
  li_grid_setting-edt_cll_cb = 'X'.

  SORT gt_pauta BY material ASCENDING.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program       = sy-repid
      i_callback_user_command  = 'USER_COMMAND_ALV'
      i_callback_pf_status_set = 'PF_STATUS_ALV'
      i_callback_top_of_page   = 'F_TOP_OF_PAGE_ALV'
      i_structure_name         = 'GT_PAUTA'
      is_layout_lvc            = lw_layout
      it_fieldcat_lvc          = gt_fieldcat
      i_grid_settings          = li_grid_setting
      i_save                   = 'X'
    TABLES
      t_outtab                 = gt_pauta
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.

  v_active9000 = 'X'.

ENDFORM.       "F_LLAMA_ALV


*&---------------------------------------------------------------------*
*&      Form  F_TOP_OF_PAGE_ALV
*&---------------------------------------------------------------------*
FORM f_top_of_page_alv.

  DATA: lt_header TYPE slis_t_listheader,
        lw_header TYPE slis_listheader.

  REFRESH: lt_header.

  SELECT SINGLE name1
    FROM kna1
    INTO @DATA(gv_name1)
   WHERE kunnr = @wa_screen1-kunnr.

* Title
  CLEAR lw_header.

  lw_header-typ  = 'H'.
  CONCATENATE 'Cliente:' wa_screen1-kunnr '-' gv_name1
         INTO lw_header-info  SEPARATED BY space.
  APPEND lw_header TO lt_header.

  CLEAR lw_header.
  lw_header-typ  = 'S'.
  lw_header-key  = 'Nº PAUTA:'.
  IF v_numeropauta IS INITIAL.
    lw_header-info = 'Pauta aún no Creada'.
  ELSE.
    lw_header-info = v_numeropauta.
  ENDIF.
  APPEND lw_header TO lt_header.


  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_header
*     I_LOGO             =
*     I_END_OF_LIST_GRID =
*     I_ALV_FORM         =
    .

ENDFORM.        "F_TOP_OF_PAGE_ALV


*&--------------------------------------------------------------------*
*&      FORM USER_COMMAND_ALV  Process Call Back Events (Begin)
*&--------------------------------------------------------------------*
FORM user_command_alv USING pv_ucomm LIKE sy-ucomm
                         pw_selfield TYPE slis_selfield.

  DATA: lw_pauta     TYPE ty_pauta,
        lw_new_pauta TYPE ty_pauta.

  READ TABLE gt_pauta INTO lw_pauta INDEX pw_selfield-tabindex.
  CHECK sy-subrc = 0.

  CASE pv_ucomm.
    WHEN '&IC1' OR 'ANZG'. "Doble Click o Boton modificar
      PERFORM f_habilita_edit USING pw_selfield.
    WHEN 'DELE'.
      DELETE gt_pauta INDEX pw_selfield-tabindex.
    WHEN 'NEWL'.
      lw_new_pauta = lw_pauta.
      CLEAR: lw_new_pauta-material,
             lw_new_pauta-matnr,
             lw_new_pauta-descripcion_mat,
             lw_new_pauta-intervalo_mine,
             lw_new_pauta-cantidad.
      INSERT lw_new_pauta INTO gt_pauta INDEX pw_selfield-tabindex.
    WHEN 'SAVE'.
      PERFORM f_grisa_campos_alv.
    WHEN 'BACK'.

    WHEN 'CANCEL'.
      CLEAR: v_grisa9000, v_active9000.
      REFRESH gt_pauta.
      CLEAR wa_screen1.
      LEAVE TO SCREEN 0.
    WHEN 'EXIT'.
      LEAVE PROGRAM.

  ENDCASE.

  pw_selfield-refresh = 'X'.

ENDFORM.                    " USER_COMMAND_ALV


*&---------------------------------------------------------------------*
*       FORM SET_PF_STATUS_01
*&---------------------------------------------------------------------*
FORM pf_status_alv USING lt_cua_exclude TYPE slis_t_extab.

  SET PF-STATUS 'STATUS_ALV'.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_HABILITA_EDIT
*&---------------------------------------------------------------------*
FORM f_habilita_edit USING pw_selfield TYPE slis_selfield.

  DATA: lw_pauta      TYPE ty_pauta,
        lw_style      TYPE lvc_s_styl,
        lv_indexpauta TYPE sy-tabix,
        lv_indexstyle TYPE sy-tabix.

  READ TABLE gt_pauta INTO lw_pauta
    INDEX pw_selfield-tabindex.

  IF sy-subrc = 0.
    lv_indexpauta = sy-tabix.

    IF pw_selfield-fieldname = 'MATERIAL'.
      READ TABLE lw_pauta-field_style INTO lw_style
        WITH KEY fieldname = 'MATERIAL'.
      IF sy-subrc = 0 AND lw_pauta-material IS INITIAL.
        lv_indexstyle = sy-tabix.
        lw_style-style = cl_gui_alv_grid=>mc_style_enabled.
        MODIFY lw_pauta-field_style FROM lw_style
          INDEX lv_indexstyle.
      ENDIF.
    ENDIF.

    IF pw_selfield-fieldname = 'MATNR'.
      READ TABLE lw_pauta-field_style INTO lw_style
        WITH KEY fieldname = 'MATNR'.
      IF sy-subrc = 0 AND lw_pauta-matnr IS INITIAL.
        lv_indexstyle = sy-tabix.
        lw_style-style = cl_gui_alv_grid=>mc_style_enabled.
        MODIFY lw_pauta-field_style FROM lw_style
          INDEX lv_indexstyle.
      ENDIF.
    ENDIF.

    IF pw_selfield-fieldname = 'DESCRIPCION_MAT'.
      READ TABLE lw_pauta-field_style INTO lw_style
        WITH KEY fieldname = 'DESCRIPCION_MAT'.
      IF sy-subrc = 0 AND lw_pauta-descripcion_mat IS INITIAL.
        lv_indexstyle = sy-tabix.
        lw_style-style = cl_gui_alv_grid=>mc_style_enabled.
        MODIFY lw_pauta-field_style FROM lw_style
          INDEX lv_indexstyle.
      ENDIF.
    ENDIF.

    IF pw_selfield-fieldname = 'CANTIDAD'.
      READ TABLE lw_pauta-field_style INTO lw_style
        WITH KEY fieldname = 'CANTIDAD'.
      IF sy-subrc = 0.
        lv_indexstyle = sy-tabix.
        lw_style-style = cl_gui_alv_grid=>mc_style_enabled.
        MODIFY lw_pauta-field_style FROM lw_style
          INDEX lv_indexstyle.
      ENDIF.
    ENDIF.

    IF pw_selfield-fieldname = 'INTERVALO_MINE'.
      READ TABLE lw_pauta-field_style INTO lw_style
        WITH KEY fieldname = 'INTERVALO_MINE'.
      IF sy-subrc = 0.
        lv_indexstyle = sy-tabix.
        lw_style-style = cl_gui_alv_grid=>mc_style_enabled.
        MODIFY lw_pauta-field_style FROM lw_style
          INDEX lv_indexstyle.
      ENDIF.
    ENDIF.
    MODIFY gt_pauta FROM lw_pauta INDEX lv_indexpauta.
  ENDIF.

ENDFORM.      "F_HABILITA_EDIT


*&---------------------------------------------------------------------*
*&      Form  F_PROCESA_PAUTA
*&---------------------------------------------------------------------*
FORM f_procesa_pauta CHANGING v_numeropauta TYPE zed_numeropauta.

  DATA: lw_pauta_save TYPE ztpauta_save,
        lw_pauta      TYPE ty_pauta.

  IF gt_pauta IS NOT INITIAL.

    CLEAR v_numeropauta.
    SELECT SINGLE MAX( numero_pauta )
      FROM ztpauta_save
      INTO v_numeropauta
     WHERE cliente = wa_screen1-kunnr.

    ADD 1 TO v_numeropauta.
    CONDENSE v_numeropauta.

    LOOP AT gt_pauta INTO lw_pauta.
      CLEAR lw_pauta_save.
      lw_pauta_save-cliente         = wa_screen1-kunnr.
      lw_pauta_save-numero_pauta    = v_numeropauta.
      lw_pauta_save-fecha           = sy-datum.
      lw_pauta_save-equipo          = lw_pauta-equipo.
      lw_pauta_save-marca           = lw_pauta-marca.
      lw_pauta_save-modelo          = lw_pauta-modelo.
      lw_pauta_save-modalidad       = wa_screen1-modalidad.
      lw_pauta_save-lugar           = wa_screen1-lugar.
      lw_pauta_save-caja            = wa_screen1-caja.
      lw_pauta_save-diferencial     = wa_screen1-diferencial.
      lw_pauta_save-material        = lw_pauta-material.
      lw_pauta_save-matnr           = lw_pauta-matnr.
      lw_pauta_save-descripcion_mat = lw_pauta-descripcion_mat.
      lw_pauta_save-intervalo_mine  = lw_pauta-intervalo_mine.
      lw_pauta_save-cantidad        = lw_pauta-cantidad.
      lw_pauta_save-uso             = wa_screen1-uso.
      lw_pauta_save-uso_inicial     = wa_screen1-uso_inicial.
      lw_pauta_save-sucursal        = wa_screen1-sucursal.

      READ TABLE gt_repuestos INTO DATA(lw_repuestos)
      WITH KEY matnr = lw_pauta-matnr.
      IF sy-subrc = 0.
        lw_pauta_save-precio       = lw_repuestos-precio.
        lw_pauta_save-dto_aplicado = lw_repuestos-descuento.
        lw_pauta_save-precio_final = lw_repuestos-total.
      ELSE.

        READ TABLE gt_implubri INTO DATA(lw_implubri)
        WITH KEY matnr = lw_pauta-matnr.
        IF sy-subrc = 0.
          lw_pauta_save-precio       = lw_implubri-precio.
          lw_pauta_save-dto_aplicado = lw_implubri-descuento.
          lw_pauta_save-precio_final = lw_implubri-total.
        ELSE.

          READ TABLE gt_servicios INTO DATA(lw_servicios)
          WITH KEY matnr = lw_pauta-matnr.
          IF sy-subrc = 0.
*            lw_pauta_save-precio       = lw_servicios-precio.
*            lw_pauta_save-dto_aplicado = lw_repuestos-descuento.
            lw_pauta_save-precio_final = lw_servicios-importe.
          ENDIF.

        ENDIF.

      ENDIF.

      MODIFY ztpauta_save FROM lw_pauta_save.
    ENDLOOP.

    COMMIT WORK AND WAIT.

  ELSE.

    CALL FUNCTION 'POPUP_TO_INFORM'
      EXPORTING
        titel = 'Mensaje'
        txt1  = 'No hay datos cargados'
        txt2  = v_numeropauta.

  ENDIF.

  PERFORM %_list_return IN PROGRAM sapmssy0.

ENDFORM.   "F_PROCESA_PAUTA Boton Cotizar Screen 9000


*&---------------------------------------------------------------------*
*&      Form  F_CARGAR_PAUTA_VIEJA
*&---------------------------------------------------------------------*
FORM f_cargar_pauta_vieja .

  DATA: lw_pauta_save TYPE ztpauta_save,
        lw_pauta      TYPE ty_pauta.

  CLEAR wa_pauta_popup.

  PERFORM f_seleccionar_pauta_vieja.

  REFRESH: gt_pauta_save, gt_pauta.

  SELECT *
    FROM ztpauta_save
    INTO TABLE gt_pauta_save
   WHERE numero_pauta = wa_pauta_popup-numero_pauta
     AND cliente      = wa_pauta_popup-cliente
     AND fecha        = wa_pauta_popup-fecha
     AND equipo       = wa_pauta_popup-equipo
     AND marca        = wa_pauta_popup-marca
     AND modelo       = wa_pauta_popup-modelo.

  IF sy-subrc = 0.
    LOOP AT gt_pauta_save INTO lw_pauta_save.
      IF v_numeropauta IS INITIAL.
        MOVE lw_pauta_save-numero_pauta TO v_numeropauta.
      ENDIF.
      lw_pauta-equipo          = lw_pauta_save-equipo.
      lw_pauta-marca           = lw_pauta_save-marca.
      lw_pauta-modelo          = lw_pauta_save-modelo.
      lw_pauta-modalidad       = lw_pauta_save-modalidad.
      lw_pauta-lugar           = lw_pauta_save-lugar.
      lw_pauta-caja            = lw_pauta_save-caja.
      lw_pauta-diferencial     = lw_pauta_save-diferencial.
      lw_pauta-material        = lw_pauta_save-material.
      lw_pauta-matnr           = lw_pauta_save-matnr.
      lw_pauta-descripcion_mat = lw_pauta_save-descripcion_mat.
      lw_pauta-intervalo_mine  = lw_pauta_save-intervalo_mine.
      lw_pauta-cantidad        = lw_pauta_save-cantidad.
      APPEND lw_pauta TO gt_pauta.
    ENDLOOP.

    wa_screen1-equipo      = lw_pauta_save-equipo.
    wa_screen1-marca       = lw_pauta_save-marca.
    wa_screen1-kunnr       = lw_pauta_save-cliente.
    wa_screen1-modelo      = lw_pauta_save-modelo.
    wa_screen1-modalidad   = lw_pauta_save-modalidad.
    wa_screen1-lugar       = lw_pauta_save-lugar.
    wa_screen1-caja        = lw_pauta_save-caja.
    wa_screen1-diferencial = lw_pauta_save-diferencial.
    wa_screen1-uso         = lw_pauta_save-uso.
    wa_screen1-uso_inicial = lw_pauta_save-uso_inicial.
    IF lw_pauta_save-sucursal IS INITIAL.
      wa_screen1-sucursal    = 'X'.
    ELSE.
      wa_screen1-sucursal    = lw_pauta_save-sucursal.
    ENDIF.
  ELSE.
    CLEAR v_numeropauta.
  ENDIF.

  CALL SCREEN 9000.

ENDFORM.       "F_CARGAR_PAUTA_VIEJA


*&---------------------------------------------------------------------*
*&      Form  F_SELECCIONAR_PAUTA_VIEJA
*&---------------------------------------------------------------------*
FORM f_seleccionar_pauta_vieja .

  DEFINE m_fieldcat.
    ADD 1 TO ls_fieldcat-col_pos.
    ls_fieldcat-fieldname   = &1.
    ls_fieldcat-ref_tabname = &2.
    ls_fieldcat-outputlen   = &3.
    ls_fieldcat-seltext_l   = &4.
    APPEND ls_fieldcat TO lt_fieldcat.
  END-OF-DEFINITION.

  DATA: lt_popup    TYPE STANDARD TABLE OF ty_popup,
        lw_popup    TYPE ty_popup,
        lv_answer   TYPE c,
        lv_exit,
        ls_private  TYPE slis_data_caller_exit,
        ls_fieldcat TYPE slis_fieldcat_alv,
        lt_fieldcat TYPE slis_t_fieldcat_alv,
        lv_cuenta   TYPE i.

  SELECT DISTINCT numero_pauta
         cliente
         fecha
         equipo
         marca
         modelo
    FROM ztpauta_save
    INTO TABLE lt_popup.
*     WHERE cliente = wa_screen1-kunnr.

  m_fieldcat 'NUMERO_PAUTA'  'lt_popup' '10' 'N° Pauta'.
  m_fieldcat 'CLIENTE'       'lt_popup' '10' 'N° Cliente'.
  m_fieldcat 'FECHA'         'lt_popup' '10' 'Fecha'.
  m_fieldcat 'EQUIPO'        'lt_popup' '10' 'Equipo'.
  m_fieldcat 'MARCA'         'lt_popup' '10' 'Marca'.
  m_fieldcat 'MODELO'        'lt_popup' '10' 'Modelo'.

  IF lt_popup[] IS NOT INITIAL.

    DO.
      CALL FUNCTION 'REUSE_ALV_POPUP_TO_SELECT'
        EXPORTING
          i_selection           = 'X'
          i_zebra               = 'X'
          i_screen_start_column = 1
          i_screen_start_line   = 1
          i_screen_end_column   = 50
          i_screen_end_line     = 25
          it_fieldcat           = lt_fieldcat
          i_tabname             = 'LT_POPUP'
          i_checkbox_fieldname  = 'CHECKBOX'
          is_private            = ls_private
        IMPORTING
          e_exit                = lv_exit
        TABLES
          t_outtab              = lt_popup.

      CLEAR lv_cuenta.
      LOOP AT lt_popup INTO lw_popup WHERE checkbox = 'X'.
        ADD 1 TO lv_cuenta.
      ENDLOOP.

      IF lv_exit IS INITIAL.

        IF lv_cuenta > 1. "seleccionaron mas de 1 registro
          CALL FUNCTION 'POPUP_TO_INFORM'
            EXPORTING
              titel  = 'Cargar Pauta'
              txt1   = 'Se seleccionó mas de una Pauta.'
              txt2   = 'Por favor seleccione una sola'
            EXCEPTIONS
              OTHERS = 1.
        ELSE.
          LOOP AT lt_popup INTO lw_popup WHERE checkbox = 'X'.
            wa_pauta_popup-numero_pauta = lw_popup-numero_pauta.
            wa_pauta_popup-cliente      = lw_popup-cliente.
            wa_pauta_popup-fecha        = lw_popup-fecha.
            wa_pauta_popup-equipo       = lw_popup-equipo.
            wa_pauta_popup-marca        = lw_popup-marca.
            wa_pauta_popup-modelo       = lw_popup-modelo.
          ENDLOOP.
          EXIT.
        ENDIF.

      ELSE.
        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = 'Cargar Pauta'
            text_question         = 'No se seleccionó Pauta. Desea continuar?'
            text_button_1         = 'Volver'                       "(001)
            text_button_2         = 'Seleccionar'                  "(002)
            display_cancel_button = space
          IMPORTING
            answer                = lv_answer
          EXCEPTIONS
            text_not_found        = 1
            OTHERS                = 2.
        IF lv_answer = '1'.
          EXIT.
        ENDIF.
      ENDIF.

    ENDDO.

  ENDIF.

ENDFORM.        "F_SELECCIONAR_PAUTA_VIEJA


*&---------------------------------------------------------------------*
*&      Form  F_USER_HABILITADO_VER_PAUTA
*&---------------------------------------------------------------------*
FORM f_user_habilitado_ver_pauta .

  DATA: lw_range LIKE LINE OF r_user.

  SELECT usuario
    FROM ztuser_cotiza
    INTO TABLE @DATA(gt_user).

  IF sy-subrc = 0.
    SORT gt_user BY usuario.
    lw_range-sign   = 'I'.
    lw_range-option = 'EQ'.
    LOOP AT gt_user INTO DATA(lw_user).
      lw_range-low = lw_user-usuario.
      APPEND lw_range TO r_user.
    ENDLOOP.
  ENDIF.

ENDFORM.       "F_USER_HABILITADO_VER_PAUTA


*&---------------------------------------------------------------------*
*&      Form  F_MOSTRAR_ALV
*&---------------------------------------------------------------------*
FORM f_mostrar_alv
     CHANGING pt_i_alv              TYPE tyt_ztcotizacion
              pv_o_e_alvgrid        TYPE REF TO cl_gui_alv_grid
              pv_o_e_contenedor_alv TYPE REF TO cl_gui_custom_container.


  IF pv_o_e_alvgrid IS INITIAL.
    PERFORM f_crear_objeto_contenedor CHANGING pv_o_e_contenedor_alv.
    PERFORM f_crear_objeto_alv CHANGING  pv_o_e_alvgrid
                                         pv_o_e_contenedor_alv .
    SORT pt_i_alv.
    PERFORM f_crear_fieldcat USING pt_i_alv
                             CHANGING gt_fcat.
    PERFORM f_cargar_alv USING pv_o_e_alvgrid
                               gt_fcat
                               pt_i_alv.
  ELSE.
    PERFORM f_refrescar_alv USING pv_o_e_alvgrid.

  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_CREAR_OBJETO_CONTENEDOR
*&---------------------------------------------------------------------*
FORM f_crear_objeto_contenedor  CHANGING pv_o_e_contenedor_alv
  TYPE REF TO cl_gui_custom_container.

  CONSTANTS: lc_container_alv TYPE char20 VALUE 'CTRL_CUSTOM_ALV'.

  " ALV general.
  CREATE OBJECT pv_o_e_contenedor_alv
    EXPORTING
      container_name              = lc_container_alv
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      OTHERS                      = 6.
  IF sy-subrc IS INITIAL.
    " El sistema se encarga de la validación.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_CREAR_OBJETO_ALV
*&---------------------------------------------------------------------*
FORM f_crear_objeto_alv
     CHANGING pv_o_e_alvgrid        TYPE REF TO cl_gui_alv_grid
              pv_o_i_contenedor_alv TYPE REF TO cl_gui_custom_container.

  CREATE OBJECT pv_o_e_alvgrid
    EXPORTING
      i_parent          = pv_o_i_contenedor_alv
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.

  IF sy-subrc <> 0.
    " El sistema se encarga de la validación.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_CREAR_FIELDCAT
*&---------------------------------------------------------------------*
FORM f_crear_fieldcat   USING pt_i_alv TYPE tyt_ztcotizacion
                        CHANGING pt_e_fieldcat TYPE lvc_t_fcat.


  DATA: lw_fieldcat TYPE lvc_s_fcat.

  lw_fieldcat-fieldname = 'NRO_COTIZ'.
  lw_fieldcat-coltext   = TEXT-e03.
  lw_fieldcat-outputlen = 04.
  APPEND lw_fieldcat TO gt_fcat.
  CLEAR lw_fieldcat.

  lw_fieldcat-fieldname = 'CLIENTE'.
  lw_fieldcat-coltext   = TEXT-e04.
  lw_fieldcat-outputlen = 10.
  APPEND lw_fieldcat TO gt_fcat.
  CLEAR lw_fieldcat.

  lw_fieldcat-fieldname = 'NUMERO_PAUTA'.
  lw_fieldcat-coltext   = TEXT-e05.
  lw_fieldcat-outputlen = 10.
  APPEND lw_fieldcat TO gt_fcat.
  CLEAR lw_fieldcat.

  lw_fieldcat-fieldname = 'FECHA'.
  lw_fieldcat-coltext   = TEXT-e06.
  lw_fieldcat-outputlen = 10.
  APPEND lw_fieldcat TO gt_fcat.
  CLEAR lw_fieldcat.

  lw_fieldcat-fieldname = 'EQUIPO'.
  lw_fieldcat-coltext   = TEXT-e07.
  lw_fieldcat-outputlen = 15.
  APPEND lw_fieldcat TO gt_fcat.
  CLEAR lw_fieldcat.

  lw_fieldcat-fieldname = 'MARCA'.
  lw_fieldcat-coltext   = TEXT-e08.
  lw_fieldcat-outputlen = 10.
  APPEND lw_fieldcat TO gt_fcat.
  CLEAR lw_fieldcat.

  lw_fieldcat-fieldname = 'MODELO'.
  lw_fieldcat-coltext   = TEXT-e09.
  lw_fieldcat-outputlen = 15.
  APPEND lw_fieldcat TO gt_fcat.
  CLEAR lw_fieldcat.

  lw_fieldcat-fieldname = 'MODALIDAD'.
  lw_fieldcat-coltext   = TEXT-e10.
  lw_fieldcat-outputlen = 15.
  APPEND lw_fieldcat TO gt_fcat.
  CLEAR lw_fieldcat.

  lw_fieldcat-fieldname = 'SUCURSAL'.
  lw_fieldcat-coltext   = TEXT-e11.
  lw_fieldcat-outputlen = 20.
  APPEND lw_fieldcat TO gt_fcat.
  CLEAR lw_fieldcat.

  lw_fieldcat-fieldname = 'HS_ANU'.
  lw_fieldcat-coltext   = TEXT-e12.
  lw_fieldcat-outputlen = 8.
  APPEND lw_fieldcat TO gt_fcat.
  CLEAR lw_fieldcat.

  lw_fieldcat-fieldname = 'HS_INI'.
  lw_fieldcat-coltext   = TEXT-e13.
  lw_fieldcat-outputlen = 8.
  APPEND lw_fieldcat TO gt_fcat.
  CLEAR lw_fieldcat.

  lw_fieldcat-fieldname = 'LUGAR'.
  lw_fieldcat-coltext   = TEXT-e14.
  lw_fieldcat-outputlen = 15.
  APPEND lw_fieldcat TO gt_fcat.
  CLEAR lw_fieldcat.

  lw_fieldcat-fieldname = 'CAJA'.
  lw_fieldcat-coltext   = TEXT-e15.
  lw_fieldcat-outputlen = 10.
  APPEND lw_fieldcat TO gt_fcat.
  CLEAR lw_fieldcat.

  lw_fieldcat-fieldname = 'DIFERENCIAL'.
  lw_fieldcat-coltext   = TEXT-e16.
  lw_fieldcat-outputlen = 15.
  APPEND lw_fieldcat TO gt_fcat.
  CLEAR lw_fieldcat.

  lw_fieldcat-fieldname = 'PREPAGO1'.
  lw_fieldcat-coltext   = TEXT-e01.
  lw_fieldcat-emphasize = 'C400'.
  APPEND lw_fieldcat TO gt_fcat.
  CLEAR lw_fieldcat.

  lw_fieldcat-fieldname = 'PREPAGO2'.
  lw_fieldcat-coltext   = TEXT-e02.
  APPEND lw_fieldcat TO gt_fcat.
  CLEAR lw_fieldcat.

  lw_fieldcat-fieldname = 'PREPAGO3'.
  lw_fieldcat-coltext   = TEXT-e17.
  APPEND lw_fieldcat TO gt_fcat.
  CLEAR lw_fieldcat.

  lw_fieldcat-fieldname = 'PREPAGO4'.
  lw_fieldcat-coltext   = TEXT-e18.
  APPEND lw_fieldcat TO gt_fcat.
  CLEAR lw_fieldcat.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_CARGAR_ALV
*&---------------------------------------------------------------------*
FORM f_cargar_alv  USING    pv_o_i_alvgrid TYPE REF TO cl_gui_alv_grid
                            pt_i_fieldcat TYPE        lvc_t_fcat
                            pt_i_alv.

  DATA: lv_variant         TYPE disvariant.
  lv_variant-report = sy-cprog.
  CALL METHOD pv_o_i_alvgrid->set_table_for_first_display
    EXPORTING
      is_variant                    = lv_variant
      i_save                        = 'A'
*     is_layout                     = pw_i_layout
    CHANGING
      it_outtab                     = pt_i_alv
      it_fieldcatalog               = pt_i_fieldcat[]
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    " El sistema se encarga de la validación.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_REFRESCAR_ALV
*&---------------------------------------------------------------------*
FORM f_refrescar_alv   USING  po_i_alvgrid TYPE REF TO cl_gui_alv_grid.

  DATA: lw_stable TYPE lvc_s_stbl.

  lw_stable-row = abap_true.
  lw_stable-col = abap_true.

  CALL METHOD po_i_alvgrid->refresh_table_display
    EXPORTING
      is_stable      = lw_stable
      i_soft_refresh = 'X'
    EXCEPTIONS
      finished       = 1
      OTHERS         = 2.

  IF sy-subrc <> 0.
    " El sistema se encarga de la validación.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_CARGAR_COTIZACION_VIEJA
*&---------------------------------------------------------------------*
FORM f_cargar_cotizacion_vieja .

  DATA: lv_answer     TYPE c,
        lw_cotizacion TYPE ztcotizacion.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = 'Tratamiento'
      text_question         = 'Desea Visualizar o Modificar Versión?'
      text_button_1         = 'Visualizar' "(001)
      text_button_2         = 'Modificar' "(002)
      display_cancel_button = 'X'
      start_column          = 10
      start_row             = 10
    IMPORTING
      answer                = lv_answer
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.


  CHECK lv_answer NE 'A'.

  CLEAR lw_cotizacion.

  SELECT SINGLE *
    FROM ztcotizacion
    INTO lw_cotizacion
   WHERE nro_cotiz = v_nrocotiz
     AND version   = v_version.

  IF sy-subrc = 0.
    REFRESH gt_cotizacion.
    APPEND lw_cotizacion TO gt_cotizacion.
  ENDIF.

  IF lv_answer = '1'.

    IF gt_cotizacion IS NOT INITIAL.
      PERFORM f_imprimir_formulario.
    ELSE.
*        MENSAJE no se encontró cotizacion
    ENDIF.

  ELSEIF lv_answer = '2'.

*     Modificar version de Cotizacion
*     Carga screen con valores de la cotizacion buscada
    CLEAR wa_screen1.
    wa_screen1-nro_cotiz      = lw_cotizacion-nro_cotiz.
    wa_screen1-version        = lw_cotizacion-version.
    wa_screen1-kunnr          = lw_cotizacion-cliente.
    wa_screen1-equipo         = lw_cotizacion-equipo.
    wa_screen1-marca          = lw_cotizacion-marca.
    wa_screen1-modelo         = lw_cotizacion-modelo.
    wa_screen1-modalidad      = lw_cotizacion-modalidad.
    wa_screen1-sucursal       = lw_cotizacion-sucursal.
    wa_screen1-lugar          = lw_cotizacion-lugar.
    wa_screen1-caja           = lw_cotizacion-caja.
    wa_screen1-diferencial    = lw_cotizacion-diferencial.
    wa_screen1-uso            = lw_cotizacion-hs_anu.
    wa_screen1-uso_inicial    = lw_cotizacion-hs_ini.
    wa_screen1-chk_cuota      = lw_cotizacion-chk_cuota.
    wa_screen1-chk_poruso     = lw_cotizacion-chk_uso.
    wa_screen1-chk_ipc        = lw_cotizacion-ipc.
    wa_screen1-chk_desc       = lw_cotizacion-chk_descuento.
    wa_screen1-descuento_peso = lw_cotizacion-descuento_peso.
    wa_screen1-descuento_porc = lw_cotizacion-descuento_porc.
    wa_screen1-chk_tel        = lw_cotizacion-chk_telemetria.
    v_rb_viaticos             = lw_cotizacion-chk_viaticos.
    v_km_terreno              = lw_cotizacion-traslado_km.
    v_hs_terreno              = lw_cotizacion-traslado_hs.
    v_peajes                  = lw_cotizacion-peajes.

    v_modifica_coti = 'X'.
    CALL SCREEN 9000.

  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_CARGAR_INT
*&---------------------------------------------------------------------*
FORM f_cargar_int.

  DATA: lv_mess TYPE string.

  v_werksoc = v_werks500.

  CLEAR wa_cotizacion.
  SELECT SINGLE *
    FROM ztcotizacion
    INTO wa_cotizacion
   WHERE nro_cotiz = v_nrocotiz500
     AND version   = v_version500.

  IF sy-subrc = 0.

    PERFORM f_procesar_int USING space.

  ELSE.

    CONCATENATE 'La cotización' v_nrocotiz500
                'versión' v_version500
           INTO lv_mess SEPARATED BY space.

    CALL FUNCTION 'POPUP_TO_INFORM'
      EXPORTING
        titel = 'Información'
        txt1  = lv_mess
        txt2  = 'No existe'.

  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_PROCESAR_INT
*&---------------------------------------------------------------------*
FORM f_procesar_int USING pv_coef_int TYPE char1.

  DATA: lw_alvint TYPE zst_cotioc,
        lv_texto  TYPE string,
        lv_answer TYPE char1.

  REFRESH gt_intervalos[].

  IF wa_cotizacion-vbeln IS NOT INITIAL.

    SELECT *
      FROM ztcoti_intervalo
      INTO TABLE gt_intervalos
     WHERE pedido = wa_cotizacion-vbeln.

    PERFORM f_seleccionar_pedido_para_oc.

  ELSE.

    SELECT *
      FROM ztcoti_intervalo
      INTO TABLE gt_intervalos
     WHERE nro_cotiz EQ wa_cotizacion-nro_cotiz
       AND pedido    NE space.

    IF sy-subrc = 0.

      READ TABLE gt_intervalos INTO DATA(lw_intervalos) INDEX 1.

      IF lw_intervalos-version NE wa_cotizacion-version.

        CONCATENATE 'La Versión que tiene'
                    'creado el pedido es otra'
               INTO lv_texto SEPARATED BY space.

        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = 'Información'
            text_question         = lv_texto
            text_button_1         = 'Visualizar'
            text_button_2         = 'Crear Ped.'
            display_cancel_button = 'X'
          IMPORTING
            answer                = lv_answer
          EXCEPTIONS
            text_not_found        = 1
            OTHERS                = 2.

        CASE lv_answer.
          WHEN '1'.
            PERFORM f_seleccionar_pedido_para_oc.
          WHEN '2'.
            CALL SCREEN 0400 STARTING AT 10 3.
          WHEN 'A'.
            CALL SCREEN 9000.
        ENDCASE.

      ELSE. "En caso que no guardó el PEDIDO en ZTCOTIZACIONES
        PERFORM f_seleccionar_pedido_para_oc.
      ENDIF.

    ELSE.

      CONCATENATE 'La Cotización'
                  wa_cotizacion-nro_cotiz
                  'Versión'
                  wa_cotizacion-version
                  'No tiene pedido. Desea crearlo?'
             INTO lv_texto SEPARATED BY space.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = 'Información'
          text_question         = lv_texto
          text_button_1         = 'Crear'
          text_button_2         = 'Volver'
          display_cancel_button = space
        IMPORTING
          answer                = lv_answer
        EXCEPTIONS
          text_not_found        = 1
          OTHERS                = 2.

      IF lv_answer = '1'.
        CALL SCREEN 0400 STARTING AT 10 3.
      ELSE.
        CALL SCREEN 9000.
      ENDIF.

    ENDIF.

  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_MOSTRAR_ALV_INT
*&---------------------------------------------------------------------*
FORM f_mostrar_alv_int.

  DATA lt_fieldcat TYPE lvc_t_fcat.

  PERFORM f_crear_fieldcat_int CHANGING lt_fieldcat.
  PERFORM f_ejecutar_alv_int USING lt_fieldcat.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_CREAR_FIELDCAT_INT
*&---------------------------------------------------------------------*
FORM f_crear_fieldcat_int CHANGING pt_fieldcat TYPE lvc_t_fcat.

  DATA: lw_fieldcat TYPE lvc_s_fcat.

  CLEAR lw_fieldcat.
  lw_fieldcat-fieldname = 'LETRA'.
  lw_fieldcat-coltext   = 'Letra'.
  APPEND lw_fieldcat TO pt_fieldcat.

  CLEAR lw_fieldcat.
  lw_fieldcat-fieldname = 'SPACE1'.
  lw_fieldcat-coltext   = 'Vacío'.
  APPEND lw_fieldcat TO pt_fieldcat.

  CLEAR lw_fieldcat.
  lw_fieldcat-fieldname = 'MATNR'.
  lw_fieldcat-coltext   = 'Material'.
  APPEND lw_fieldcat TO pt_fieldcat.

  CLEAR lw_fieldcat.
  lw_fieldcat-fieldname = 'SPACE2'.
  lw_fieldcat-coltext   = 'Vacío'.
  APPEND lw_fieldcat TO pt_fieldcat.

  CLEAR lw_fieldcat.
  lw_fieldcat-fieldname = 'CANTIDAD'.
  lw_fieldcat-coltext   = 'Cantidad'.
  APPEND lw_fieldcat TO pt_fieldcat.

  CLEAR lw_fieldcat.
  lw_fieldcat-fieldname = 'SPACE3'.
  lw_fieldcat-coltext   = 'Vacío'.
  APPEND lw_fieldcat TO pt_fieldcat.

  CLEAR lw_fieldcat.
  lw_fieldcat-fieldname = 'SPACE4'.
  lw_fieldcat-coltext   = 'Vacío'.
  APPEND lw_fieldcat TO pt_fieldcat.

  CLEAR lw_fieldcat.
  lw_fieldcat-fieldname = 'SPACE5'.
  lw_fieldcat-coltext   = 'Vacío'.
  APPEND lw_fieldcat TO pt_fieldcat.

  CLEAR lw_fieldcat.
  lw_fieldcat-fieldname = 'PRECIO'.
  lw_fieldcat-coltext   = 'Precio'.
  APPEND lw_fieldcat TO pt_fieldcat.

  CLEAR lw_fieldcat.
  lw_fieldcat-fieldname = 'SPACE6'.
  lw_fieldcat-coltext   = 'Vacío'.
  APPEND lw_fieldcat TO pt_fieldcat.

  CLEAR lw_fieldcat.
  lw_fieldcat-fieldname = 'SPACE7'.
  lw_fieldcat-coltext   = 'Vacío'.
  APPEND lw_fieldcat TO pt_fieldcat.

  CLEAR lw_fieldcat.
  lw_fieldcat-fieldname = 'SPACE8'.
  lw_fieldcat-coltext   = 'Vacío'.
  APPEND lw_fieldcat TO pt_fieldcat.

  CLEAR lw_fieldcat.
  lw_fieldcat-fieldname = 'SPACE9'.
  lw_fieldcat-coltext   = 'Vacío'.
  APPEND lw_fieldcat TO pt_fieldcat.

  CLEAR lw_fieldcat.
  lw_fieldcat-fieldname = 'WERKS'.
  lw_fieldcat-coltext   = 'Centro'.
  APPEND lw_fieldcat TO pt_fieldcat.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_EJECUTAR_ALV_INT
*&---------------------------------------------------------------------*
FORM f_ejecutar_alv_int USING pt_fieldcat TYPE lvc_t_fcat.

  DATA: lw_layout       TYPE lvc_s_layo,
        li_grid_setting TYPE lvc_s_glay.

  lw_layout-cwidth_opt = 'X'.
  lw_layout-stylefname = 'FIELD_STYLE'.

  li_grid_setting-edt_cll_cb = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program       = sy-repid
      i_callback_user_command  = 'USER_COMMAND_INT'
      i_callback_pf_status_set = 'PF_STATUS_INT'
      i_callback_top_of_page   = 'F_TOP_OF_PAGE_INT'
      i_structure_name         = 'GT_ALVINT'
      is_layout_lvc            = lw_layout
      it_fieldcat_lvc          = pt_fieldcat[]
      i_grid_settings          = li_grid_setting
      i_save                   = 'X'
    TABLES
      t_outtab                 = gt_alvint
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.

ENDFORM.       "F_EJECUTAR_ALV_INT


*&---------------------------------------------------------------------*
*&      Form  F_TOP_OF_PAGE_INT
*&---------------------------------------------------------------------*
FORM f_top_of_page_int.

  DATA: lt_header    TYPE slis_t_listheader,
        lw_header    TYPE slis_listheader,
        lv_intervalo TYPE char8.

  REFRESH: lt_header.
  CLEAR lw_header.

  WRITE v_intervalo TO lv_intervalo.

  REPLACE ALL OCCURRENCES OF '.' IN lv_intervalo WITH ''.
  REPLACE ALL OCCURRENCES OF ',' IN lv_intervalo WITH ''.

  lw_header-typ  = 'H'.
  CONCATENATE 'Intervalo:' lv_intervalo
         INTO lw_header-info SEPARATED BY space.

  APPEND lw_header TO lt_header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_header.

ENDFORM.        "F_TOP_OF_PAGE_INT


*&--------------------------------------------------------------------*
*&      FORM USER_COMMAND_INT
*&--------------------------------------------------------------------*
FORM user_command_int USING pv_ucomm    LIKE sy-ucomm
                           pw_selfield TYPE slis_selfield.

  DATA: lw_pauta     TYPE ty_pauta,
        lw_new_pauta TYPE ty_pauta.

  CASE sy-ucomm. "pv_ucomm.
    WHEN 'PEDIDO'.
      CALL SCREEN 0400 STARTING AT 10 3.
    WHEN 'CANCEL' OR 'BACK'.
      CALL SCREEN 9000.
    WHEN 'EXIT'.
      LEAVE PROGRAM.

  ENDCASE.

  pw_selfield-refresh = 'X'.

ENDFORM.                    " USER_COMMAND_INT

*&---------------------------------------------------------------------*
*       FORM PF_STATUS_INT
*&---------------------------------------------------------------------*
FORM pf_status_int USING lt_cua_exclude TYPE slis_t_extab.

  SET PF-STATUS 'STATUS_INT'.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_CREAR_PEDIDO
*&---------------------------------------------------------------------*
FORM f_crear_pedido.

  DATA: lt_items                TYPE STANDARD TABLE OF bapisditm,
        lt_itemsx               TYPE STANDARD TABLE OF bapisditmx,
        lt_order_partners       TYPE STANDARD TABLE OF bapiparnr,
        lt_orderschedin         TYPE STANDARD TABLE OF bapischdl,
        lt_orderschedin_x       TYPE STANDARD TABLE OF bapischdlx,
        lt_order_conditions_in  TYPE STANDARD TABLE OF bapicond,
        lt_order_conditions_inx TYPE STANDARD TABLE OF bapicondx,
        lt_return               TYPE STANDARD TABLE OF bapiret2,
        lt_intervalos           TYPE STANDARD TABLE OF ztcoti_intervalo,
        lt_bapiret2             TYPE TABLE OF bapiret2,
        lt_order_text           TYPE STANDARD TABLE OF bapisdtext,
        lt_messtab              TYPE tyt_bdcmsgcoll,

        lw_order_header         TYPE bapisdhd1,
        lw_order_header_x       TYPE bapisdhd1x,
        lw_items                TYPE bapisditm,
        lw_itemsx               TYPE bapisditmx,
        lw_order_partners       TYPE bapiparnr,
        lw_orderschedin         TYPE bapischdl,
        lw_orderschedin_x       TYPE bapischdlx,
        lw_order_conditions_in  TYPE bapicond,
        lw_order_conditions_inx TYPE bapicondx,
        lw_return               TYPE bapiret2,
        lw_intervalos           TYPE ztcoti_intervalo,
        lw_order_view           TYPE order_view,
        lw_sales_documents      TYPE sales_key,
        lw_item_out             TYPE bapisdit,
        lw_bapiret2             TYPE bapiret2,
        lw_order_text           TYPE bapisdtext.


* variables locales
  DATA: lv_kunnr         TYPE kunnr,
        lv_pos           TYPE posnr_va,
        lv_vbeln         TYPE bapivbeln-vbeln,
        lv_precio        TYPE bapikbetr1,
        lv_precio_totint TYPE bapikbetr1,
        lv_precio_int    TYPE bapikbetr1,
        lv_cuota_tot     TYPE bapikbetr1,
        lv_lines         TYPE tdline,
        lv_vbtyp_v       TYPE vbtyp_v.

* Limpia tablas
  REFRESH: lt_items,
           lt_itemsx,
           lt_orderschedin,
           lt_orderschedin_x,
           lt_order_partners,
           lt_order_conditions_in,
           lt_order_conditions_in.

  CLEAR wa_cotizacion.
  SELECT SINGLE *
    FROM ztcotizacion
    INTO wa_cotizacion
   WHERE nro_cotiz = v_nrocotiz500
     AND version   = v_version500.

  IF v_rb_leasing = 'X'.

    IF v_nrofact IS INITIAL.

      CALL FUNCTION 'POPUP_TO_INFORM'
        EXPORTING
          titel = 'Información'
          txt1  = 'Para contratos Leasing'
          txt2  = 'debe ingresar N° de Factura SAP'.

      CALL SCREEN 0400 STARTING AT 10 3.

    ELSE.

      CLEAR lv_vbtyp_v.

      SELECT SINGLE *
        FROM vbrk
        INTO @DATA(lw_vbrk)
       WHERE vbeln = @v_nrofact.

      IF sy-subrc = 0.

        SELECT SINGLE *
          FROM vbrp
          INTO @DATA(lw_vbrp)
         WHERE vbeln = @v_nrofact.
*           AND xblnr = @lw_vbrk-xblnr. AGREGAR POSICION DESEADA

        IF sy-subrc = 0.
          lv_vbtyp_v = lw_vbrk-vbtyp. "M
        ELSE.
          CALL FUNCTION 'POPUP_TO_INFORM'
            EXPORTING
              titel = 'Información'
              txt1  = 'La Factura seleccionada'
              txt2  = 'NO existe'.

          CALL SCREEN 0400 STARTING AT 10 3.
        ENDIF.

      ELSE.

        CALL FUNCTION 'POPUP_TO_INFORM'
          EXPORTING
            titel = 'Información'
            txt1  = 'La factura seleccionada NO contiene'
            txt2  = 'la posición Prov.Mant.Convenios'.

        CALL SCREEN 0400 STARTING AT 10 3.

      ENDIF.

    ENDIF.

  ENDIF.

*  IF v_rb_prepago = 'X' OR v_rb_cuota = 'X'.
*    v_auart = 'ZPP3'.
*  ELSEIF v_rb_leasing = 'X'.
*    v_auart = 'ZPPL'.
*  ENDIF.

  SELECT *
    FROM ztcoti_intervalo
    INTO TABLE lt_intervalos
   WHERE nro_cotiz EQ wa_cotizacion-nro_cotiz
     AND version   EQ wa_cotizacion-version
     AND duracion  LE v_duracion.

  IF sy-subrc = 0.
    CLEAR lv_precio_int.
    LOOP AT lt_intervalos INTO lw_intervalos.
      CASE v_duracion.
        WHEN wa_cotizacion-duracion1.
          ADD lw_intervalos-prepago1 TO lv_precio_totint.
        WHEN wa_cotizacion-duracion2.
          ADD lw_intervalos-prepago2 TO lv_precio_totint.
        WHEN wa_cotizacion-duracion3.
          ADD lw_intervalos-prepago3 TO lv_precio_totint.
        WHEN wa_cotizacion-duracion4.
          ADD lw_intervalos-prepago4 TO lv_precio_totint.
      ENDCASE.
    ENDLOOP.
  ENDIF.

* Asigno intervalo
  IF v_rb_cuota = 'X'.
    IF wa_cotizacion-chk_cuota = 'X'.
      CASE v_duracion.
        WHEN wa_cotizacion-duracion1.
          lv_cuota_tot = wa_cotizacion-cuota1 * v_duracion.
        WHEN wa_cotizacion-duracion2.
          lv_cuota_tot = wa_cotizacion-cuota2 * v_duracion.
        WHEN wa_cotizacion-duracion3.
          lv_cuota_tot = wa_cotizacion-cuota3 * v_duracion.
        WHEN wa_cotizacion-duracion4.
          lv_cuota_tot = wa_cotizacion-cuota4 * v_duracion.
      ENDCASE.
    ELSEIF wa_cotizacion-chk_cuota_ajus = 'X'.
      CASE v_duracion.
        WHEN wa_cotizacion-duracion1.
          lv_cuota_tot = wa_cotizacion-cuota_ajus1 * v_duracion.
        WHEN wa_cotizacion-duracion2.
          lv_cuota_tot = wa_cotizacion-cuota_ajus2 * v_duracion.
        WHEN wa_cotizacion-duracion3.
          lv_cuota_tot = wa_cotizacion-cuota_ajus3 * v_duracion.
        WHEN wa_cotizacion-duracion4.
          lv_cuota_tot = wa_cotizacion-cuota_ajus4 * v_duracion.
      ENDCASE.
    ENDIF.
  ENDIF.

* Busco material SAP asociado al Intervalo
  SELECT *
    FROM ztcodmat_int
    INTO TABLE @DATA(lt_materiales)
   WHERE equipo    EQ @wa_cotizacion-equipo.
  IF sy-subrc = 0.
    LOOP AT lt_materiales ASSIGNING FIELD-SYMBOL(<fs_mat>).
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = <fs_mat>-intervalo
        IMPORTING
          output = <fs_mat>-intervalo.
    ENDLOOP.
    SORT lt_materiales BY equipo intervalo.
  ENDIF.

* Selecciono Centro segun Oficina de Venta
  SELECT SINGLE *
    FROM ztofvta_centro
    INTO @DATA(lw_ofvta)
   WHERE vkbur = @v_vkbur.


*************    SALES ORDER HEADER   ***************
  IF v_rb_leasing = 'X'.
    lw_order_header-ref_doc    	 = v_nrofact.
    lw_order_header_x-ref_doc    = c_mark.
    lw_order_header-refdoc_cat   = lv_vbtyp_v.
    lw_order_header_x-refdoc_cat = c_mark.
  ENDIF.


* Tipo doc.
  lw_order_header-doc_type   = v_auart.
  lw_order_header_x-doc_type = c_mark.

* Org. ventas
  lw_order_header-sales_org   = v_vkorg. "'1000'.
  lw_order_header_x-sales_org = c_mark.

* Canal distr.
  lw_order_header-distr_chan   = v_vtweg. "'VS'.
  lw_order_header_x-distr_chan = c_mark.

* Sector.
  lw_order_header-division   = v_spart. "'R0'.
  lw_order_header_x-division = c_mark.

* Fecha entrega
  lw_order_header-req_date_h   = sy-datum.
  lw_order_header_x-req_date_h = c_mark.

* Document date
  lw_order_header-doc_date     = sy-datum.
  lw_order_header_x-doc_date   = c_mark.
  lw_order_header-purch_date   = sy-datum.
  lw_order_header_x-purch_date = c_mark.
  lw_order_header-price_date   = sy-datum.
  lw_order_header_x-price_date = c_mark.

* Fecha pedido dest.merc.
  lw_order_header-po_dat_s    = sy-datum.
  lw_order_header_x-po_dat_s  = c_mark.

* Oficina de ventas
  lw_order_header-sales_off   = v_vkbur.
  lw_order_header_x-sales_off = c_mark.

* Grupo de vendedores
  lw_order_header-sales_grp   = v_vkgrp. "'STA'.
  lw_order_header_x-sales_grp = c_mark.

* Solicitante
  CLEAR lw_order_partners.
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = wa_cotizacion-cliente
    IMPORTING
      output = lv_kunnr.

  lw_order_partners-partn_numb  = lv_kunnr.
  lw_order_partners-partn_role  = v_parvw. "'AG'.
  APPEND lw_order_partners TO lt_order_partners.
  CLEAR lw_order_partners.

* Textos
  CLEAR: lw_order_text, lv_lines.
  CONDENSE v_vin NO-GAPS.
  lv_lines = v_vin.

  lw_order_text-text_id    = '0002'.
  lw_order_text-langu      = 'S'.
  lw_order_text-langu_iso  = 'ES'.
  lw_order_text-text_line  = lv_lines.
  APPEND lw_order_text TO lt_order_text.

*  IF v_auart NE 'ZPPL'. "Leasing hereda de la factura los textos
  IF v_rb_leasing NE 'X'.
    CLEAR: lv_lines, lw_order_text.
    CONCATENATE ' Mantenimiento preventivo equipo'
                v_vin
           INTO lv_lines
      SEPARATED BY space.

    lw_order_text-text_id    = 'Z002'.
    lw_order_text-langu      = 'S'.
    lw_order_text-langu_iso  = 'ES'.
    lw_order_text-text_line  = ' '.
    APPEND lw_order_text TO lt_order_text.
    lw_order_text-text_line  = lv_lines.
    APPEND lw_order_text TO lt_order_text.
  ENDIF.

*************    SALES ORDER ITEM   ***************
  CLEAR: lv_pos.

  LOOP AT lt_intervalos INTO lw_intervalos.

    CLEAR: lw_items,
           lw_itemsx,
           lw_orderschedin,
           lw_orderschedin_x,
           lw_order_conditions_in,
           lw_order_conditions_inx.

    ADD 10 TO lv_pos.

    CASE v_duracion.
      WHEN wa_cotizacion-duracion1.
        lv_precio_int = lw_intervalos-prepago1 / 1000.
      WHEN wa_cotizacion-duracion2.
        lv_precio_int = lw_intervalos-prepago2 / 1000.
      WHEN wa_cotizacion-duracion3.
        lv_precio_int = lw_intervalos-prepago3 / 1000.
      WHEN wa_cotizacion-duracion4.
        lv_precio_int = lw_intervalos-prepago4 / 1000.
    ENDCASE.


    lw_items-itm_number                = lv_pos.
    lw_itemsx-itm_number               = lv_pos.
    lw_orderschedin-itm_number         = lv_pos.
    lw_orderschedin_x-itm_number       = lv_pos.
    lw_order_conditions_in-itm_number  = lv_pos.
    lw_order_conditions_inx-itm_number = lv_pos.

    READ TABLE lt_materiales INTO DATA(lw_materiales)
      WITH KEY equipo    = wa_cotizacion-equipo
               intervalo = lw_intervalos-intervalo.

    IF sy-subrc = 0.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = lw_materiales-matnr
        IMPORTING
          output = lw_items-material.
      lw_itemsx-material            = c_mark.
    ENDIF.

    lw_items-target_qty           = '1'.
    lw_itemsx-target_qty          = c_mark.

    lw_orderschedin-req_qty       = '1'.
    lw_orderschedin_x-req_qty     = c_mark.

    lw_items-plant                = lw_ofvta-werks.
    lw_itemsx-plant               = c_mark.

*    CASE 'X'.
*      WHEN v_rb_prepago OR v_rb_leasing.
*        lw_items-item_categ  = 'ZPP2'.
*      WHEN v_rb_cuota.
*        lw_items-item_categ  = 'ZPPC'.
*    ENDCASE.
    lw_items-item_categ   = v_pstyv.
    lw_itemsx-item_categ  = c_mark.


*   Condiciones
    lw_order_conditions_in-cond_type  = v_kscha. "'ZFLE'.
    lw_order_conditions_inx-cond_type = c_mark.

    IF v_rb_cuota = 'X'.
      lv_precio = lv_precio_int / lv_precio_totint * lv_cuota_tot.
    ELSE.
      lv_precio = lv_precio_int.
    ENDIF.
    lw_order_conditions_in-cond_value  = lv_precio.
    lw_order_conditions_inx-cond_value = c_mark.


    APPEND: lw_items                TO lt_items,
            lw_itemsx               TO lt_itemsx,
            lw_orderschedin         TO lt_orderschedin,
            lw_orderschedin_x       TO lt_orderschedin_x,
            lw_order_conditions_in  TO lt_order_conditions_in,
            lw_order_conditions_inx TO lt_order_conditions_inx.

  ENDLOOP.

* Initialize bapi
  CALL FUNCTION 'CUXC_INIT'.

  DATA lv_test.

* Call bapi
  CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
    EXPORTING
      order_header_in      = lw_order_header
      order_header_inx     = lw_order_header_x
      testrun              = lv_test
    IMPORTING
      salesdocument        = lv_vbeln
    TABLES
      return               = lt_return
      order_items_in       = lt_items
      order_items_inx      = lt_itemsx
      order_partners       = lt_order_partners
      order_schedules_in   = lt_orderschedin
      order_schedules_inx  = lt_orderschedin_x
      order_conditions_in  = lt_order_conditions_in
      order_conditions_inx = lt_order_conditions_inx
      order_text           = lt_order_text.

  IF lv_vbeln IS INITIAL.

    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

    APPEND LINES OF lt_return TO lt_bapiret2.
    LOOP AT lt_return INTO lw_return.
      IF lw_return-type   = 'E' AND
         lw_return-id     = 'V4' AND
         lw_return-number = '248'.

        lv_pos = lw_return-message_v2.

        READ TABLE lt_items INTO lw_items
          WITH KEY itm_number = lv_pos.
        IF sy-subrc = 0.
          CONCATENATE 'Posición' lv_pos '-> Material' lw_items-material
                 INTO lw_return-message SEPARATED BY space.
          lw_return-id         = 'ZSD'.
          lw_return-number     = '025'.
          lw_return-message_v1 = 'Posición'.
          lw_return-message_v2 = lv_pos.
          lw_return-message_v3 = '-> Material'.
          lw_return-message_v4 = lw_items-material.

          APPEND lw_return TO lt_bapiret2.
        ENDIF.

      ENDIF.
    ENDLOOP.

  ELSE. "Pedido Creado con Éxito

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = c_mark.

    IF v_rb_cuota = 'X'.
      REFRESH lt_messtab[].
      PERFORM f_modifica_plan_facturacion
        USING lv_vbeln
        CHANGING lt_messtab.
    ENDIF.

*    IF v_rb_cuota = 'X'.
*      wa_cotizacion-auart = 'ZPPC'.
*    ELSE.
    wa_cotizacion-auart = v_auart.
*    ENDIF.
    wa_cotizacion-vkbur            = v_vkbur.
    wa_cotizacion-duracion_elegida = v_duracion.
    wa_cotizacion-factura          = v_nrofact.
    wa_cotizacion-vin              = v_vin.
    wa_cotizacion-werksoc          = lw_ofvta-werks.
    wa_cotizacion-vbeln            = lv_vbeln.

    MODIFY ztcotizacion FROM wa_cotizacion.

    LOOP AT lt_intervalos INTO lw_intervalos.
      lw_intervalos-pedido = lv_vbeln.
      CLEAR lw_materiales.
      READ TABLE lt_materiales INTO lw_materiales
        WITH KEY equipo    = wa_cotizacion-equipo
                 intervalo = lw_intervalos-intervalo.
      IF sy-subrc = 0.
        lw_intervalos-matnr = lw_materiales-matnr.
      ENDIF.
      MODIFY ztcoti_intervalo FROM lw_intervalos.
    ENDLOOP.

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = c_mark.

    CLEAR lw_bapiret2.
    lw_bapiret2-type       = 'S'.
    lw_bapiret2-id         = 'ZSD'.
    lw_bapiret2-number     = 035.
    lw_bapiret2-message_v1 = TEXT-003.   " 'Se creó el Pedido de Venta '.
    lw_bapiret2-message_v2 = lv_vbeln.
    APPEND lw_bapiret2 TO lt_bapiret2.

    READ TABLE lt_messtab INTO DATA(lw_messtab) "Batch Input
      WITH KEY msgtyp = 'E'.
    IF sy-subrc = 0.
      CLEAR lw_bapiret2.
      lw_bapiret2-type       = 'S'.
      lw_bapiret2-id         = 'ZSD'.
      lw_bapiret2-number     = 035.
      lw_bapiret2-message_v1 = TEXT-004.   " No se actualizó el Plan de Facturacion
      APPEND lw_bapiret2 TO lt_bapiret2.
    ENDIF.

  ENDIF.

  CALL FUNCTION 'C14ALD_BAPIRET2_SHOW'
    TABLES
      i_bapiret2_tab = lt_bapiret2.

  REFRESH lt_bapiret2.
  CLEAR lw_bapiret2.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_MODIFICA_PLAN_FACTURACION
*&---------------------------------------------------------------------*
FORM f_modifica_plan_facturacion USING pv_vbeln   TYPE vbak-vbeln
                              CHANGING pt_messtab TYPE tyt_bdcmsgcoll.

  DATA: lv_modo     TYPE c VALUE 'N',
        lv_update   TYPE c VALUE 'S',
        lv_catt     TYPE c VALUE 'N',
        lv_fecha    TYPE char10,
        lv_firstday TYPE sy-datum,
        lv_lastday  TYPE sy-datum,
        lw_planfac  TYPE ztplanfac,
        lw_opt      TYPE ctu_params.

  SELECT SINGLE *
    FROM ztplanfac
    INTO lw_planfac
   WHERE duracion = v_duracion.

  CALL FUNCTION 'OIL_MONTH_GET_FIRST_LAST'
    EXPORTING
      i_month     = sy-datum+4(2)
      i_year      = sy-datum(4)
    IMPORTING
      e_first_day = lv_firstday
      e_last_day  = lv_lastday
    EXCEPTIONS
      wrong_date  = 1
      OTHERS      = 2.

  lv_fecha = lv_firstday.
  CONCATENATE lv_fecha+6(2)
              lv_fecha+4(2)
              lv_fecha(4)
         INTO lv_fecha SEPARATED BY '.'.

  PERFORM f_dynpro USING 'SAPMV45A'   '0102'.
  PERFORM f_datos  USING 'VBAK-VBELN' pv_vbeln.
  PERFORM f_datos  USING 'BDC_OKCODE' '/00'.

  PERFORM f_dynpro USING 'SAPMV45A'   '4001'.
  PERFORM f_datos  USING 'BDC_OKCODE' '=HEAD'.

  PERFORM f_dynpro USING 'SAPMV45A'   '4002'.
  PERFORM f_datos  USING 'BDC_OKCODE' '=T\05'.

  PERFORM f_dynpro USING 'SAPLV60F'   '4001'.
  PERFORM f_datos  USING 'FPLA-BEDAT' lv_fecha.
  PERFORM f_datos  USING 'FPLA-BEDAR' ''.
  PERFORM f_datos  USING 'FPLA-RFPLN' lw_planfac-rfpln.
  PERFORM f_datos  USING 'BDC_OKCODE' '/00'.
  PERFORM f_datos  USING 'BDC_OKCODE' '=S\BACK'.

  PERFORM f_dynpro USING 'SAPMV45A'   '4001'.
  PERFORM f_datos  USING 'BDC_OKCODE' '=SICH'.

  CLEAR lw_opt.
  lw_opt-cattmode = lv_catt.  "N: CATT s/control, A: CATT c/control, Vacio: Sin CATT
  lw_opt-dismode  = lv_modo.  "A: Paso a paso, E: Errores, N: Normal
  lw_opt-updmode  = lv_update."S: Sincronico, A: Asincronico
  lw_opt-racommit = c_mark.
  lw_opt-nobinpt  = c_mark.
  lw_opt-nobiend  = c_mark.

  CALL TRANSACTION 'VA02' USING gt_bdcdata
                   OPTIONS FROM lw_opt
                  MESSAGES INTO pt_messtab.

  REFRESH gt_bdcdata.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_DYNPRO
*&---------------------------------------------------------------------*
FORM f_dynpro USING pv_program pv_dynpro.

  DATA lw_bdcdata TYPE ty_bdcdata.
  CLEAR lw_bdcdata.

  lw_bdcdata-program  = pv_program.
  lw_bdcdata-dynpro   = pv_dynpro.
  lw_bdcdata-dynbegin = 'X'.
  APPEND lw_bdcdata TO gt_bdcdata.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_DATOS
*&---------------------------------------------------------------------*
FORM f_datos USING pv_fnam pv_fval.

  DATA lw_bdcdata TYPE ty_bdcdata.
  CLEAR lw_bdcdata.

  lw_bdcdata-fnam = pv_fnam.
  lw_bdcdata-fval = pv_fval.
  APPEND lw_bdcdata TO gt_bdcdata.

ENDFORM.


*&---------------------------------------------------------------------*
*       FORM PF_STATUS_OC
*&---------------------------------------------------------------------*
FORM pf_status_oc USING lt_cua_exclude TYPE slis_t_extab.

  SET PF-STATUS 'STATUS_OC'.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_IMPRIMIR_FORMULARIO
*&---------------------------------------------------------------------*
FORM f_imprimir_formulario .

  DATA: l_funcion        TYPE rs38l_fnam,
        l_output_option  TYPE ssfcompop,
        l_control_option TYPE ssfctrlop,
        lt_detalle       TYPE ztt_detallecm.


  PERFORM f_parametros_impresion CHANGING l_output_option.

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname           = 'ZFCOTIZADOR_TEST'  "'ZFCOTIZADOR'  "
*     VARIANT            = ' '
*     DIRECT_CALL        = ' '
    IMPORTING
      fm_name            = l_funcion
    EXCEPTIONS
      no_form            = 1
      no_function_module = 2
      OTHERS             = 3.

  IF sy-subrc = 0.
    PERFORM f_opciones_control CHANGING l_control_option.

    READ TABLE gt_cotizacion INTO DATA(lw_cotizacion) INDEX 1.

* Proceso info antes de enviar al formulario.
    PERFORM f_proceso_tabla_detallecm CHANGING lt_detalle.

* Enviar datos al formulario e imprimirlo.
    CALL FUNCTION l_funcion
      EXPORTING
        control_parameters = l_control_option
        output_options     = l_output_option
        user_settings      = ' '
        wa_cotizacion      = lw_cotizacion
      TABLES
        it_detalle         = lt_detalle[]
      EXCEPTIONS
        formatting_error   = 1
        internal_error     = 2
        send_error         = 3
        user_canceled      = 4
        OTHERS             = 5.
  ENDIF.


ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_PARAMETROS_IMPRESION
*&---------------------------------------------------------------------*
FORM f_parametros_impresion CHANGING pl_output_option TYPE ssfcompop.

  DATA:  lv_ldest TYPE rspopname.

  itcpo-tdcopies   = 1.         " Cantidad de impresiones
*  itcpo-tddest     = 'LOCAL'.   " Nombre de la impresora
  pl_output_option-tdimmed    = 'X'.       " Imprime inmediatamente
  itcpo-tdnewid    = 'X'.       " Crear nueva SPOOL
*  itcpo-tddelete   = 'X'.       " Borra después de imprimir
*  itcpo-tdpageslct = space.     " Todas las páginas
*  itcpo-tdpreview  = space.     " Visualización de la impresión
*  itcpo-tdcover    = space.     " No portada

***Output Options
  lv_ldest = 'ZLOC'. "definicion de impresoras

**  «ACTIVA SELECCION DE IMPRESORA
**  «—————————————————-
  pl_output_option-tddest     = lv_ldest."Impresora

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_OPCIONES_CONTROL
*&---------------------------------------------------------------------*
FORM f_opciones_control  CHANGING pl_control_option  TYPE ssfctrlop.

***Control Options
  pl_control_option-preview   = 'X'.
  pl_control_option-no_open   = ' '.
  pl_control_option-no_close  = ' '.
  pl_control_option-no_dialog = 'X'.
  pl_control_option-device    = 'PRINTER'.
*  pl_control_options-getotf   = ‘X’.


ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_GRABA_COTIZACION
*&---------------------------------------------------------------------*
FORM f_graba_cotizacion.

  DATA: lt_bapiret2 TYPE TABLE OF bapiret2,
        lw_bapiret2 TYPE bapiret2,
        lv_message  TYPE symsgv.

  FIELD-SYMBOLS <fs_intervalos> TYPE ztcoti_intervalo.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar       = 'Acción'
      text_question  = 'Desea grabar la Versión de la Cotización??'
      text_button_1  = 'Si' "(001)
      text_button_2  = 'No' "(002)
      default_button = '1'
      start_column   = 25
      start_row      = 6
    IMPORTING
      answer         = v_answer.

  IF v_answer EQ '1'.

    PERFORM f_procesa_pauta CHANGING v_numeropauta.

    READ TABLE gt_cotizacion INTO DATA(lw_cotizacion) INDEX 1.

    IF sy-subrc = 0.

      lw_cotizacion-numero_pauta = v_numeropauta.
      MODIFY ztcotizacion FROM lw_cotizacion.

      IF gt_intervalos IS NOT INITIAL.

        SORT gt_intervalos ASCENDING BY nro_cotiz version intervalo.

        LOOP AT gt_intervalos ASSIGNING <fs_intervalos>.
          <fs_intervalos>-nro_cotiz = lw_cotizacion-nro_cotiz.
          <fs_intervalos>-version   = lw_cotizacion-version.
          IF <fs_intervalos>-prepago1 IS NOT INITIAL.
            <fs_intervalos>-duracion = lw_cotizacion-duracion1.
          ELSE.
            IF <fs_intervalos>-prepago2 IS NOT INITIAL.
              <fs_intervalos>-duracion = lw_cotizacion-duracion2.
            ELSE.
              IF <fs_intervalos>-prepago3 IS NOT INITIAL.
                <fs_intervalos>-duracion = lw_cotizacion-duracion3.
              ELSE.
                IF <fs_intervalos>-prepago4 IS NOT INITIAL.
                  <fs_intervalos>-duracion = lw_cotizacion-duracion4.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDLOOP.

        MODIFY ztcoti_intervalo FROM TABLE gt_intervalos.

      ENDIF.

    ENDIF.

    CONCATENATE 'Se creó la Cotización:'
                lw_cotizacion-nro_cotiz
                'Versión:'
                lw_cotizacion-version
           INTO lv_message
      SEPARATED BY space.

    REFRESH lt_bapiret2.
    CLEAR lw_bapiret2.

    lw_bapiret2-type       = 'S'.
    lw_bapiret2-id         = 'ZSD'.
    lw_bapiret2-number     = 035.
    lw_bapiret2-message_v1 = lv_message.
    APPEND lw_bapiret2 TO lt_bapiret2.

    CALL FUNCTION 'C14ALD_BAPIRET2_SHOW'
      TABLES
        i_bapiret2_tab = lt_bapiret2.

    wa_screen1-nro_cotiz = lw_cotizacion-nro_cotiz.
    wa_screen1-version   = lw_cotizacion-version.

  ENDIF.

  v_active9000 = 'X'.
  REFRESH: gt_pauta, gt_repuestos.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_PROCESO_TABLA_DETALLECM
*&---------------------------------------------------------------------*
FORM f_proceso_tabla_detallecm  CHANGING pt_detalle TYPE ztt_detallecm.

  DATA: lt_pauta   TYPE STANDARD TABLE OF ty_pauta,
        lw_detalle TYPE zts_detallecm,
        lv_cant    TYPE sy-tabix.

  lt_pauta[] = gt_pauta[].
  SORT lt_pauta BY intervalo_mine ASCENDING.
  READ TABLE lt_pauta INTO DATA(lw_pauta2) INDEX 1.
  IF sy-subrc = 0.
    DATA(lv_intervalo) = lw_pauta2-intervalo_mine.
  ENDIF.
  LOOP AT gt_pauta INTO DATA(lw_pauta).
    AT FIRST.
      lw_detalle-servicio    = ''.
      lw_detalle-descripcion = 'DESCRIPCIÓN'.
      lw_detalle-intervalo01 = lv_intervalo(4).
      lw_detalle-intervalo02 = lv_intervalo(4) * 2.
      lw_detalle-intervalo03 = lv_intervalo(4) * 3.
      lw_detalle-intervalo04 = lv_intervalo(4) * 4.
      lw_detalle-intervalo05 = lv_intervalo(4) * 5.
      lw_detalle-intervalo06 = lv_intervalo(4) * 6.
      lw_detalle-intervalo07 = lv_intervalo(4) * 7.
      lw_detalle-intervalo08 = lv_intervalo(4) * 8.
      lw_detalle-intervalo09 = lv_intervalo(4) * 9.
      lw_detalle-intervalo10 = lv_intervalo(4) * 10.
      lw_detalle-intervalo11 = lv_intervalo(4) * 11.
      lw_detalle-intervalo12 = lv_intervalo(4) * 12.
      lw_detalle-intervalo13 = lv_intervalo(4) * 13.
      lw_detalle-intervalo14 = lv_intervalo(4) * 14.
      lw_detalle-intervalo15 = lv_intervalo(4) * 15.
      lw_detalle-intervalo16 = lv_intervalo(4) * 16.
      lw_detalle-intervalo17 = lv_intervalo(4) * 17.
      lw_detalle-intervalo18 = lv_intervalo(4) * 18.
      lw_detalle-intervalo19 = lv_intervalo(4) * 19.
      lw_detalle-intervalo20 = lv_intervalo(4) * 20.
      APPEND lw_detalle TO pt_detalle.
    ENDAT.

    CLEAR: lw_detalle, lv_cant.

    lw_detalle-descripcion = lw_pauta-descripcion_mat.

    ADD 1 TO lv_cant.
    IF ( lv_intervalo * lv_cant ) MOD lw_pauta-intervalo_mine = 0.
      lw_detalle-intervalo01 = 'X'.
    ENDIF.
    ADD 1 TO lv_cant.
    IF ( lv_intervalo * lv_cant ) MOD lw_pauta-intervalo_mine = 0.
      lw_detalle-intervalo02 = 'X'.
    ENDIF.
    ADD 1 TO lv_cant.
    IF ( lv_intervalo * lv_cant ) MOD lw_pauta-intervalo_mine = 0.
      lw_detalle-intervalo03 = 'X'.
    ENDIF.
    ADD 1 TO lv_cant.
    IF ( lv_intervalo * lv_cant ) MOD lw_pauta-intervalo_mine = 0.
      lw_detalle-intervalo04 = 'X'.
    ENDIF.
    ADD 1 TO lv_cant.
    IF ( lv_intervalo * lv_cant ) MOD lw_pauta-intervalo_mine = 0.
      lw_detalle-intervalo05 = 'X'.
    ENDIF.
    ADD 1 TO lv_cant.
    IF ( lv_intervalo * lv_cant ) MOD lw_pauta-intervalo_mine = 0.
      lw_detalle-intervalo06 = 'X'.
    ENDIF.
    ADD 1 TO lv_cant.
    IF ( lv_intervalo * lv_cant ) MOD lw_pauta-intervalo_mine = 0.
      lw_detalle-intervalo07 = 'X'.
    ENDIF.
    ADD 1 TO lv_cant.
    IF ( lv_intervalo * lv_cant ) MOD lw_pauta-intervalo_mine = 0.
      lw_detalle-intervalo08 = 'X'.
    ENDIF.
    ADD 1 TO lv_cant.
    IF ( lv_intervalo * lv_cant ) MOD lw_pauta-intervalo_mine = 0.
      lw_detalle-intervalo09 = 'X'.
    ENDIF.
    ADD 1 TO lv_cant.
    IF ( lv_intervalo * lv_cant ) MOD lw_pauta-intervalo_mine = 0.
      lw_detalle-intervalo10 = 'X'.
    ENDIF.
    ADD 1 TO lv_cant.
    IF ( lv_intervalo * lv_cant ) MOD lw_pauta-intervalo_mine = 0.
      lw_detalle-intervalo11 = 'X'.
    ENDIF.
    ADD 1 TO lv_cant.
    IF ( lv_intervalo * lv_cant ) MOD lw_pauta-intervalo_mine = 0.
      lw_detalle-intervalo12 = 'X'.
    ENDIF.
    ADD 1 TO lv_cant.
    IF ( lv_intervalo * lv_cant ) MOD lw_pauta-intervalo_mine = 0.
      lw_detalle-intervalo13 = 'X'.
    ENDIF.
    ADD 1 TO lv_cant.
    IF ( lv_intervalo * lv_cant ) MOD lw_pauta-intervalo_mine = 0.
      lw_detalle-intervalo14 = 'X'.
    ENDIF.
    ADD 1 TO lv_cant.
    IF ( lv_intervalo * lv_cant ) MOD lw_pauta-intervalo_mine = 0.
      lw_detalle-intervalo15 = 'X'.
    ENDIF.
    ADD 1 TO lv_cant.
    IF ( lv_intervalo * lv_cant ) MOD lw_pauta-intervalo_mine = 0.
      lw_detalle-intervalo16 = 'X'.
    ENDIF.
    ADD 1 TO lv_cant.
    IF ( lv_intervalo * lv_cant ) MOD lw_pauta-intervalo_mine = 0.
      lw_detalle-intervalo17 = 'X'.
    ENDIF.
    ADD 1 TO lv_cant.
    IF ( lv_intervalo * lv_cant ) MOD lw_pauta-intervalo_mine = 0.
      lw_detalle-intervalo18 = 'X'.
    ENDIF.
    ADD 1 TO lv_cant.
    IF ( lv_intervalo * lv_cant ) MOD lw_pauta-intervalo_mine = 0.
      lw_detalle-intervalo19 = 'X'.
    ENDIF.
    ADD 1 TO lv_cant.
    IF ( lv_intervalo * lv_cant ) MOD lw_pauta-intervalo_mine = 0.
      lw_detalle-intervalo20 = 'X'.
    ENDIF.
    APPEND lw_detalle TO pt_detalle.

  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_GUARDAR_TEXTOS
*&---------------------------------------------------------------------*
FORM f_guardar_textos USING pv_object TYPE tdobject
                            pv_name   TYPE vbeln
                            pv_id     TYPE tdid
                            pw_lines  TYPE tdline.

  DATA: lt_lines  TYPE TABLE OF tline,
        lw_header TYPE thead,
        lv_tdname TYPE tdobname.

  WRITE pv_name TO lv_tdname.

  REFRESH lt_lines.
  APPEND pw_lines TO lt_lines.

  lw_header-tdobject   = pv_object.
  lw_header-tdname     = lv_tdname.
  lw_header-tdid       = pv_id.
  lw_header-tdspras    = 'S'.

  CALL FUNCTION 'SAVE_TEXT'
    EXPORTING
      header          = lw_header
      insert          = 'X'
      savemode_direct = 'X'
    TABLES
      lines           = lt_lines
    EXCEPTIONS
      id              = 1
      language        = 2
      name            = 3
      object          = 4
      OTHERS          = 5.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.


ENDFORM.



*&---------------------------------------------------------------------*
*&      Form  F_SELECCIONAR_PEDIDO_PARA_OC
*&---------------------------------------------------------------------*
FORM f_seleccionar_pedido_para_oc.

  DATA: lw_layout       TYPE lvc_s_layo,
        li_grid_setting TYPE lvc_s_glay,
        lw_alvoc        TYPE zst_ocalv,
        lt_fieldcat     TYPE lvc_t_fcat,
        lw_fieldcat     TYPE lvc_s_fcat.

  REFRESH gt_alvoc[].

  LOOP AT gt_intervalos INTO DATA(lw_intervalos).
    MOVE-CORRESPONDING lw_intervalos TO lw_alvoc.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lw_alvoc-intervalo
      IMPORTING
        output = lw_alvoc-intervalo.
    APPEND lw_alvoc TO gt_alvoc.
  ENDLOOP.

  lw_layout-cwidth_opt = 'X'.
  lw_layout-stylefname = 'FIELD_STYLE'.
  lw_layout-box_fname  = 'SEL'.

  li_grid_setting-edt_cll_cb = 'X'.

  REFRESH lt_fieldcat.

  CLEAR lw_fieldcat.
  lw_fieldcat-fieldname = 'SEL'.
  lw_fieldcat-no_out    = 'X'.
  APPEND lw_fieldcat TO lt_fieldcat.

  CLEAR lw_fieldcat.
  lw_fieldcat-fieldname = 'NRO_COTIZ'.
  lw_fieldcat-coltext   = 'N° Cotización'.
  APPEND lw_fieldcat TO lt_fieldcat.

  CLEAR lw_fieldcat.
  lw_fieldcat-fieldname = 'VERSION'.
  lw_fieldcat-coltext   = 'Version'.
  APPEND lw_fieldcat TO lt_fieldcat.

  CLEAR lw_fieldcat.
  lw_fieldcat-fieldname = 'INTERVALO'.
  lw_fieldcat-coltext   = 'Intervalo'.
  lw_fieldcat-no_zero   = 'X'.
  lw_fieldcat-just      = 'R'.
  APPEND lw_fieldcat TO lt_fieldcat.

  CLEAR lw_fieldcat.
  lw_fieldcat-fieldname = 'PEDIDO'.
  lw_fieldcat-coltext   = 'N° Pedido'.
  lw_fieldcat-no_zero   = 'X'.
  lw_fieldcat-just      = 'R'.
  lw_fieldcat-outputlen = '10'.
  APPEND lw_fieldcat TO lt_fieldcat.

  CLEAR lw_fieldcat.
  lw_fieldcat-fieldname = 'EBELN'.
  lw_fieldcat-coltext   = 'N° OC'.
  lw_fieldcat-no_zero   = 'X'.
  lw_fieldcat-just      = 'R'.
  lw_fieldcat-outputlen = '10'.
  APPEND lw_fieldcat TO lt_fieldcat.

  SORT gt_alvoc[] ASCENDING BY nro_cotiz version intervalo.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program       = sy-repid
      i_callback_user_command  = 'USER_COMMAND_OC'
      i_callback_pf_status_set = 'PF_STATUS_OC'
      i_structure_name         = 'GT_ALVOC'
      is_layout_lvc            = lw_layout
      it_fieldcat_lvc          = lt_fieldcat[]
      i_grid_settings          = li_grid_setting
      i_save                   = 'A'
    TABLES
      t_outtab                 = gt_alvoc
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.

ENDFORM.


*&--------------------------------------------------------------------*
*&      FORM USER_COMMAND_OC
*&--------------------------------------------------------------------*
FORM user_command_oc USING pv_ucomm    LIKE sy-ucomm
                           pw_selfield TYPE slis_selfield.

  DATA lv_cont TYPE sy-tabix.

  CASE sy-ucomm. "pv_ucomm.

    WHEN 'OC'.
      CLEAR lv_cont.
      LOOP AT gt_alvoc INTO DATA(lw_alvoc)
        WHERE sel = 'X'.
        ADD 1 TO lv_cont.
      ENDLOOP.

      IF lv_cont GT 1.
        CALL FUNCTION 'POPUP_TO_INFORM'
          EXPORTING
            titel = 'Información'
            txt1  = 'Seleccione sólo 1 regsitro'
            txt2  = 'para crear la OC.'.
      ELSEIF lv_cont IS INITIAL.
        CALL FUNCTION 'POPUP_TO_INFORM'
          EXPORTING
            titel = 'Información'
            txt1  = 'Seleccione al menos 1 regsitro'
            txt2  = 'para crear la OC.'.
      ELSE.
        IF lw_alvoc-ebeln IS INITIAL.
          CALL SCREEN 0600 STARTING AT 10 3.
*          PERFORM f_crear_orden_compra.
          pw_selfield-refresh = 'X'.
        ELSE.
          CALL FUNCTION 'POPUP_TO_INFORM'
            EXPORTING
              titel = 'Información'
              txt1  = 'El Intervalo del pedido ya tiene'
              txt2  = 'una OC creada.'.
        ENDIF.
      ENDIF.

    WHEN 'CANCEL' OR 'BACK'.
      CALL SCREEN 9000.

    WHEN 'EXIT'.
      LEAVE PROGRAM.

  ENDCASE.

ENDFORM.                    " USER_COMMAND_OC

<<<<<<< HEAD
*&---------------------------------------------------------------------*
*&      Form  F_CREAR_ORDEN_COMPRA
*&---------------------------------------------------------------------*
*  Crea Orden de Compra referenciando la Solicitud de Pedido (PR)
*  que SAP genera automáticamente al crear el Sales Order con
*  tipo de posición TAS (Third-Party).
*
*  Flujo: SO (con item_categ TAS) → PR automática (VBEP) → OC (BAPI)
*         → VBFA actualizado automáticamente
*----------------------------------------------------------------------*
=======

*&---------------------------------------------------------------------*
*&      Form  F_CREAR_ORDEN_COMPRA
*&---------------------------------------------------------------------*
>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c
FORM f_crear_orden_compra.

  DATA: lw_header            TYPE bapimepoheader,
        lw_headerx           TYPE bapimepoheaderx,
        lt_return            TYPE STANDARD TABLE OF bapiret2,
        lt_item              TYPE STANDARD TABLE OF bapimepoitem,
        lt_itemx             TYPE STANDARD TABLE OF bapimepoitemx,
        lt_poaccount         TYPE STANDARD TABLE OF bapimepoaccount,
        lt_poaccountx        TYPE STANDARD TABLE OF bapimepoaccountx,
        lt_bapimeposchedule  TYPE STANDARD TABLE OF bapimeposchedule,
        lt_bapimeposchedulex TYPE STANDARD TABLE OF bapimeposchedulx,
        lt_bapiret2          TYPE STANDARD TABLE OF bapiret2,
        lw_item              TYPE bapimepoitem,
        lw_itemx             TYPE bapimepoitemx,
        lw_poaccount         TYPE bapimepoaccount,
        lw_poaccountx        TYPE bapimepoaccountx,
        lw_bapimeposchedule  TYPE bapimeposchedule,
        lw_bapimeposchedulex TYPE bapimeposchedulx,
        lw_bapiret2          TYPE bapiret2,
        lv_ebeln             TYPE ebeln,
        lv_pos               TYPE ebelp,
        lv_quantity          TYPE bstmg,
        lv_glaccount         TYPE saknr,
        lv_tabix             TYPE sy-tabix,
        lv_intervalo         TYPE ztpauta_save-intervalo_mine.

<<<<<<< HEAD
* Variables para la Solicitud de Pedido automática
  DATA: lv_banfn     TYPE banfn,        " Número de Solped
        lv_bnfpo     TYPE bnfpo,        " Posición de Solped
        lv_pr_found  TYPE abap_bool.    " Flag PR encontrada

  FIELD-SYMBOLS <fs_alvoc> TYPE zst_ocalv.

  CLEAR: wa_cotizacion, lv_pr_found.
=======
  FIELD-SYMBOLS <fs_alvoc> TYPE zst_ocalv.

  CLEAR wa_cotizacion.
>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c

  READ TABLE gt_alvoc ASSIGNING <fs_alvoc>
    WITH KEY sel = 'X'.

  IF sy-subrc = 0.
    SELECT SINGLE *
      FROM ztcotizacion
      INTO wa_cotizacion
     WHERE nro_cotiz = <fs_alvoc>-nro_cotiz
       AND version   = <fs_alvoc>-version.

    IF sy-subrc = 0.

      lv_intervalo = <fs_alvoc>-intervalo.

      SELECT *
        FROM ztpauta_save
        INTO TABLE @DATA(lt_pautasave)
       WHERE numero_pauta   EQ @wa_cotizacion-numero_pauta
         AND cliente        EQ @wa_cotizacion-cliente
         AND fecha          EQ @wa_cotizacion-fecha
         AND equipo         EQ @wa_cotizacion-equipo
         AND marca          EQ @wa_cotizacion-marca
         AND modelo         EQ @wa_cotizacion-modelo
         AND modalidad      EQ @wa_cotizacion-modalidad
         AND lugar          EQ @wa_cotizacion-lugar
         AND caja           EQ @wa_cotizacion-caja
         AND diferencial    EQ @wa_cotizacion-diferencial
         AND intervalo_mine LE @lv_intervalo.
    ENDIF.
  ENDIF.


<<<<<<< HEAD
*----------------------------------------------------------------------*
* HEADER OC
*----------------------------------------------------------------------*
  lw_header-comp_code  = v_oc_bukrs.
  lw_header-doc_type   = v_oc_esart.
  lw_header-creat_date = sy-datum.
  lw_header-vendor     = v_oc_elifn.
  lw_header-purch_org  = v_oc_ekorg.
  lw_header-pur_group  = v_oc_bkgrp.
  lw_header-currency   = v_oc_waers.
=======

  lw_header-comp_code  = v_oc_bukrs. "'1000'.
  lw_header-doc_type   = v_oc_esart. "'ZPP3'.
  lw_header-creat_date = sy-datum.
  lw_header-vendor     = v_oc_elifn. "'RSA0'.
  lw_header-purch_org  = v_oc_ekorg. "'1000'.
  lw_header-pur_group  = v_oc_bkgrp. "'107'.
  lw_header-currency   = v_oc_waers. "'CLP'.
>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c
  lw_header-doc_date   = sy-datum.

  lw_headerx-comp_code  = c_mark.
  lw_headerx-doc_type   = c_mark.
  lw_headerx-creat_date = c_mark.
  lw_headerx-vendor     = c_mark.
  lw_headerx-purch_org  = c_mark.
  lw_headerx-pur_group  = c_mark.
  lw_headerx-currency   = c_mark.
  lw_headerx-doc_date   = c_mark.


<<<<<<< HEAD
*----------------------------------------------------------------------*
* ITEMS OC
*----------------------------------------------------------------------*
  lv_glaccount = v_oc_saknr.
=======
* ITEMS

  lv_glaccount = v_oc_saknr. "'0021110018'.
>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c

  READ TABLE gt_intervalos INTO DATA(lw_intervalos)
    WITH KEY nro_cotiz = <fs_alvoc>-nro_cotiz
             version   = <fs_alvoc>-version
             intervalo = <fs_alvoc>-intervalo.
<<<<<<< HEAD

=======
>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c
  IF sy-subrc NE 0.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
      EXPORTING
        input  = <fs_alvoc>-intervalo
      IMPORTING
        output = <fs_alvoc>-intervalo.

    READ TABLE gt_intervalos INTO lw_intervalos
      WITH KEY nro_cotiz = <fs_alvoc>-nro_cotiz
               version   = <fs_alvoc>-version
               intervalo = <fs_alvoc>-intervalo.
  ENDIF.


  IF sy-subrc = 0.

    lv_tabix = sy-tabix.

<<<<<<< HEAD
*   Buscar datos del Sales Order
=======
>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c
    SELECT SINGLE *
      FROM vbak
      INTO @DATA(lw_vbak)
     WHERE vbeln = @lw_intervalos-pedido.

    IF sy-subrc = 0.
      SELECT SINGLE *
        FROM ztofvta_centro
        INTO @DATA(lw_centro)
       WHERE vkbur = @lw_vbak-vkbur.
    ENDIF.

<<<<<<< HEAD
*   Buscar posición del Sales Order
=======

>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c
    SELECT SINGLE *
      FROM vbap
      INTO @DATA(lw_vbap)
     WHERE vbeln = @lw_intervalos-pedido
       AND matnr = @lw_intervalos-matnr.

    IF sy-subrc = 0.

<<<<<<< HEAD
*----------------------------------------------------------------------*
* PASO CLAVE: Buscar la Solicitud de Pedido automática en VBEP
* El tipo de posición TAS genera automáticamente una PR que se
* guarda en los schedule lines (VBEP.BANFN / VBEP.BANFP)
*----------------------------------------------------------------------*
      SELECT SINGLE banfn
        FROM vbep
        INTO (@lv_banfn)
       WHERE vbeln = @lw_vbap-vbeln
         AND posnr = @lw_vbap-posnr
         AND banfn NE @space.

      IF sy-subrc = 0 AND lv_banfn IS NOT INITIAL.
        lv_pr_found = abap_true.

      ENDIF.

*     Validar que se encontró la PR
      IF lv_pr_found = abap_false.
        CLEAR lw_bapiret2.
        lw_bapiret2-type       = 'E'.
        lw_bapiret2-id         = 'ZSD'.
        lw_bapiret2-number     = '038'.
        lw_bapiret2-message_v1 = 'No se encontró Solicitud de Pedido para SO:'.
        lw_bapiret2-message_v2 = lw_vbap-vbeln.
        lw_bapiret2-message_v3 = 'Pos:'.
        lw_bapiret2-message_v4 = lw_vbap-posnr.
        APPEND lw_bapiret2 TO lt_bapiret2.

        CALL FUNCTION 'C14ALD_BAPIRET2_SHOW'
          TABLES
            i_bapiret2_tab = lt_bapiret2.
        RETURN.
      ENDIF.

*----------------------------------------------------------------------*
* Crear item de OC con referencia a la Solicitud de Pedido
*----------------------------------------------------------------------*
      CLEAR: lw_item, lw_itemx, lw_poaccount, lw_poaccountx, lv_quantity.

      ADD 10 TO lv_pos.
=======
      DATA lv_preq_item TYPE vbap-posnr.
      CLEAR: lw_item, lw_itemx, lw_poaccount, lw_poaccountx, lv_quantity.

      lv_preq_item = lw_vbap-posnr.
      ADD 10 TO lv_pos.

>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c
      lv_quantity = lw_vbap-kwmeng.

      lw_item-po_item     = lv_pos.
      lw_item-acctasscat  = 'S'.
      lw_item-material    = lw_vbap-matnr.
      lw_item-short_text  = lw_vbap-arktx.
      lw_item-quantity    = lv_quantity.
      lw_item-net_price   = lw_vbap-netwr.
      lw_item-plant       = lw_centro-werks.
<<<<<<< HEAD
      lw_item-tax_code    = v_oc_mwskz.

*     *** REFERENCIA A LA SOLICITUD DE PEDIDO AUTOMÁTICA ***
      lw_item-preq_no     = lv_banfn.     " Número de Solped
      lw_item-preq_item   = lw_vbap-posnr.     " Posición de Solped = pos sales order

=======
      lw_item-tax_code    = v_oc_mwskz. "'C4'.
      lw_item-ref_doc     = lw_vbap-vbeln.
      lw_item-ref_item    = lv_preq_item.
*      lw_item-preq_no     = lw_vbap-vbeln.
*      lw_item-preq_item   = lv_preq_item.
>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c
      APPEND lw_item TO lt_item.

      lw_itemx-po_item    = lv_pos.
      lw_itemx-acctasscat = c_mark.
      lw_itemx-material   = c_mark.
      lw_itemx-short_text = c_mark.
      lw_itemx-quantity   = c_mark.
      lw_itemx-net_price  = c_mark.
      lw_itemx-plant      = c_mark.
      lw_itemx-tax_code   = c_mark.
<<<<<<< HEAD
      lw_itemx-preq_no    = c_mark.       " Flag para Solped
      lw_itemx-preq_item  = c_mark.       " Flag para Solped

      APPEND lw_itemx TO lt_itemx.

*     Account assignment
      lw_poaccount-po_item    = lv_pos.
      lw_poaccount-gl_account = lv_glaccount.
*     Vincular con Sales Order para EKKN
      lw_poaccount-sd_doc     = lw_vbap-vbeln.  " Sales Order
      lw_poaccount-itm_number = lw_vbap-posnr.  " Posición SO
=======
      lw_itemx-ref_doc    = c_mark.
      lw_itemx-ref_item   = c_mark.
*      lw_itemx-preq_no    = lw_vbap-vbeln.
*      lw_itemx-preq_item  = lv_preq_item.
      APPEND lw_itemx TO lt_itemx.

      lw_poaccount-po_item    = lv_pos.
      lw_poaccount-gl_account = lv_glaccount. "Cuenta de Mayor
>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c
      APPEND lw_poaccount TO lt_poaccount.

      lw_poaccountx-po_item    = lv_pos.
      lw_poaccountx-gl_account = c_mark.
<<<<<<< HEAD
      lw_poaccountx-sd_doc     = c_mark.
      lw_poaccountx-itm_number = c_mark.
      APPEND lw_poaccountx TO lt_poaccountx.

*     Schedule
=======
      APPEND lw_poaccountx TO lt_poaccountx.

>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c
      lw_bapimeposchedule-po_item       = lv_pos.
      lw_bapimeposchedule-delivery_date = sy-datum.
      APPEND lw_bapimeposchedule TO lt_bapimeposchedule.

      lw_bapimeposchedulex-po_item       = lv_pos.
      lw_bapimeposchedulex-delivery_date = c_mark.
<<<<<<< HEAD
      APPEND lw_bapimeposchedulex TO lt_bapimeposchedulex.

    ENDIF.

*----------------------------------------------------------------------*
* Items adicionales de la pauta (materiales adicionales)
*----------------------------------------------------------------------*
=======
      APPEND lw_bapimeposchedule TO lt_bapimeposchedule.

    ENDIF.

>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c
    LOOP AT lt_pautasave INTO DATA(lw_pautasave).

      CLEAR: lw_item, lw_itemx, lw_poaccount, lw_poaccountx.

      ADD 10 TO lv_pos.
      lw_item-po_item     = lv_pos.
      lw_item-acctasscat  = 'S'.
      lw_item-material    = lw_pautasave-matnr.
      lw_item-short_text  = lw_pautasave-descripcion_mat.
      lw_item-quantity    = lw_pautasave-cantidad.
      lw_item-net_price   = lw_pautasave-precio_final.
<<<<<<< HEAD
      lw_item-plant       = lw_centro-werks.
      lw_item-tax_code    = v_oc_mwskz.
*     Estos items adicionales NO llevan referencia a PR
*     ya que no vienen del Sales Order
=======
      lw_item-plant       = lw_centro-werks. "lw_pautasave-werksoc.
      lw_item-tax_code    = v_oc_mwskz. "'C4'.
>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c
      APPEND lw_item TO lt_item.

      lw_itemx-po_item    = lv_pos.
      lw_itemx-acctasscat = c_mark.
      lw_itemx-material   = c_mark.
      lw_itemx-short_text = c_mark.
      lw_itemx-quantity   = c_mark.
      lw_itemx-net_price  = c_mark.
      lw_itemx-plant      = c_mark.
      lw_itemx-tax_code   = c_mark.
      APPEND lw_itemx TO lt_itemx.

      lw_poaccount-po_item    = lv_pos.
<<<<<<< HEAD
      lw_poaccount-gl_account = lv_glaccount.
=======
      lw_poaccount-gl_account = lv_glaccount. "Cuenta de Mayor
>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c
      APPEND lw_poaccount TO lt_poaccount.

      lw_poaccountx-po_item    = lv_pos.
      lw_poaccountx-gl_account = c_mark.
      APPEND lw_poaccountx TO lt_poaccountx.

      lw_bapimeposchedule-po_item       = lv_pos.
      lw_bapimeposchedule-delivery_date = sy-datum.
      APPEND lw_bapimeposchedule TO lt_bapimeposchedule.

      lw_bapimeposchedulex-po_item       = lv_pos.
      lw_bapimeposchedulex-delivery_date = c_mark.
<<<<<<< HEAD
      APPEND lw_bapimeposchedulex TO lt_bapimeposchedulex.
=======
      APPEND lw_bapimeposchedule TO lt_bapimeposchedule.
>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c

    ENDLOOP.

  ENDIF.

<<<<<<< HEAD

*----------------------------------------------------------------------*
* Crear Orden de Compra
*----------------------------------------------------------------------*
  IF lt_item[] IS NOT INITIAL.

*   Test run primero
=======
  IF lt_item[] IS NOT INITIAL.

>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c
    CALL FUNCTION 'BAPI_PO_CREATE1'
      EXPORTING
        poheader         = lw_header
        poheaderx        = lw_headerx
        testrun          = 'X'
      IMPORTING
        exppurchaseorder = lv_ebeln
      TABLES
        return           = lt_return
        poitem           = lt_item
        poitemx          = lt_itemx
        poaccount        = lt_poaccount
        poaccountx       = lt_poaccountx
        poschedule       = lt_bapimeposchedule
        poschedulex      = lt_bapimeposchedulex.

  ENDIF.

  READ TABLE lt_return INTO DATA(lw_return)
    WITH KEY type = 'E'.

  IF sy-subrc = 0.
<<<<<<< HEAD
*   Errores en test run
=======

>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c
    APPEND LINES OF lt_return TO lt_bapiret2.
    DELETE lt_bapiret2 WHERE type NE 'E'.

  ELSE.
<<<<<<< HEAD
*   Test OK - Crear en productivo
    CLEAR: lt_return, lv_ebeln.
=======
>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c

    CALL FUNCTION 'BAPI_PO_CREATE1'
      EXPORTING
        poheader         = lw_header
        poheaderx        = lw_headerx
        testrun          = space
      IMPORTING
        exppurchaseorder = lv_ebeln
      TABLES
        return           = lt_return
        poitem           = lt_item
        poitemx          = lt_itemx
        poaccount        = lt_poaccount
        poaccountx       = lt_poaccountx
        poschedule       = lt_bapimeposchedule
        poschedulex      = lt_bapimeposchedulex.

    READ TABLE lt_return INTO lw_return
      WITH KEY type = 'E'.

    IF sy-subrc = 0.
<<<<<<< HEAD
*     Error en creación real
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

      LOOP AT lt_return INTO lw_return WHERE type = 'E'.
        CLEAR lw_bapiret2.
        lw_bapiret2-type       = 'E'.
        lw_bapiret2-id         = 'ZSD'.
        lw_bapiret2-number     = '035'.
        lw_bapiret2-message_v1 = lw_return-message.
        APPEND lw_bapiret2 TO lt_bapiret2.
      ENDLOOP.

    ELSE.
*     Éxito - Commit y actualizar tablas
=======

      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

      APPEND LINES OF lt_return TO lt_bapiret2.

    ELSE.

>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = c_mark.

      REFRESH lt_bapiret2.
<<<<<<< HEAD

*     Mensaje de éxito con info de Document Flow
      CLEAR lw_bapiret2.
      lw_bapiret2-type       = 'S'.
      lw_bapiret2-id         = 'ZSD'.
      lw_bapiret2-number     = '035'.
      lw_bapiret2-message_v1 = TEXT-005.   " 'Se creó la Orden de Compra'
      lw_bapiret2-message_v2 = lv_ebeln.
      APPEND lw_bapiret2 TO lt_bapiret2.

*     Mensaje informativo sobre Document Flow
      CLEAR lw_bapiret2.
      lw_bapiret2-type       = 'I'.
      lw_bapiret2-id         = 'ZSD'.
      lw_bapiret2-number     = '039'.
      lw_bapiret2-message_v1 = 'Document Flow: SO'.
      lw_bapiret2-message_v2 = lw_intervalos-pedido.
      lw_bapiret2-message_v3 = '→ PR →'.
      lw_bapiret2-message_v4 = lv_ebeln.
      APPEND lw_bapiret2 TO lt_bapiret2.

*     Actualizar tabla Z con número de OC
=======
      CLEAR lw_bapiret2.
      lw_bapiret2-type       = 'S'.
      lw_bapiret2-id         = 'ZSD'.
      lw_bapiret2-number     = 035.
      lw_bapiret2-message_v1 = TEXT-005.   " 'Se creó la Orden de Compra'.
      lw_bapiret2-message_v2 = lv_ebeln.
      APPEND lw_bapiret2 TO lt_bapiret2.

>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c
      lw_intervalos-ebeln = lv_ebeln.
      MODIFY gt_intervalos FROM lw_intervalos INDEX lv_tabix.
      MODIFY ztcoti_intervalo FROM lw_intervalos.
      <fs_alvoc>-ebeln = lv_ebeln.
<<<<<<< HEAD

=======
>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c
    ENDIF.

  ENDIF.

  IF lt_bapiret2[] IS NOT INITIAL.
    CALL FUNCTION 'C14ALD_BAPIRET2_SHOW'
      TABLES
        i_bapiret2_tab = lt_bapiret2.
  ENDIF.

ENDFORM.


<<<<<<< HEAD



=======
>>>>>>> 8f59dcd95f4936d4b88bac84da007d60761edb8c
*&---------------------------------------------------------------------*
*&      Form  F_OBTENER_VARIABLES
*&---------------------------------------------------------------------*
FORM f_obtener_variables.

*  DATA: lw_tempario  TYPE zttempario,
*        lv_modelo    TYPE zed_modelo,
*        lv_intervalo TYPE zed_interv_mine.
*
*  SELECT SINGLE *
*    FROM ztmanodeobra
*    INTO wa_manodeobra
*   WHERE sucursal = wa_screen1-sucursal "lv_sucursal
*     AND equipo   = wa_screen1-equipo.
*
*  SELECT *
*    FROM zttempario
*    INTO TABLE gt_tempario
*   WHERE modelo      = wa_screen1-modelo
*     AND modalidad   = wa_screen1-modalidad
*     AND caja        = wa_screen1-caja
*     AND diferencial = wa_screen1-diferencial.
*
*  IF sy-subrc = 0.
*    SORT gt_tempario ASCENDING
*      BY modelo modalidad caja diferencial.
*  ENDIF.


ENDFORM.      "F_OBTENER_VARIABLES
