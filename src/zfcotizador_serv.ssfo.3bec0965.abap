DATA: lv_valor1(15)  TYPE c,
      lv_valor2(15) TYPE c,
      lv_valor3(15) TYPE c,
      lv_valor4(15) TYPE c.

WRITE wa_cotizacion-prepago1 TO lv_valor1.
WRITE wa_cotizacion-prepago2 TO lv_valor2.
WRITE wa_cotizacion-prepago3 TO lv_valor3.
WRITE wa_cotizacion-prepago4 TO lv_valor4.

CONCATENATE '$' lv_valor1 INTO v_importe1 SEPARATED BY space.
CONCATENATE '$' lv_valor2 INTO v_importe2 SEPARATED BY space.
CONCATENATE '$' lv_valor3 INTO v_importe3 SEPARATED BY space.
CONCATENATE '$' lv_valor4 INTO v_importe4 SEPARATED BY space.


















