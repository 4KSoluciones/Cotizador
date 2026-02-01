DATA: lv_valor(10)  TYPE c,
      lv_valor2(10) TYPE c,
      lv_valor3(10) TYPE c,
      lv_valor4(10) TYPE c.

WRITE wa_cotizacion-milajustado  TO lv_valor.
WRITE wa_cotizacion-cuatromajust TO lv_valor2.
WRITE wa_cotizacion-contrat_4500 TO lv_valor3.
WRITE wa_cotizacion-contrat_6000 TO lv_valor4.

CONCATENATE '$' lv_valor  INTO v_importe1.
CONCATENATE '$' lv_valor2 INTO v_importe2.
CONCATENATE '$' lv_valor3 INTO v_importe3.
CONCATENATE '$' lv_valor4 INTO v_importe4.



















