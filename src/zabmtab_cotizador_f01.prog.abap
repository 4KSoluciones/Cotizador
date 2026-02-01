*&---------------------------------------------------------------------*
*&  Include           ZABMTAB_COTIZADOR_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  F_RUTA_DE_ARCHIVO
*&---------------------------------------------------------------------*
FORM f_ruta_de_archivo CHANGING p_ruta     TYPE dxfile-filename
                                pv_error   TYPE char1.

  DATA: lv_usr_action TYPE i,
        lv_win_title  TYPE string,
        lv_rc         TYPE i,
        lt_file_table TYPE filetable,
        lw_file_table TYPE file_table.

  lv_win_title =  TEXT-t01.

  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title            = lv_win_title
      default_extension       = '*csv'
*     file_filter             = lc_filter
    CHANGING
      file_table              = lt_file_table
      rc                      = lv_rc
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5.

  IF lv_usr_action EQ cl_gui_frontend_services=>action_cancel.
    EXIT.
  ELSE.
    READ TABLE lt_file_table INTO lw_file_table INDEX 1.
    IF sy-subrc IS INITIAL.
      p_ruta =  lw_file_table-filename..
    ELSE.
      pv_error = c_flag.
    ENDIF.
  ENDIF.

ENDFORM.


**&---------------------------------------------------------------------*
**&      Form  F_CARGA_DE_ARCHIVO
**&---------------------------------------------------------------------*
FORM f_carga_de_archivo USING pv_i_tabname   TYPE dd03l-tabname
                              pv_i_file      TYPE dxfile-filename
                     CHANGING pv_e_error     TYPE c..

  DATA: lt_raw          TYPE truxs_t_text_data .

  DATA: lv_files    TYPE string.

**  RUTA
  lv_files = pv_i_file.
  ASSIGN gr_itab->* TO <fs_datos>.

  CALL FUNCTION 'TEXT_CONVERT_XLS_TO_SAP'
    EXPORTING
*     I_FIELD_SEPERATOR    =
*     I_LINE_HEADER        =
      i_tab_raw_data       = lt_raw
      i_filename           = p_ruta
    TABLES
      i_tab_converted_data = <fs_datos>
    EXCEPTIONS
      conversion_failed    = 1
      OTHERS               = 2.

  IF sy-subrc NE 0.
    pv_e_error = c_flag.
* Message Error
    MESSAGE s000(zfi_001)  WITH TEXT-te3 DISPLAY LIKE c_error.
    LEAVE LIST-PROCESSING.
    EXIT.

  ENDIF.

  IF gr_itab IS INITIAL.
    CALL FUNCTION 'POPUP_TO_INFORM'
      EXPORTING
        titel = 'Mensaje de error'
        txt1  = 'El archivo no se cargó o '
        txt2  = 'se encuentra vacío.'.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_PROCESA_ARCHIVO
*&---------------------------------------------------------------------*
FORM f_procesa_archivo USING pv_i_tabname   TYPE dd03l-tabname
                    CHANGING pt_e_fieldcat  TYPE lvc_t_fcat.

  DATA: lt_table  TYPE REF TO data,
        lw_line   TYPE REF TO data,
        lv_style  TYPE lvc_fname,
        lv_nro    TYPE i,
        lv_lines  TYPE i,
        lw_campos TYPE lty_s_campos,
        lv_campo  TYPE c LENGTH 25.

  FIELD-SYMBOLS: <l_reg>    TYPE any,
                 <l_campo>  TYPE any,
                 <lv_value> TYPE any.


  SELECT fieldname inttype leng position keyflag
    INTO TABLE it_campos
    FROM dd03l
   WHERE tabname = pv_i_tabname.


  IF sy-subrc = 0.
    SORT it_campos BY position.
    LOOP AT it_campos INTO wa_campos.
      CLEAR wa_fieldcat.
      wa_fieldcat-col_pos   = sy-tabix.
      wa_fieldcat-fieldname = wa_campos-fieldname.
      wa_fieldcat-inttype   = wa_campos-inttype.
      wa_fieldcat-intlen    = wa_campos-leng.
      wa_fieldcat-outputlen = wa_campos-leng.
      wa_fieldcat-ref_field = wa_campos-fieldname.
      wa_fieldcat-ref_table = pv_i_tabname.
      APPEND wa_fieldcat TO pt_e_fieldcat.
    ENDLOOP.
  ENDIF.

  CALL METHOD cl_alv_table_create=>create_dynamic_table
    EXPORTING
      it_fieldcatalog = pt_e_fieldcat[]
    IMPORTING
      ep_table        = lt_table
      e_style_fname   = lv_style.

  ASSIGN lt_table->* TO <l_tabla>.


