
DATA: lv_tasa_m TYPE p DECIMALS 6,
      lv_cuota_t1 TYPE i,
      lv_cuota_t2 TYPE i,
      lv_cuota_t3 TYPE i,
      lv_cuota_t4 TYPE i,
      lv_valor_hs1 TYPE p DECIMALS 2,
      lv_valor_hs2 TYPE p DECIMALS 2,
      lv_valor_hs3 TYPE p DECIMALS 2,
      lv_valor_hs4 TYPE p DECIMALS 2,
      lv_contrato_v TYPE i,
      lv_cuota1 TYPE c LENGTH 10,
      lv_cuota2 TYPE c LENGTH 10,
      lv_cuota3 TYPE c LENGTH 10,
      lv_cuota4 TYPE c LENGTH 10,
      lv_valorc1 TYPE c LENGTH 10,
      lv_valorc2 TYPE c LENGTH 10,
      lv_valorc3 TYPE c LENGTH 10,
      lv_valorc4 TYPE c LENGTH 10.

IF wa_cotizacion-ipc IS NOT INITIAL.
  v_tasa_mensu = wa_cotizacion-tasa_mensu.

  REPLACE ',' WITH '.' INTO v_tasa_mensu.

*  lv_tasa_m = wa_cotizacion-tasa_mensu / 100.
  lv_tasa_m = v_tasa_mensu / 100.

***TASA 1
  lv_cuota_t1 = wa_cotizacion-milajustado *
     ( lv_tasa_m * ( 1  + lv_tasa_m ) ** wa_cotizacion-duracion1 )  /
     ( ( 1 + lv_tasa_m ) ** wa_cotizacion-duracion1 - 1 ).

  WRITE lv_cuota_t1 TO lv_cuota1.
  CONCATENATE '$' lv_cuota1 INTO v_cuota SEPARATED BY space.

***TASA 2
  lv_cuota_t2 =  wa_cotizacion-cuatromajust *
     ( lv_tasa_m * ( 1  + lv_tasa_m ) ** wa_cotizacion-duracion2 )  /
     ( ( 1 + lv_tasa_m ) ** wa_cotizacion-duracion2 - 1 ).

  WRITE lv_cuota_t2 TO lv_cuota2.
  CONCATENATE '$' lv_cuota2 INTO v_cuota2 SEPARATED BY space.

***TASA 3
  lv_cuota_t3 =   wa_cotizacion-contrat_4500 *
     ( lv_tasa_m * ( 1  + lv_tasa_m ) ** wa_cotizacion-duracion3 )  /
     ( ( 1 + lv_tasa_m ) ** wa_cotizacion-duracion3 - 1 ).

  WRITE lv_cuota_t3 TO lv_cuota3.
  CONCATENATE '$' lv_cuota3 INTO v_cuota3 SEPARATED BY space.

***TASA 4
  lv_cuota_t4 =   wa_cotizacion-contrat_6000 *
     ( lv_tasa_m * ( 1  + lv_tasa_m ) ** wa_cotizacion-duracion4 )  /
     ( ( 1 + lv_tasa_m ) ** wa_cotizacion-duracion4 - 1 ).

  WRITE lv_cuota_t4 TO lv_cuota4.
  CONCATENATE '$' lv_cuota4 INTO v_cuota4 SEPARATED BY space.
ELSE.
***TASA 1
  lv_cuota_t1 = wa_cotizacion-milajustado / wa_cotizacion-duracion1.

  WRITE lv_cuota_t1 TO lv_cuota1.
  CONCATENATE '$' lv_cuota1 INTO v_cuota SEPARATED BY space.
** TASA 2
  lv_cuota_t2 =  wa_cotizacion-cuatromajust / wa_cotizacion-duracion2.

  WRITE lv_cuota_t2 TO lv_cuota2.
  CONCATENATE '$' lv_cuota2 INTO v_cuota2 SEPARATED BY space.
** TASA 3
  lv_cuota_t3 =  wa_cotizacion-contrat_4500 / wa_cotizacion-duracion3.

  WRITE lv_cuota_t3 TO lv_cuota3.
  CONCATENATE '$' lv_cuota3 INTO v_cuota3 SEPARATED BY space.
