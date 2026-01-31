IF wa_cotizacion-chk_cuota_ajus = 'X'.

  CONCATENATE '$' wa_cotizacion-cuota_ajus1 INTO v_cuota1 SEPARATED BY space.
  CONCATENATE '$' wa_cotizacion-cuota_ajus2 INTO v_cuota2 SEPARATED BY space.
  CONCATENATE '$' wa_cotizacion-cuota_ajus3 INTO v_cuota3 SEPARATED BY space.
  CONCATENATE '$' wa_cotizacion-cuota_ajus4 INTO v_cuota4 SEPARATED BY space.

ELSE.

  CONCATENATE '$' wa_cotizacion-cuota1 INTO v_cuota1 SEPARATED BY space.
  CONCATENATE '$' wa_cotizacion-cuota2 INTO v_cuota2 SEPARATED BY space.
  CONCATENATE '$' wa_cotizacion-cuota3 INTO v_cuota3 SEPARATED BY space.
  CONCATENATE '$' wa_cotizacion-cuota4 INTO v_cuota4 SEPARATED BY space.

ENDIF.