* Create dynamic work area and assign to FS
  CREATE DATA lw_line LIKE LINE OF <l_tabla>.
  ASSIGN lw_line->* TO <l_reg>.

  DESCRIBE TABLE it_campos LINES lv_lines.

  LOOP AT <fs_datos> ASSIGNING FIELD-SYMBOL(<lw_datos>).
    lv_nro = 1.

    DO  lv_lines TIMES.

      lv_nro = lv_nro + 1.
      READ TABLE it_campos INTO lw_campos INDEX lv_nro.

      CONCATENATE '<l_REG>-' lw_campos-fieldname
        INTO lv_campo.

      ASSIGN (lv_campo) TO <l_campo>.

      IF <l_campo> IS ASSIGNED.
        ASSIGN COMPONENT lw_campos-fieldname
            OF STRUCTURE <lw_datos> TO <lv_value>.

        <l_campo> = <lv_value>.
      ENDIF.
    ENDDO.

    APPEND <l_reg> TO <l_tabla>.

  ENDLOOP.

  DELETE pt_e_fieldcat WHERE fieldname = 'MANDT'.

  PERFORM f_elimino_repetido USING pv_i_tabname.

  IF <l_tabla> IS NOT INITIAL.
    DESCRIBE TABLE <l_tabla> LINES lv_lines.
    MODIFY (pv_i_tabname) FROM TABLE <l_tabla>.
    CALL SCREEN 0100.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_CHECK_SELECTION_SCREEN
*&---------------------------------------------------------------------*
FORM f_check_selection_screen  USING    pv_file    TYPE dxfile-filename
                               CHANGING pv_error   TYPE char1.

  DATA: lv_file_exist(1) TYPE c.
  DATA: lv_filename      TYPE string.

  lv_filename = pv_file.

  CALL METHOD cl_gui_frontend_services=>file_exist
    EXPORTING
      file   = lv_filename
    RECEIVING
      result = lv_file_exist.

  IF NOT ( sy-subrc = 0 AND lv_file_exist = c_flag ).
    pv_error = c_flag.
    MESSAGE  s000(zfi_001)  WITH TEXT-te2 DISPLAY LIKE c_error.
    LEAVE LIST-PROCESSING.
    EXIT.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_MOSTRAR_ALV