** TASA 4
  lv_cuota_t4 =  wa_cotizacion-contrat_6000 / wa_cotizacion-duracion4.

  WRITE lv_cuota_t4 TO lv_cuota4.
  CONCATENATE '$' lv_cuota4 INTO v_cuota4 SEPARATED BY space.
ENDIF.

***Si es FAENA se divide por 1000 en caso contrario no se divide
IF wa_cotizacion-modalidad EQ 'HORAS'.
  CLEAR : lv_contrato_v.
  lv_contrato_v = wa_cotizacion-contrato_valor1.
  lv_valor_hs1 = ( ( lv_cuota_t1 * wa_cotizacion-duracion1 ) /
                    lv_contrato_v ). " / 1000.

  WRITE lv_valor_hs1 TO lv_valorc1.
  CONCATENATE '$' lv_valorc1 INTO vl_hs1 SEPARATED BY space.

  CLEAR : lv_contrato_v.
  lv_contrato_v = wa_cotizacion-contrato_valor2.
  lv_valor_hs2 = ( ( lv_cuota_t2 * wa_cotizacion-duracion2 ) /
                    lv_contrato_v ). " / 1000.

  WRITE lv_valor_hs2 TO lv_valorc2.
  CONCATENATE '$' lv_valorc2 INTO vl_hs2 SEPARATED BY space.

  CLEAR : lv_contrato_v.
  lv_contrato_v = wa_cotizacion-contrato_valor3.
  lv_valor_hs3 = ( ( lv_cuota_t3 * wa_cotizacion-duracion3 ) /
                    lv_contrato_v ). " / 1000.

  WRITE lv_valor_hs3 TO lv_valorc3.
  CONCATENATE '$' lv_valorc3 INTO vl_hs3 SEPARATED BY space.

  CLEAR : lv_contrato_v.
  lv_contrato_v = wa_cotizacion-contrato_valor4.
  lv_valor_hs4 = ( ( lv_cuota_t4 * wa_cotizacion-duracion4 ) /
                    lv_contrato_v ). " / 1000.

  WRITE lv_valor_hs4 TO lv_valorc4.
  CONCATENATE '$' lv_valorc4 INTO vl_hs4 SEPARATED BY space.
ELSE.
  CLEAR : lv_contrato_v.
  lv_contrato_v = wa_cotizacion-contrato_valor1.
  lv_valor_hs1 = ( ( lv_cuota_t1 * wa_cotizacion-duracion1 ) /
                    lv_contrato_v ) / 1000.

  WRITE lv_valor_hs1 TO lv_valorc1.
  CONCATENATE '$' lv_valorc1 INTO vl_hs1 SEPARATED BY space.

  CLEAR : lv_contrato_v.
  lv_contrato_v = wa_cotizacion-contrato_valor2.
  lv_valor_hs2 = ( ( lv_cuota_t2 * wa_cotizacion-duracion2 ) /
                    lv_contrato_v ) / 1000.

  WRITE lv_valor_hs2 TO lv_valorc2.
  CONCATENATE '$' lv_valorc2 INTO vl_hs2 SEPARATED BY space.

  CLEAR : lv_contrato_v.
  lv_contrato_v = wa_cotizacion-contrato_valor3.
  lv_valor_hs3 = ( ( lv_cuota_t3 * wa_cotizacion-duracion3 ) /
                    lv_contrato_v ) / 1000.

  WRITE lv_valor_hs3 TO lv_valorc3.
  CONCATENATE '$' lv_valorc3 INTO vl_hs3 SEPARATED BY space.

  CLEAR : lv_contrato_v.
  lv_contrato_v = wa_cotizacion-contrato_valor4.
  lv_valor_hs4 = ( ( lv_cuota_t4 * wa_cotizacion-duracion4 ) /
                    lv_contrato_v ) / 1000.

  WRITE lv_valor_hs4 TO lv_valorc4.
  CONCATENATE '$' lv_valorc4 INTO vl_hs4 SEPARATED BY space.
ENDIF.
