*&---------------------------------------------------------------------*
*&  Include           ZCOTIZADOR_TOP
*&---------------------------------------------------------------------*

TABLES: ztpauta, nast, itcpo.

TYPES: BEGIN OF ty_screen1,
         nro_cotiz       TYPE ze_nro_cotiz,
         version         TYPE ze_version,
         kunnr           TYPE kunnr,
         equipo          TYPE zed_equipo,
         marca           TYPE zed_marca,
         modelo          TYPE zed_modelo,
         sucursal        TYPE zed_sucursal,
         modalidad       TYPE zed_modalidad,
         lugar           TYPE zed_lugar,
         caja            TYPE zed_caja,
         diferencial     TYPE zed_diferencial,
         txt_operacion   TYPE zed_descripcion,
         uso             TYPE zed_uso,
         uso_inicial     TYPE zed_uso,
         uso_iniciali    TYPE i,
         txt_sucursal    TYPE char10,
         txt_modalidad   TYPE char20,
         txt_lugar       TYPE char20,
         txt_caja        TYPE char20,
         txt_diferencial TYPE char20,
         txt_medida      TYPE char16,
         txt_uso_inic    TYPE char20,
         descuento_peso  TYPE komp-wrbtr,
         descuento_porc  TYPE zed_porc,
         chk_ipc         TYPE c,
         chk_cuota       TYPE c,
         chk_poruso      TYPE c,
         chk_prepago     TYPE c,
         chk_desc        TYPE c,
         chk_tel         TYPE c,
       END OF ty_screen1.

TYPES: BEGIN OF ty_pauta.
         INCLUDE STRUCTURE ztpauta.
         TYPES: field_style TYPE lvc_t_styl,
       END OF ty_pauta.

TYPES: BEGIN OF ty_popup,
         numero_pauta TYPE ztpauta_save-numero_pauta,
         cliente      TYPE ztpauta_save-cliente,
         fecha        TYPE ztpauta_save-fecha,
         equipo       TYPE ztpauta_save-equipo,
         marca        TYPE ztpauta_save-marca,
         modelo       TYPE ztpauta_save-modelo,
         checkbox,
       END OF ty_popup.

TYPES: tyt_ztcotizacion TYPE STANDARD TABLE OF ztcotizacion.

TYPES: BEGIN OF ty_pauta_i,
         intervalo_mine TYPE i,
       END OF ty_pauta_i,
       tyt_pauta_i TYPE STANDARD TABLE OF ty_pauta_i.

TYPES: BEGIN OF ty_comision,
         comision1 TYPE zed_comision,
         comision2 TYPE zed_comision,
         comision3 TYPE zed_comision,
         comision4 TYPE zed_comision,
       END OF ty_comision.

TYPES: BEGIN OF ty_val_contrato,
         valor1 TYPE i,
         valor2 TYPE i,
         valor3 TYPE i,
         valor4 TYPE i,
       END OF ty_val_contrato.

TYPES: BEGIN OF ty_materiales,
         matnr TYPE mara-matnr,
         mfrpn TYPE mara-mfrpn,
         maktx TYPE makt-maktx,
         matkl TYPE mara-matkl,
         bukrs TYPE t001k-bukrs,
         spart TYPE mara-spart,
         werks TYPE mard-werks,
         labst TYPE mard-labst,
       END OF ty_materiales.

TYPES: BEGIN OF ty_descuento,
         matnr TYPE a515-matnr,
         kbetr TYPE konp-kbetr,
       END OF ty_descuento.

TYPES: BEGIN OF ty_repuestos,
         matnr     TYPE mara-matnr,
         mfrpn     TYPE mara-mfrpn,
         maktx     TYPE makt-maktx,
         matkl     TYPE mara-matkl,
         bukrs     TYPE t001k-bukrs,
         spart     TYPE mara-spart,
         labst     TYPE char18, "mard-labst,
         precio    TYPE char16, "konp-kbetr,
         descuento TYPE char16, "konp-kbetr,
         kwaeh     TYPE konp-kwaeh,
         total     TYPE char21, "vbrp-netwr,
         reemplazo TYPE string,
       END OF ty_repuestos.

TYPES: BEGIN OF ty_implubri,
         matnr     TYPE mara-matnr,
         kbetr     TYPE konp-kbetr,
         precio    TYPE char16,
         descuento TYPE char16,
         total     TYPE char21,
       END OF ty_implubri,
       tyt_implubri TYPE STANDARD TABLE OF ty_implubri.

TYPES: BEGIN OF ty_bdcdata.
         INCLUDE STRUCTURE bdcdata.
       TYPES: END OF ty_bdcdata.

TYPES tyt_bdcmsgcoll TYPE STANDARD TABLE OF bdcmsgcoll.

TYPES: BEGIN OF ty_servicios,
         matnr   TYPE matnr,
         importe TYPE netwr_fp,
       END OF ty_servicios,
       tyt_servicios TYPE STANDARD TABLE OF ty_servicios.