*&---------------------------------------------------------------------*
FORM f_mostrar_alv  CHANGING po_e_alvgrid        TYPE REF TO cl_gui_alv_grid
                             po_e_contenedor_alv TYPE REF TO cl_gui_custom_container.

  DATA: lw_layout   TYPE lvc_s_layo,
        lt_fieldcat TYPE lvc_t_fcat,
        lv_variant  TYPE disvariant.

  CONSTANTS: lc_container_alv TYPE char20 VALUE 'CTRL_CUSTOM_ALV'.

  IF po_e_alvgrid IS INITIAL.

    " ALV general.
    CREATE OBJECT po_e_contenedor_alv
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

    CREATE OBJECT po_e_alvgrid
      EXPORTING
        i_parent          = po_e_contenedor_alv
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
      " El sistema se encarga de la validación.
    ENDIF.

    lw_layout-zebra = 'X'.
    lv_variant-report = sy-cprog.

    CALL METHOD po_e_alvgrid->set_table_for_first_display
      EXPORTING
        is_variant                    = lv_variant
        i_save                        = 'A'
        is_layout                     = lw_layout
      CHANGING
        it_outtab                     = <fs_datos>
        it_fieldcatalog               = it_fieldcat[]
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.

  ELSE.
    " Refrescar salida.
    PERFORM f_refrescar_alv USING po_e_alvgrid.
  ENDIF.


ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  F_REFRESCAR_ALV
*&---------------------------------------------------------------------*
FORM f_refrescar_alv  USING  po_i_alvgrid TYPE REF TO cl_gui_alv_grid.

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
*&      Form  F_ELIMINO_REPETIDO
*&---------------------------------------------------------------------*
FORM f_elimino_repetido   USING pv_i_tabname   TYPE dd03l-tabname.

  CONSTANTS: lc_par_a TYPE c VALUE '(',
             lc_par_c TYPE c VALUE ')',
             lc_and   TYPE c LENGTH 3 VALUE 'AND',
             lc_i     TYPE c VALUE 'I',
             lc_eq    TYPE c LENGTH 2 VALUE 'EQ'.

  DATA: gr_itab     TYPE REF TO data,
        gr_aux      TYPE REF TO data,
        lt_campos_k TYPE STANDARD TABLE OF lty_s_campos,
        lv_campos_k TYPE c LENGTH 255,
        lr_campo    TYPE RANGE OF string,
        lwr_campo   LIKE LINE OF lr_campo,
        lv_cant     TYPE n,
        lr_campo1   TYPE RANGE OF string,
        lr_campo2   TYPE RANGE OF string,
        lr_campo3   TYPE RANGE OF string,
        lr_campo4   TYPE RANGE OF string,
        lr_campo5   TYPE RANGE OF string,
        lr_campo6   TYPE RANGE OF string,
        lr_campo7   TYPE RANGE OF string,
        lr_campo8   TYPE RANGE OF string,
        lr_campo9   TYPE RANGE OF string,
        lr_campo10  TYPE RANGE OF string,
        lr_campo11  TYPE RANGE OF string,
        lr_campo12  TYPE RANGE OF string,
        lr_campo13  TYPE RANGE OF string,
        lr_campo14  TYPE RANGE OF string,
        lr_campo15  TYPE RANGE OF string.

  FIELD-SYMBOLS: <fs_aux>   TYPE STANDARD TABLE,
                 <fs_datos> TYPE STANDARD TABLE.

  CREATE DATA gr_itab TYPE STANDARD TABLE OF (pv_i_tabname)
    WITH NON-UNIQUE DEFAULT KEY.

  CREATE DATA gr_aux TYPE STANDARD TABLE OF (pv_i_tabname)
    WITH NON-UNIQUE DEFAULT KEY.

  ASSIGN gr_itab->* TO <fs_aux>.

  <fs_aux> = <l_tabla>.
  lt_campos_k[] = it_campos[].
  DELETE lt_campos_k WHERE keyflag = space.

  SORT <fs_aux> .
  DELETE ADJACENT DUPLICATES FROM <fs_aux>.

  CLEAR lv_campos_k.

  lv_campos_k = lc_par_a.

  DELETE lt_campos_k WHERE fieldname = 'MANDT'.

  CLEAR lv_cant.
  LOOP AT lt_campos_k INTO DATA(lw_campos_k).
    ADD 1 TO lv_cant.

    IF lv_cant = 1.
      CONCATENATE lv_campos_k lw_campos_k-fieldname
        INTO lv_campos_k SEPARATED BY space.
    ELSE.
      CONCATENATE lv_campos_k lc_and lw_campos_k-fieldname
        INTO lv_campos_k SEPARATED BY space.
    ENDIF.

    LOOP AT <fs_aux> ASSIGNING  FIELD-SYMBOL(<ls_datos>).

      ASSIGN COMPONENT lw_campos_k-fieldname
        OF STRUCTURE <ls_datos> TO FIELD-SYMBOL(<lv_field>).

      lwr_campo-sign   = lc_i.
      lwr_campo-option = lc_eq.
      lwr_campo-low    = <lv_field>.
      APPEND lwr_campo TO lr_campo.
      CLEAR lwr_campo.

    ENDLOOP.

    IF lv_cant = 1.
      lr_campo1[] = lr_campo[].
      CONCATENATE lv_campos_k 'IN' 'lr_campo1'
             INTO lv_campos_k SEPARATED BY space.

    ELSEIF lv_cant = 2.
      lr_campo2[] = lr_campo[].
      CONCATENATE lv_campos_k 'IN' 'lr_campo2'
             INTO lv_campos_k SEPARATED BY space.

    ELSEIF lv_cant = 3.
      lr_campo3[] = lr_campo[].
      CONCATENATE lv_campos_k 'IN' 'lr_campo3'
             INTO lv_campos_k SEPARATED BY space.

    ELSEIF lv_cant = 4.
      lr_campo4[] = lr_campo[].
      CONCATENATE lv_campos_k 'IN' 'lr_campo4'
             INTO lv_campos_k SEPARATED BY space.

    ELSEIF lv_cant = 5.
      lr_campo5[] = lr_campo[].
      CONCATENATE lv_campos_k 'IN' 'lr_campo5'
             INTO lv_campos_k SEPARATED BY space.

    ELSEIF lv_cant = 6.
      lr_campo6[] = lr_campo[].
      CONCATENATE lv_campos_k 'IN' 'lr_campo6'
             INTO lv_campos_k SEPARATED BY space.

    ELSEIF lv_cant = 7.
      lr_campo7[] = lr_campo[].
      CONCATENATE lv_campos_k 'IN' 'lr_campo7'
             INTO lv_campos_k SEPARATED BY space.

    ELSEIF lv_cant = 8.
      lr_campo8[] = lr_campo[].
      CONCATENATE lv_campos_k 'IN' 'lr_campo8'
             INTO lv_campos_k SEPARATED BY space.

    ELSEIF lv_cant = 9.
      lr_campo9[] = lr_campo[].
      CONCATENATE lv_campos_k 'IN' 'lr_campo9'
             INTO lv_campos_k SEPARATED BY space.

    ELSEIF lv_cant = 10.
      lr_campo10[] = lr_campo[].
      CONCATENATE lv_campos_k 'IN' 'lr_campo10'
             INTO lv_campos_k SEPARATED BY space.

    ELSEIF lv_cant = 11.
      lr_campo11[] = lr_campo[].
      CONCATENATE lv_campos_k 'IN' 'lr_campo11'
             INTO lv_campos_k SEPARATED BY space.

    ELSEIF lv_cant = 12.
      lr_campo12[] = lr_campo[].
      CONCATENATE lv_campos_k 'IN' 'lr_campo12'
             INTO lv_campos_k SEPARATED BY space.

    ELSEIF lv_cant = 13.
      lr_campo13[] = lr_campo[].
      CONCATENATE lv_campos_k 'IN' 'lr_campo13'
             INTO lv_campos_k SEPARATED BY space.

    ELSEIF lv_cant = 14.
      lr_campo14[] = lr_campo[].
      CONCATENATE lv_campos_k 'IN' 'lr_campo14'
             INTO lv_campos_k SEPARATED BY space.

    ELSEIF lv_cant = 15.
      lr_campo15[] = lr_campo[].
      CONCATENATE lv_campos_k 'IN' 'lr_campo15'
             INTO lv_campos_k SEPARATED BY space.

    ENDIF.

    CLEAR: lwr_campo,
           lr_campo.

  ENDLOOP.

  CONCATENATE  lv_campos_k lc_par_c
         INTO lv_campos_k SEPARATED BY space.

  DELETE FROM (pv_i_tabname) WHERE (lv_campos_k).

ENDFORM.
