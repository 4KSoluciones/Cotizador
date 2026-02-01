*&---------------------------------------------------------------------*
*& Report ZABMTAB_COTIZADOR
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT  zabmtab_cotizador.

INCLUDE zabmtab_cotizador_top.
INCLUDE zabmtab_cotizador_f01.
INCLUDE zabmtab_cotizador_pbo.
INCLUDE zabmtab_cotizador_pai.

************************************************************************
*                          START OF SELECTION
************************************************************************
START-OF-SELECTION.

  CALL SCREEN 9000.

  PERFORM %_list_return IN PROGRAM sapmssy0.
