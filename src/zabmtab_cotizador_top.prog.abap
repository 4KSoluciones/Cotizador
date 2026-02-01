*&---------------------------------------------------------------------*
*&  Include           ZABMTAB_COTIZADOR_TOP
*&---------------------------------------------------------------------*
TYPE-POOLS: slis.

************************************************************************
*                              TYPES
************************************************************************
TYPES: BEGIN OF lty_s_campos,
         fieldname TYPE dd03l-fieldname,
         inttype   TYPE dd03l-inttype,
         leng      TYPE dd03l-leng,
         position  TYPE dd03l-position,
         keyflag   TYPE dd03l-keyflag,
       END OF lty_s_campos.

************************************************************************
*                              DATA
************************************************************************
DATA: gt_pauta        TYPE STANDARD TABLE OF ztpauta_serv,
      gt_tempario     TYPE STANDARD TABLE OF zttempario_serv,
      gt_param        TYPE STANDARD TABLE OF ztparam_cotserv,
      gt_textos       TYPE STANDARD TABLE OF zttextos_serv,
      gt_pauta_log    TYPE STANDARD TABLE OF ztpauta_serv,
      gt_tempario_log TYPE STANDARD TABLE OF zttempario_serv,
      gt_param_log    TYPE STANDARD TABLE OF ztparam_cotserv,
      gt_textos_log   TYPE STANDARD TABLE OF zttextos_serv.

DATA: it_campos   TYPE STANDARD TABLE OF lty_s_campos,
      it_fieldcat TYPE lvc_t_fcat,
      it_table    TYPE REF TO data,
      gr_itab     TYPE REF TO data.
*      gt_tasas    TYPE STANDARD TABLE OF ztdto_serv_mant.

FIELD-SYMBOLS: <fs_datos> TYPE table,
               <l_tabla>  TYPE STANDARD TABLE.

DATA: v_error(1) TYPE c,
      v_tabname  TYPE dd03l-tabname,
      v_estname  TYPE dd03l-tabname.

* OBJETOS --------------------------------------------------------*
DATA: vo_alvgrid        TYPE REF TO cl_gui_alv_grid,
      vo_contenedor_alv TYPE REF TO cl_gui_custom_container,
      v_ok_code         TYPE sy-ucomm.

DATA: p_pauta  TYPE flag,
      p_temp   TYPE flag,
      p_param  TYPE flag,
      p_textos TYPE flag,
      p_manual TYPE flag,
      p_excel  TYPE flag,
      p_ruta   LIKE rlgrap-filename.

************************************************************************
*   Work Areas
************************************************************************
DATA: wa_campos   TYPE lty_s_campos,
      wa_fieldcat TYPE lvc_s_fcat.


************************************************************************
*                            CONSTANTS
************************************************************************
CONSTANTS: c_error(1)   TYPE c VALUE 'E',
           c_flag(1)    TYPE c VALUE 'X',
           c_tab_pauta  TYPE c LENGTH 12 VALUE 'ZTPAUTA_SERV',
           c_est_pauta  TYPE c LENGTH 13 VALUE 'ZTPAUTA_SERV',
           c_tab_tempa  TYPE c LENGTH 15 VALUE 'ZTTEMPARIO_SERV',
           c_est_tempa  TYPE c LENGTH 16 VALUE 'ZTTEMPARIO_SERV',
           c_tab_param  TYPE c LENGTH 15 VALUE 'ZTPARAM_COTSERV',
           c_est_param  TYPE c LENGTH 16 VALUE 'ZTPARAM_COTSERV',
           c_tab_textos TYPE c LENGTH 14 VALUE 'ZTTEXTOS_SERV',
           c_est_textos TYPE c LENGTH 15 VALUE 'ZTTEXTOS_SERV'.
