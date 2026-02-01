FUNCTION zmf_f4_fecha.
*"----------------------------------------------------------------------
*"*"Interfase local
*"  TABLES
*"      SHLP_TAB TYPE  SHLP_DESCT
*"      RECORD_TAB STRUCTURE  SEAHLPRES
*"  CHANGING
*"     VALUE(SHLP) TYPE  SHLP_DESCR
*"     VALUE(CALLCONTROL) TYPE  DDSHF4CTRL
*"----------------------------------------------------------------------

  DATA: lt_fields  TYPE TABLE OF dynpread,
        lw_fields  TYPE dynpread,
        lv_dyname  TYPE sy-repid,
        lv_dynumb  TYPE sy-dynnr,
        lv_cliente TYPE dynfieldvalue.

  lw_fields-fieldname = 'V_CLIENTE'.
  APPEND lw_fields TO lt_fields.

  lv_dyname = 'ZCOTIZADOR'.
  lv_dynumb = '0300'.

  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname     = lv_dyname
      dynumb     = lv_dynumb
    TABLES
      dynpfields = lt_fields
    EXCEPTIONS
      OTHERS     = 01.

  READ TABLE lt_fields INTO lw_fields
    WITH KEY fieldname = 'V_CLIENTE'.
  IF sy-subrc = 0.
    lv_cliente = lw_fields-fieldvalue.
  ELSE.
    CLEAR lv_cliente.
  ENDIF.

  IF callcontrol-step EQ 'DISP'.
    SORT record_tab BY string ASCENDING.
    IF lv_cliente IS NOT INITIAL.
      DELETE record_tab WHERE string NS lv_cliente.
      DELETE ADJACENT DUPLICATES FROM record_tab COMPARING string.
    ENDIF.
  ENDIF.

ENDFUNCTION.
