
DATA: lv_tasa_m TYPE p DECIMALS 6,
      lv_cuota_t1 TYPE i,
      lv_cuota_t2 TYPE i,
      lv_cuota_t3 TYPE i,
      lv_cuota_t4 TYPE i,
      lv_cuota1 TYPE c LENGTH 10,
      lv_cuota2 TYPE c LENGTH 10,
      lv_cuota3 TYPE c LENGTH 10,
      lv_cuota4 TYPE c LENGTH 10.
v_tasa_mensu = wa_cotizacion-tasa_mensu.

REPLACE ',' WITH '.' INTO v_tasa_mensu.

*lv_tasa_m = wa_cotizacion-tasa_mensu / 100.
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






