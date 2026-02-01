FUNCTION zmf_f4_cliente.
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
        lv_fecha   TYPE dynfieldvalue.

  REFRESH lt_fields.
  lw_fields-fieldname = 'V_FECHA'.
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
    WITH KEY fieldname = 'V_FECHA'.
  IF sy-subrc = 0.
    CONCATENATE lw_fields-fieldvalue+6(4)
                lw_fields-fieldvalue+3(2)
                lw_fields-fieldvalue(2)
           INTO lv_fecha.
  ELSE.
    CLEAR lv_fecha.
  ENDIF.

  IF callcontrol-step EQ 'DISP'.
    SORT record_tab BY string ASCENDING.
    DELETE ADJACENT DUPLICATES FROM record_tab COMPARING string.
    IF lv_fecha IS NOT INITIAL.
      DELETE record_tab WHERE string NS lv_fecha.
    ENDIF.
  ENDIF.

ENDFUNCTION.