DATA: gt_pauta           TYPE STANDARD TABLE OF ty_pauta,
      gt_pauta_save      TYPE STANDARD TABLE OF ztpauta_save,
      gt_tempario        TYPE STANDARD TABLE OF zttempario,
      gt_comision        TYPE STANDARD TABLE OF ztcomision,
      gt_param           TYPE STANDARD TABLE OF ztparam_coti, "ztdto_serv_mant,
      gt_servicios       TYPE STANDARD TABLE OF ztservicios, "tyt_servicios,
      gt_fieldcat        TYPE lvc_t_fcat,
      gt_cotizacion      TYPE tyt_ztcotizacion,
      gt_materiales      TYPE STANDARD TABLE OF ty_materiales,
      gt_descuento       TYPE STANDARD TABLE OF ty_descuento,
      gt_descuento2      TYPE STANDARD TABLE OF ty_descuento,
      gt_repuestos       TYPE STANDARD TABLE OF ty_repuestos,
      gt_implubri        TYPE tyt_implubri,
      gt_fcat            TYPE lvc_t_fcat,
      gt_intervalos      TYPE STANDARD TABLE OF ztcoti_intervalo,
      gt_alvint          TYPE ztt_cotioc,
      gt_bdcdata         TYPE STANDARD TABLE OF ty_bdcdata,
      gt_alvoc           TYPE STANDARD TABLE OF zst_ocalv,

      wa_servicios       TYPE ztservicios, "ty_servicios,
      wa_screen1         TYPE ty_screen1,
      wa_pauta_popup     TYPE ty_popup,
      wa_manodeobra      TYPE ztmanodeobra,
      wa_repuestos       TYPE ty_repuestos,
      wa_implubri        TYPE ty_implubri,
      wa_cotizacion      TYPE ztcotizacion,

      v_active9000       TYPE c,
      v_activefin        TYPE c,
      v_modifica_coti    TYPE c,
      v_grisa9000        TYPE c,
      v_fieldvalue       TYPE char25,
      v_numeropauta      TYPE zed_numeropauta,
      v_answer           TYPE c,
      v_ok_code_0100     TYPE sy-ucomm,
      v_ok_code_0200     TYPE sy-ucomm,
      v_ok_code_0300     TYPE sy-ucomm,
      v_ok_code_0400     TYPE sy-ucomm,
      v_ok_code_0500     TYPE sy-ucomm,
      v_ok_code_0600     TYPE sy-ucomm,
      v_ok_code_9000     TYPE sy-ucomm,
      v_saveok9000       TYPE sy-ucomm,
      v_rb_ajust         TYPE c,
      v_rb_viaticos      TYPE c,
      v_rb_dto$          TYPE c,
      v_rb_dto%          TYPE c,
      v_rb_prepago       TYPE c,
      v_rb_cuota         TYPE c,
      v_rb_leasing       TYPE c,
      v_viaticos         TYPE i,
      v_km_terreno       TYPE i,
      v_hs_terreno       TYPE i,
      v_peajes           TYPE i,
      v_icon_ok          TYPE icons-text,
      v_icon_canc        TYPE icons-text,
      v_trasla           TYPE c LENGTH 5,
      v_reparac          TYPE c LENGTH 5,
      v_intervalo        TYPE zed_interv_mine,
      v_interv_x         TYPE sy-tabix,
      v_cliente          TYPE ztcotizacion-cliente,
      v_fecha            TYPE ztcotizacion-fecha,
      v_nrocotiz         TYPE ztcotizacion-nro_cotiz,
      v_version          TYPE ztcotizacion-version,
      v_auart            TYPE auart,
      v_vkbur            TYPE vkbur,
      v_duracion         TYPE ze_duracion,
      v_nrofact          TYPE belnr_d,
      v_vin              TYPE zed_vin,
      v_werksoc          TYPE t001w-werks,
      v_nrocotiz500      TYPE ztcotizacion-nro_cotiz,
      v_version500       TYPE ztcotizacion-version,
      v_werks500         TYPE t001w-werks,

      v_vkorg            TYPE vkorg,
      v_vtweg            TYPE vtweg,
      v_spart            TYPE spart,
      v_vkgrp            TYPE vkgrp,
      v_parvw            TYPE parvw,
      v_kscha            TYPE kscha,
      v_pstyv            TYPE pstyv,

      v_oc_bukrs         TYPE bukrs,
      v_oc_esart         TYPE esart,
      v_oc_elifn         TYPE elifn,
      v_oc_ekorg         TYPE ekorg,
      v_oc_bkgrp         TYPE bkgrp,
      v_oc_waers         TYPE waers,
      v_oc_saknr         TYPE saknr,
      v_oc_mwskz         TYPE mwskz,

      v_o_alvgrid        TYPE REF TO cl_gui_alv_grid,
      v_o_contenedor_alv TYPE REF TO cl_gui_custom_container,

      r_user             TYPE RANGE OF syuname.

CONSTANTS: c_back       TYPE sy-ucomm          VALUE 'BACK',
           c_cancel     TYPE sy-ucomm          VALUE 'CANCEL',
           c_exit       TYPE sy-ucomm          VALUE 'EXIT',
           c_camiones   TYPE ty_screen1-equipo VALUE 'CAMIONES',
           c_agricola   TYPE ty_screen1-equipo VALUE 'AGRICOLA',
           c_maquinaria TYPE ty_screen1-equipo VALUE 'MAQUINARIA',
           c_mark       TYPE char1             VALUE 'X'.
