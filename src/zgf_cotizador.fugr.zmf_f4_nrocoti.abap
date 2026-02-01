FUNCTION zmf_f4_nrocoti.
*"----------------------------------------------------------------------
*"*"Interfase local
*"  TABLES
*"      SHLP_TAB TYPE  SHLP_DESCT
*"      RECORD_TAB STRUCTURE  SEAHLPRES
*"  CHANGING
*"     VALUE(SHLP) TYPE  SHLP_DESCR
*"     VALUE(CALLCONTROL) TYPE  DDSHF4CTRL
*"----------------------------------------------------------------------

  DATA: lv_fecha TYPE sy-datum,
        lv_tabix TYPE sy-tabix.

  IF callcontrol-step EQ 'DISP'.

    CALL FUNCTION 'CALCULATE_DATE'
      EXPORTING
        months      = '-2'
        start_date  = sy-datum
      IMPORTING
        result_date = lv_fecha.

    SORT record_tab BY string ASCENDING.

    LOOP AT record_tab.
      lv_tabix = sy-tabix.
      IF record_tab-string+39(8) LT lv_fecha.
        IF sy-sysid NE 'SFD'.
          DELETE record_tab INDEX lv_tabix.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDFUNCTION.
